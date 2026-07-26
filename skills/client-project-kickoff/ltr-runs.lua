--[[
ltr-runs.lua — keep multi-word Latin runs left-to-right inside RTL text.

The `bidi` package used by xelatex + polyglossia does not implement the full
Unicode Bidirectional Algorithm. Inside an RTL paragraph it places each Latin
*word* independently in the RTL flow, so a multi-word Latin run comes out
reversed: "Meridian Labs" renders as "Labs Meridian", "Purple Berry Studio" as
"Studio Berry Purple". Single Latin words are unaffected, which is why the
problem hides until a brand name has two words in it.

Fix: wrap each maximal Latin run in \LR{...} (provided by `bidi`) so the run is
laid out as one left-to-right span. Neutral tokens — em dashes, slashes,
brackets — join a run when Latin sits on both sides, and are trimmed from its
edges.

LaTeX-only, and only meaningful for documents with `dir: rtl`.

Usage:  pandoc "Doc (FA).md" -o "Doc (FA).pdf" --pdf-engine=xelatex \
          --lua-filter=ltr-runs.lua -V geometry:margin=1in
]]

if FORMAT ~= 'latex' and FORMAT ~= 'beamer' then return {} end

-- Lua patterns are byte-oriented. Persian/Arabic (U+0600–U+06FF) and the
-- Arabic Presentation Forms encode as UTF-8 lead bytes 0xD8–0xDB / 0xEF, none
-- of which are ASCII. So "contains no byte >= 0x80" is a sound test for
-- "purely Latin/ASCII", and it is what distinguishes the three token classes.
local function classify(s)
  if s:find('[\128-\255]') then return 'rtl' end   -- any non-ASCII byte
  if s:find('%a') then return 'latin' end          -- ASCII letters present
  return 'neutral'                                 -- punctuation, digits, symbols
end

-- Only Str carries text; Space/SoftBreak are neutral glue. Anything else
-- (Link, Code, Strong, …) ends a run — those are handled by recursion, since
-- the walker visits their inline lists separately.
local function token_class(el)
  if el.t == 'Str' then return classify(el.text) end
  -- Code spans carry their own text and are usually paths, filenames or handles.
  -- Multi-word ones reverse just like prose does: `03 Source Assets/` comes out
  -- as `Assets/ Source 03` unless the span is wrapped too.
  if el.t == 'Code' then return classify(el.text) end
  if el.t == 'Space' or el.t == 'SoftBreak' then return 'neutral' end
  return 'other'
end

-- A Str can fuse both scripts with no space between them — "Studio،" is one
-- token, because the Persian comma follows the Latin word directly. Left whole
-- it classifies as 'rtl' and terminates the run, so "Purple Berry Studio،"
-- wraps only "Purple Berry" and the name still comes out broken. Split each Str
-- into maximal ASCII / non-ASCII pieces first, so each piece classifies on its
-- own. Splitting on that byte boundary never lands mid-character: every byte of
-- a multi-byte UTF-8 sequence is >= 0x80.
local function split_mixed(inlines)
  local out = pandoc.Inlines({})
  for _, el in ipairs(inlines) do
    if el.t ~= 'Str' or not el.text:find('[\128-\255]') or el.text:find('^[\128-\255]*$') then
      out:insert(el)
    else
      local s, i = el.text, 1
      while i <= #s do
        local ascii, j = s:byte(i) < 128, i
        while j <= #s and (s:byte(j) < 128) == ascii do j = j + 1 end
        out:insert(pandoc.Str(s:sub(i, j - 1)))
        i = j
      end
    end
  end
  return out
end

local function fix_run(inlines)
  inlines = split_mixed(inlines)
  local out = pandoc.Inlines({})
  local run, has_latin = {}, false

  -- Drop neutral glue from a run's edges, wrap the rest, emit.
  local function flush()
    if not has_latin then
      for _, el in ipairs(run) do out:insert(el) end
      run, has_latin = {}, false
      return
    end
    local first, last = 1, #run
    while token_class(run[first]) == 'neutral' do first = first + 1 end
    while token_class(run[last]) == 'neutral' do last = last - 1 end

    for i = 1, first - 1 do out:insert(run[i]) end
    out:insert(pandoc.RawInline('latex', '\\babelsublr{'))
    for i = first, last do out:insert(run[i]) end
    out:insert(pandoc.RawInline('latex', '}'))
    for i = last + 1, #run do out:insert(run[i]) end

    run, has_latin = {}, false
  end

  for _, el in ipairs(inlines) do
    local class = token_class(el)
    if class == 'latin' then
      run[#run + 1] = el
      has_latin = true
    elseif class == 'neutral' then
      run[#run + 1] = el          -- may turn out to be a joiner, or edge glue
    else                          -- 'rtl' or 'other' terminates the run
      flush()
      out:insert(el)
    end
  end
  flush()

  return out
end

-- Body only — never metadata. Two separate reasons, both fatal:
--   * `mainfont`/`lang` are consumed as raw LaTeX arguments (\setmainfont{...}),
--     so \LR{} inside them breaks the fontspec call;
--   * `title` is expanded by hyperref in the preamble, before `bidi` loads
--     (bidi must be loaded last), so \LR is still undefined there.
-- Give RTL documents their title as a body H1 rather than YAML `title:`.
-- Only act on RTL documents. \babelsublr is defined by babel only when an RTL
-- language is loaded, so applying this to an English document produces
-- "Undefined control sequence" and no PDF at all. Guarding here means one
-- pandoc invocation works for both languages of a bilingual pair.
function Pandoc(doc)
  local dir = doc.meta.dir
  if dir ~= nil then dir = pandoc.utils.stringify(dir) end
  if dir ~= 'rtl' then return doc end

  doc.blocks = doc.blocks:walk({ Inlines = fix_run })
  return doc
end
