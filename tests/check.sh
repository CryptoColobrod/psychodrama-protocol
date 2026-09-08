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

# --- TASK 2 ---
for a in decomposer judge skeptic outside-frame transgressive; do must "agents/psychodrama-$a.md" '^model: opus$'; done
for a in optimizer security maintainability-advocate resource-keeper champion; do must "agents/psychodrama-$a.md" '^model: sonnet$'; done
must agents/psychodrama-champion.md '^name: psychodrama-champion$'
must agents/psychodrama-champion.md 'WEAK_POINT:'
must agents/psychodrama-champion.md 'does not satisfy Adversarial Presence'

# --- TASK 3 ---
must SKILL.md 'One model family across all agents'
must_not SKILL.md 'Not Sonnet, not a mix'
must SKILL.md '^\| `--spectator` \|'
must SKILL.md '^\| `--position "<text>"` \|'
must SKILL.md '^\| `--no-position` \|'
must SKILL.md '^\| `--model opus'
must SKILL.md 'STEELMAN:'
must SKILL.md 'Targeted R2 roster'
must SKILL.md 'psychodrama-champion'
must_not SKILL.md '6-11 panel mode'
must SKILL.md '~6-10 panel mode'

# --- TASK 4 ---
must SKILL.md "Looks like you've stated a position"
must SKILL.md 'PROTAGONIST_POSITION'
must SKILL.md '~6-10 model calls'
must_not SKILL.md '~6-11 model calls'
must SKILL.md 'Save the user.s parsed flags \(`--with-external`, `--save-adr`, `--no-record`, `--spectator`, `--position`, `--no-position`, `--model`\)'

# --- TASK 5 ---
must SKILL.md 'subagent_type="psychodrama-champion"'
must SKILL.md 'Protagonist position: "<PROTAGONIST_POSITION>". Stress-test it explicitly where a thesis touches it.'
must SKILL.md 'A Champion is defending the user.s stated position'
must_not SKILL.md 'No `model` parameter is passed — role agents inherit'
must SKILL.md 'model="opus"'
must SKILL.md 'model="sonnet"'

# --- TASK 6 ---
must SKILL.md 'EARLY_FINALIZE'
must SKILL.md 'R2_PARTICIPANTS:'
must SKILL.md 'R2_ROSTER'
must SKILL.md 'STEELMAN: <the strongest version'
must SKILL.md 'PROTAGONIST: survived \| survived with conditions \| did not survive'
must SKILL.md '## Match report'
must_not SKILL.md 'dispatch the same roster IN PARALLEL \(single message, as in Step 4\) with the R2 prompt'

# --- TASK 7 ---
must SKILL.md '^ *tiers: '
must SKILL.md '^ *protagonist: '
must SKILL.md '^ *r2_participants: '
must_not SKILL.md 'One apex model everywhere'
must SKILL.md 'One model family, tiers per role'
must SKILL.md 'Protagonist: <survived'

# --- TASK 6 fix ---
must SKILL.md 'r2_participants:. = the roles in .R2_ROSTER'
must SKILL.md 'PROTAGONIST line if PROTAGONIST_POSITION is set'

# --- END ---
[ $fail -eq 0 ] && echo "ALL CHECKS PASS"
exit $fail
