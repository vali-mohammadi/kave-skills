#!/usr/bin/env bash
# Scan generated project documents for material that must never reach delivery
# teams: fees, payment terms, contract IDs, personal contact details.
#
# Portable to stock macOS: uses only POSIX/BSD grep features (-E, -F). Never -P.
#
# Usage:
#   redaction-audit.sh <directory> [literal-term ...]
#
# Literal terms are the specific strings you read in the contract — the fee
# figure, the engagement ID, the client's name and email. Pass them explicitly;
# the built-in patterns are a safety net, not a substitute.
#
# Exit: 0 clean · 1 findings · 2 usage/error

set -uo pipefail

die() { printf 'redaction-audit: %s\n' "$1" >&2; exit 2; }

[ $# -ge 1 ] || die "usage: redaction-audit.sh <directory> [literal-term ...]"

DIR="$1"; shift
[ -d "$DIR" ] || die "not a directory: $DIR"

# Search from inside the directory so reported paths stay readable.
ABS_DIR=$(cd "$DIR" && pwd) || die "cannot enter: $DIR"
cd "$ABS_DIR" || die "cannot enter: $ABS_DIR"

# Generated PDFs mirror their .md source, so scanning markdown covers both.
FILE_COUNT=$(find . -type f -name '*.md' | wc -l | tr -d ' ')
[ "$FILE_COUNT" -gt 0 ] || die "no .md files under $ABS_DIR — nothing to audit"

FINDINGS=$(mktemp) || die "cannot create temp file"
trap 'rm -f "$FINDINGS"' EXIT

report() { # label, then grep output on stdin
  local label="$1" hits
  hits=$(cat)
  [ -n "$hits" ] || return 0
  printf '\n%s\n' "$label" >>"$FINDINGS"
  printf '%s\n' "$hits" | sed 's|^|  |' >>"$FINDINGS"
}

# --- Pass 1: literal terms from the contract -------------------------------
for term in "$@"; do
  [ -n "$term" ] || continue
  grep -R -n -i -F --include='*.md' -- "$term" . 2>/dev/null \
    | report "Contract term \"$term\":"
done

# --- Pass 2: built-in patterns ---------------------------------------------
scan() { # description, ERE
  grep -R -n -i -E --include='*.md' -- "$2" . 2>/dev/null | report "$1"
}

scan 'Currency amounts:'        '(GBP|USD|EUR|[$£€])[[:space:]]*[0-9]'
scan 'Payment / commercial terms:' 'due in full|payment term|payable|invoice|deposit|per hour|hourly rate|retainer|revision allowance|unlimited (revision|iteration)'
scan 'Email addresses:'         '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
scan 'Contract/document IDs:'   '(engagement|document|doc|ref(erence)?)[[:space:]]*(id|no\.?|number|#)[[:space:]]*:?[[:space:]]*[0-9]'

# --- Verdict ---------------------------------------------------------------
# Print an explicit verdict either way: silence must never read as success.
printf 'Audited %s markdown file(s) under: %s\n' "$FILE_COUNT" "$ABS_DIR"

if [ -s "$FINDINGS" ]; then
  cat "$FINDINGS"
  printf '\nFAIL — review each hit above. Some may be legitimate (an asset link\n'
  printf 'containing an address, a deliberately public contact); the rest must be\n'
  printf 'removed before this folder is shared.\n'
  exit 1
fi

printf 'CLEAN — no fees, payment terms, contact details, or contract IDs found.\n'
exit 0
