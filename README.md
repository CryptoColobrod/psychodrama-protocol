# The Psychodrama Protocol

**Put your decision on stage.** A [Claude Code](https://claude.com/claude-code) skill that debates your question through a panel of adversarial AI roles — thesis-by-thesis voting for formed decisions, duels with critics built for each idea for open ones. Never the answer as one blob.

This repository is the protocol's reference implementation for Claude Code (formerly `consensus-claude`).

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-2.2.0-informational.svg)](CHANGELOG.md)

Prefer a plain name? In a session the skill also answers to **"consensus panel"** — the mythology is optional; the mechanics are not.

## Quick start

```bash
git clone https://github.com/CryptoColobrod/psychodrama-protocol.git && cd psychodrama-protocol
mkdir -p ~/.claude/skills/psychodrama-protocol ~/.claude/agents && cp SKILL.md DESIGN.md ~/.claude/skills/psychodrama-protocol/ && cp agents/psychodrama-*.md ~/.claude/agents/
```
Restart Claude Code, then: `/psychodrama-protocol Should we move session storage from PostgreSQL to Redis?` — the panel asks for confirmation before spending any calls. Full install notes, flags and cost are below.

## The differentiator

Most review tools score a decision holistically: one pass, one verdict. The Psychodrama Protocol decomposes the question first and votes claim by claim.

- **Per-thesis decomposition.** An isolated Decomposer agent splits the question into 3–7 atomic decision criteria. A binary "A or B" question becomes independent criteria to evaluate — never a mirror pair like "T1: choose A / T2: choose B."
- **4-status voting per thesis** — `AGREED` / `AGREED_WEAK` / `DISPUTED` / `NEEDS_CLARIFICATION` — plus a `CONDITION:` tag for conditional agreement ("yes, if this external dependency holds"), instead of bloating the status vocabulary with a 5th state.
- **Hard-capped rounds.** R1 (parallel, isolated) + a targeted R2 on disputed theses only. Never R3 — two rounds without convergence is a signal to escalate to external review, not to spin the same panel again.
- **Single-model by design.** The panel's independent perspectives come from role isolation within one apex model — distinct mandates, clean contexts, no cross-talk in R1 — not from paying for three API keys across three providers. An external critic enters only as an anti-groupthink tripwire when the panel goes suspiciously unanimous, and it's provider-agnostic: configure any CLI in one line, or fall back to a copy-paste prompt handoff to whatever model you already have — never the default mode.
- **Critics with biographies, not a generic skeptic.** Criticism quality scales with critic specificity — in duel mode, each explored direction gets a critic with a biography: an antagonist shaped by the failures of exactly that idea's class, not a fixed adversarial role stretched to fit every idea.

**vs. alternatives:** tools like [agent-review-panel](https://github.com/wan-huiyan/agent-review-panel) review a document holistically, as one blob. Multi-model council tools require multiple model providers by default. The Psychodrama Protocol's unit of judgment is the individual claim, and it needs exactly one model to do it.

**Heads-up on cost:** one full run = ~6-10 calls (decomposer + 4 role votes + judge, plus targeted round-2 re-votes by the roles that disputed). Decomposer, Judge and Skeptic run on your strongest tier; the other voters run on a cheaper one — see the tier table under Install. Expect several minutes and meaningful quota use on subscription plans. Built for decisions that deserve it — not for quick questions.

## When to use this skill

Reach for the panel when:

- The decision is complex and multi-faceted — e.g. "monolith → microservices?"
- You need explicit trade-off exploration — e.g. "Rust vs Go for this service"
- You're de-risking a choice that's critical or hard to reverse
- You want to surface unknown unknowns in a plan before committing to it

For quick questions, just ask directly — the panel is deliberately heavyweight. On an expensive or ambiguous question, run with `--plan` first to steer the frame before you pay for a full panel — this matters most in duel mode, where `--plan` lets you steer which perspectives get minted before paying for duels.

---

## Why a psychodramatist built this

Konstantin Shvedov is a practicing psychologist and psychodramatist. He also builds [SessionFlow](https://shvedovpro.com/sessionflow) (site in Russian), an AI platform for psychotherapists.

The core insight is transplanted straight from the therapy stage: a problem becomes tractable when it is *staged* — given to roles, each with its own mandate to fight for. Nobody resolves a conflict by holding it in their head as one blob; you put each side in a chair and let it argue. The protocol is Moreno's psychodrama, mapped onto decision engineering.

| Psychodrama (Moreno) | The Protocol |
|---|---|
| The stage | the run: isolated contexts where roles play out |
| Auxiliary egos | the panel roles / minted champions |
| The hidden critic | Skeptic + GROUPTHINK_FLAG (an alarm for the critic's *silence*) |
| Tailored antagonists | critics with biographies — an opponent built from this idea's failure class |
| The empty chair | the Judge must name the direction nobody was minted to defend |
| Surplus reality | duel mode: the problem generates voices that do not exist until staged |
| Role reversal | `STEELMAN:` in round 2 — every re-vote first states the opponent's strongest case |
| The protagonist | `--position` — the user's own stance gets a chair and a Champion, and the verdict says whether it survived |
| The figure above the system | 🕊 the outside-the-frame voice — dissolves a deadlock from above |
| The shadow / the tempter | 🔥 the transgressive voice — the suppressed option, staged at last |

None of this is decoration. Each row is a mechanism you can read in SKILL.md — the stage directions are the source code.

And we ran the protocol on itself. The panel broke the question's own premise, held two minority reports, fact-checked the orchestrator's evidence mid-run, and the verdict — *Narrowly carried* — shipped two product changes before release. Full transcript: [`examples/self-review.md`](examples/self-review.md).

---

## Example: PostgreSQL → Redis session storage?

The full run is in [`examples/session-storage-demo.md`](examples/session-storage-demo.md) — real, unedited, run against the prompts shipped in this repo. Here's what the machinery actually produces.

**Question:** *Should we migrate our web app's session storage from PostgreSQL to Redis, or keep sessions in Postgres and only add a cache layer for hot paths?*

### Decomposition

```
CANONICAL INTENT: User is choosing between a full session-store migration and a lower-risk
incremental fix (keep Postgres, cache hot paths); the real trade-off is whether current
session-storage pain is severe enough to justify a migration's cost and operational risk
when a cheaper targeted alternative exists.

T1: Session storage in PostgreSQL is currently a real performance or scaling bottleneck.
T2: Adding a cache layer only for hot paths resolves that bottleneck sufficiently.
T3: Redis materially outperforms PostgreSQL for this application's session workload.
T4: The team can operate Redis in production without unacceptable added operational burden.
T5: Introducing Redis as a new stateful component is justified by the expected gains.
T6: Keeping sessions in PostgreSQL avoids data-consistency and durability complications that
    Redis would introduce.
```

**→ note:** the binary question became 6 independent criteria — no `T1: pick Redis / T2: pick Postgres` mirror pair. The Canonical Intent rides along with every thesis to every voter, so no role loses the whole while judging its slice.

### Votes that show the machinery working

**Skeptic on T5 — catching circular justification, then a Judge FLIP:**

```
T5: DISPUTED Self-contradiction with T1/T3 — this thesis ("gains justify the new component")
    cannot be true if T1 (bottleneck is real) and T3 (Redis materially outperforms) are
    themselves unproven. FLIP: measured p99 latency + QPS baseline on current Postgres.
```

**Optimizer's T2 CONDITION tag:**

```
T2: AGREED_WEAK Read-through cache on existing Postgres reuses a well-understood pattern.
    CONDITION: holds if the hot-path read/write ratio is skewed enough that caching absorbs
    the contention (i.e., sessions are read far more than written).
```

**Net verdict:** the panel favors **keep Postgres + add a scoped read-through cache** over a Redis migration — conditional on confirming the pain is real and read-dominated *first*.

→ Full run, unedited: [examples/session-storage-demo.md](examples/session-storage-demo.md). Two more: [duel-demo.md](examples/duel-demo.md), [self-review.md](examples/self-review.md), [market-test-demo.md](examples/market-test-demo.md).

---

## How it works

```
Triage → Decompose → Vote R1 (parallel, isolated) → Judge aggregate
        → Vote R2 (disputed theses only) → Judge synthesize
```

After decomposition, one triage question forks the flow into two ceremonies: **panel** (vote on a formed decision, the flow above) or **duels** (explore an open problem — see [Duel mode](#duel-mode-explore-dont-just-evaluate) below). `--mode` forces the choice instead of relying on triage.

Decomposition itself is no longer a single pass — an internal Lumper-vs-Splitter negotiation over thesis grain settles per seam, on whichever argument is stronger, and the result surfaces as an always-visible trace line:

```
GRAIN: 6 theses (Splitter proposed 7, Lumper proposed 6) — ...
```

The full negotiation goes into the run record, not the trace line. `--grain fine|coarse` biases the negotiation toward more or fewer theses.

**Golden-standard roster** (4 roles, active by default):

| Role | Lens |
|---|---|
| `Optimizer` | correctness, readability, idiomaticity, simplification |
| `Skeptic` | holes, contradictions, unrealistic assumptions *(adversarial)* |
| `Security` | threat model, attack surface, secrets, authn/authz, supply chain |
| `Maintainability-advocate` | future-change cost, decomposition, naming, hidden coupling |

Plus two utility agents outside the vote: `Decomposer` (splits the question into theses, and surfaces the question's own unstated premise as T0 — a foundational thesis voted like any other) and `Judge` (aggregates, then synthesizes).

**Votes carry structured tags.** Statuses stay at 4 — tags ride alongside them. `FLIP:` is mandatory on every `DISPUTED` vote and names the evidence that would reverse it; `ANCHOR: "quote"` grounds a vote in a specific piece of the question or context instead of a bare opinion; `[impact: critical|moderate|minor]` ranks how much the outcome hinges on that thesis; `REFRAME:` lets any voter name the question behind the question when a thesis is mis-posed — ≥2 roles raising `REFRAME:` on the same thesis summons 🕊 the outside-the-frame voice early, and the reframe feeds the R2 re-vote. The Judge weights disputes carrying a `FLIP:` tag higher, flags votes with no `ANCHOR:`, and prioritizes critical-impact conflicts first.

**Panel invariants** (the panel's constitution):
- **Adversarial Presence** — the panel must contain ≥1 adversarial role (Skeptic by default).
- **Size** — 3 to 7 active roles.
- **No redundancy** — no two roles with heavily overlapping mandates active at once.

**Output** is an 8-section synthesis: Verdict, Holism check, Trade-offs, Blockers, Prerequisites, Nuances, Unresolved, Devil's advocate. It now opens with `CONSENSUS_STRENGTH` — `Strong` / `Working` / `Narrowly carried` / `Contested` — so you know how much weight the verdict can bear before reading a single section.

Every run writes a Verifiable Decision Record — a structured markdown transcript (question → intent → votes → conditions → dissent → verdict) — to `./consensus-runs/`, opt out with `--no-record`. The record is the artifact to attach when reporting a weak verdict. Each record opens with an `AUDIT_BLOCK` — a machine-readable summary (date, mode, roster, `consensus_strength`, verdict, key assumptions) — so you can paste the whole record into any external model and ask it to audit the panel's reasoning, no re-run required. Every run also appends one line — date, question, strength, verdict, link — to `./consensus-runs/INDEX.md`, turning your engineering decisions into a browsable ledger over time. These records contain your questions verbatim — treat as sensitive, and add `consensus-runs/` to `.gitignore` in git repositories (the skill drops a `README.txt` reminder in the directory on first write, and nudges you toward `.gitignore` if it detects a git repo).

`SKILL.md` is self-describing — its canonical Protocol block at the top **is** the specification the orchestrator executes. Read that one block and you know the whole system.

---

## Composable panel

The golden-standard roster above is active by default. An optional shelf of roles ships disabled:

| Role | Mandate | when_to_enable |
|---|---|---|
| `Performance-hawk` | Latency, throughput, resource consumption | Perf-critical / real-time code |
| `Product-thinker` | User value, JTBD, why this should exist | Product and spec decisions |
| `Scope-cutter` | Trims MVP excess, names what to cut | Risk of over-build, scope creep |
| `Simplicity-advocate` | Complexity beyond the value it delivers is a bug | Author/panel prone to over-engineering |
| `Domain-expert` | Pluggable domain lens | A narrow, specialized domain |
| `Resource-keeper` | Guards working assets — the appreciative-inquiry counterweight to a panel that's structurally careless about what already works | Panel is critic-heavy, risk of discarding a working asset |

`Resource-keeper` is the shelf's first role shipped as an actual agent file (opt-in via `--roles "+Resource-keeper"`, not active by default). Where every other default role is built to find fault, Resource-keeper's mandate runs the other way: it must name at least one thing that must survive regardless of which side wins the vote.

Enabling a role means editing the roster list in `SKILL.md`'s Protocol block — markdown is the config, there's no loader and no runtime machinery to route around. Skeptic is the default satisfier of the Adversarial Presence invariant; `Security` and `Scope-cutter` also qualify if you swap Skeptic out.

**Tuning roles:** the agent files ARE the source — editing mandates and operational heuristics in `~/.claude/agents/psychodrama-*.md` is a supported customization path, not a hack. Keep the vote-format contract (statuses + `CONDITION:` tag + `DISAGREEMENT` block) intact so the Judge can still parse it.

Full role metadata (`when_to_enable` / `conflicts_with`) is in [DESIGN.md · Role Library](DESIGN.md).

Not only for engineering: [examples/market-test-demo.md](examples/market-test-demo.md) puts a pricing decision in front of a panel of buyer personas minted with `--roles` — CFO, end user, procurement, the client's security lead — with Skeptic kept for the invariant.

---

## Duel mode (explore, don't just evaluate)

When triage reads the question as exploratory rather than a formed decision, it routes here instead of the panel. The Decomposer generates the 3-5 strongest perspectives the question actually calls for, then mints a pair for each: a Champion to argue it, and a Tailored Critic — a critic with a biography, purpose-built for that specific idea (not a generic skeptic; an antagonist shaped like "you have watched three rewrites die" for a rewrite-the-service idea), FLIP-disciplined against strawmen. Each pair gets one isolated exchange.

The Judge grades survival on four levels — `clean` / `scarred` / `gutted` / `unproven` — feeding into the same `CONSENSUS_STRENGTH` line the panel uses. A Champion's footnote (one sentence from the Judge on how the Champion would have answered its fatal flaw) fixes last-word bias at zero extra cost, and the Judge also names 🪑 the empty chair (the un-championed direction) — the option nobody was minted to defend. Rejected perspectives don't just disappear: their `FLIP:` tags invert into `Revisit if...` tripwires.

The duel structure follows the author's psychodrama practice: every idea deserves its own antagonist, and the stage decides who enters.

Cost is comparable to a full run (~9-13 calls). `--plan` is recommended here even more than in panel mode — steering which perspectives get minted before paying for duels is cheaper than re-running them. `--emergent` is now a deprecated alias for `--mode duels`.

A full real duel run — four critics with biographies independently converging on a verdict that broke the question's own premise: [`examples/duel-demo.md`](examples/duel-demo.md).

---

## The figures (when the stage is stuck)

In psychodrama, when a protagonist is truly stuck, the director brings in a figure from beyond the role system — God, the fool, the ancestor — someone with no stake in the dispute as posed. The protocol has two: one dissolves the deadlock from above, one breaks it from below.

🕊 **The outside-the-frame voice** exits the dispute's terms entirely and reports what the deadlock itself reveals — the view from outside, a `THE REFRAME:` line, and `Dissolves if:` conditions.

🔥 **The transgressive voice** names the one suppressed option nobody dared put on the table: why it's taboo, its honest price, and what it buys.

Both are non-voting — they don't cast AGREED/DISPUTED, they reframe or transgress. **Triggers:** a `REFRAME:` cluster (≥2 roles on one thesis), theses marked `stagnated`, or a `Contested` verdict. `--summon above|below|both` forces a figure regardless of trigger state; `--no-figures` suppresses both. Cost: +1-2 calls, only on deadlock — never on a clean run.

As with every role in this protocol, the agent files are the source: tune your own figures in `~/.claude/agents/psychodrama-*.md`.

Same release ships the shelf's first role as an actual agent file, `Resource-keeper` — the appreciative-inquiry counterweight to a panel of critics — see [Composable panel](#composable-panel).

---

## Spectator mode

`--spectator` renders the run as a match instead of a report. The Judge appends a `## Match report` to the synthesis: one block per thesis naming who struck first and with which tag (a real `ANCHOR:`/`FLIP:`/`CONDITION:`/`REFRAME:` quoted from the votes, never invented), who held and who flipped in round 2 and after which `STEELMAN:`, then a score line. Zero extra calls — it's a render pass over votes the panel already cast.

```
Match report

T4: Security struck first with ANCHOR: "default-no-auth Redis" — Optimizer held, Maintainability
    flipped in R2 after Security's STEELMAN. Score: 3:1 against unconditioned Redis.

### Figures on stage
none

### Minority report
Optimizer: Redis still wins on raw throughput if the operational cost is amortized...

### One-line result
Keep Postgres, add a scoped cache — carried 3:1, one dissent on record.
```

---

## Install

**Requirements:** Claude Code (the skill orchestrates panel roles via its subagent tool).

```bash
git clone https://github.com/CryptoColobrod/psychodrama-protocol.git && cd psychodrama-protocol
mkdir -p ~/.claude/skills/psychodrama-protocol ~/.claude/agents
cp SKILL.md DESIGN.md ~/.claude/skills/psychodrama-protocol/
cp agents/psychodrama-*.md ~/.claude/agents/
```

> Agent files must land at the **top level** of `~/.claude/agents/` — Claude Code does not scan subdirectories for agent definitions.

> A full panel run makes several calls on your strongest model and takes a few minutes — see the cost note above before your first run.

**Model tiers:** agents declare their tier in frontmatter — Decomposer, Judge, Skeptic and the figures on `opus`; Optimizer, Security, Maintainability-advocate, Resource-keeper and Champion on `sonnet`. `--model opus|sonnet|haiku` overrides for one run. No API key: the skill runs inside your Claude Code subscription.

**Usage:**

```
/psychodrama-protocol <your question>
```

or say "psychodrama" / "put this on stage" / "consensus panel" in a session.

**Flags:**

| Flag | Effect |
|---|---|
| `--with-external` | Force the external critic regardless of unanimity |
| `--save-adr` | Write an ADR file for this run (off by default) |
| `--no-record` | Skip writing the run record file |
| `--plan` | Dry-run checkpoint — Triage + Decompose only, then stop for approval before any votes are cast |
| `--roles` | One-run roster override — `+Shelf-role`, `-Role`, `+name(focus:'...')` for an ephemeral persona |
| `--mode` | Force `panel` or `duels` instead of relying on triage |
| `--grain` | `fine` or `coarse` — biases the Lumper/Splitter grain negotiation during decomposition |
| `--emergent` | Deprecated alias for `--mode duels` |
| `--summon` | `above`, `below`, or `both` — forces a figure regardless of trigger state |
| `--no-figures` | Suppresses both figures even if a deadlock trigger fires |
| `--spectator` | Render mode: the Judge appends a `## Match report` (per-thesis hits citing real tags, figures on stage, minority report, one-line result). Zero extra calls |
| `--position "<text>"` | Stage the Protagonist chair with this position: a Champion defends it in R1 (+1 call), voters stress-test it, the Judge reports `PROTAGONIST:`. Panel mode only |
| `--no-position` | Suppress the offer of a Protagonist chair even if the question states a stance |
| `--model opus\|sonnet\|haiku` | Override every agent's tier for this run |

**External critic (optional, any model):** used only as the anti-groupthink fallback when the panel goes fully unanimous on a security-adjacent thesis. Reached via a small ladder: configure any CLI that takes a prompt and prints text (one line in `SKILL.md`'s Protocol block — the [`gemini` CLI](https://github.com/google-gemini/gemini-cli) works out of the box as the default worked example), or skip the install entirely and use the built-in copy-paste handoff — the skill prints the critic prompt for you to paste into any other model you have, then paste the reply back. Decline either way and the run continues gracefully, with the status reported honestly (e.g. `skipped (user_declined)`) rather than failing. Before anything leaves the machine via the configured CLI, the skill prints a per-run confirmation naming the exact destination command and waits for your approval — `--with-external` forces the critic to fire, but never bypasses this confirmation.

---

## Update / Uninstall

**Update:**

```bash
cd psychodrama-protocol && git pull
```

then re-run the two `cp` commands from the install block above.

**Uninstall:**

```bash
rm -rf ~/.claude/skills/psychodrama-protocol
rm ~/.claude/agents/psychodrama-*.md
```

The `psychodrama-*` prefix on every agent file makes the second glob safe — it won't touch any unrelated agent files in `~/.claude/agents/`.

**Footprint:** the skill adds 6 prefixed entries to your global agent list (`~/.claude/agents/psychodrama-*.md`) plus `SKILL.md`/`DESIGN.md` under `~/.claude/skills/psychodrama-protocol/`. Runs also write records to `./consensus-runs/` in whatever working directory you ran the skill from — those are plain markdown files and can be deleted freely at any time.

---

## Honest scope

v1 ships **one** deeply-built panel — the code/engineering-decision preset. That's deliberate: a small, complete spike beats a wide, half-built system.

What's designed but not built — a dynamic role library with auto-assembly, automated relevance-weighting, a dedicated scope-triage agent, an `ANTIBODIES.md` failure-memory file, and additional presets (architecture / spec / strategy) — lives in [DESIGN.md · Future Arc](DESIGN.md) as a visible roadmap, not as half-wired code.

Output follows the user's language; internal status tokens (`AGREED`, `DISPUTED`, etc.) always stay English.

---

## License

MIT — see [LICENSE](LICENSE).

The Psychodrama Protocol is a community project, not affiliated with or endorsed by Anthropic.
