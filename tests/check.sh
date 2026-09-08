#!/usr/bin/env bash
# Assertion checks for the markdown skill. Run from anywhere: tests/check.sh
set -u
cd "$(dirname "$0")/.."
fail=0
must()     { grep -qE -- "$2" "$1" || { echo "FAIL [$1] missing: $2"; fail=1; }; }
must_not() { grep -qE -- "$2" "$1" && { echo "FAIL [$1] present: $2"; fail=1; }; }
count()    { n=$(grep -cE -- "$2" "$1"); [ "$n" -eq "$3" ] || { echo "FAIL [$1] expected $3 of '$2', got $n"; fail=1; }; }
no_cyrillic() { perl -CSD -ne 'if (/\p{Cyrillic}/) { print "FAIL [$ARGV] cyrillic at line $.\n"; exit 1 }' "$1" || fail=1; }

# --- TASK 1 ---
for f in SKILL.md README.md DESIGN.md CHANGELOG.md CONTRIBUTING.md agents/*.md examples/*.md; do
  no_cyrillic "$f"
done
must SKILL.md '^name: psychodrama-protocol$'

# --- END ---
[ $fail -eq 0 ] && echo "ALL CHECKS PASS"
exit $fail
