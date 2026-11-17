# Durable & Background Systems

Four systems run alongside the main conversation loop. Quick reference
here; full developer notes live in `AGENTS.md`, user-facing docs under
`website/docs/user-guide/features/`.

### Delegation (`delegate_task`)

Spawn a subagent with an isolated context + terminal session.

- **Single:** `delegate_task(goal, context)`.
- **Batch:** `delegate_task(tasks=[{goal, ...}, ...])` runs children in
  parallel, capped by `delegation.max_concurrent_children` (check
  `hermes_cli/config_defaults.py` for the current default).
- **Background:** `delegate_task(background=true)` returns a handle
  immediately and keeps the parent loop going; the child's result
  re-enters the conversation as a new turn when it finishes.
- **Roles:** `leaf` (default; cannot re-delegate) vs `orchestrator`
  (can spawn its own workers, bounded by `delegation.max_spawn_depth`).
- **Not durable.** A backgrounded child is still process-local — if the
  parent process exits, the child is lost. For work that must outlive
  the process, use `cronjob` or
  `terminal(background=True, notify_on_complete=True)`.

Config: `delegation.*` in `config.yaml`.

**Strategies (`delegation.backend`, from the `advanced-delegation` plugin):**
`default` (delegation.model/provider or parent), `model_map` (named
provider/model routes under `delegation.backends.model_map.options`), or
`profile_routes` (child runs AS a listed profile: its model, credentials,
skills, SOUL.md, terminal policy). One mode at a time; the other mode's
block is kept. Mode changes apply from the next session. Plugin source and
README: `$HERMES_HOME/plugins/advanced-delegation/`.

**Subagent fallback — check this whenever routes are configured:**
- A child pinned by provider/model (every model_map route) gets NO
  fallback unless one is declared; `delegation.fallback_providers` defaults
  to null and does NOT inherit the top-level `fallback_providers`.
- Precedence: route's own `fallback_providers` → `delegation.fallback_providers`
  → none. `[]` on a route disables it. Profile routes use the target
  profile's own top-level chain.
- Fallback entries can't carry reasoning effort; the global
  `agent.reasoning_overrides` entry for that model applies.
- Keep slow models (≈20+ min/task) out of subagent chains, and remember
  `:free` OpenRouter fallbacks share the daily request quota with the main
  agent — parallel batches burn it fast.

**Planning profile routes (decide per profile before writing config):**
- Read every profile's `SOUL.md`, `profile.yaml` description and config diff
  vs default (`disabled_toolsets`, mounts, skills.disabled, memory provider)
  first — existing profiles often encode a kanban pipeline with human
  approval gates and deliberately disable `delegation`.
- Subagents can't ask the user and resolve approvals non-interactively, so a
  profile whose SOUL requires user approval is only a safe route for
  staging work; add a SOUL line that approval must come from the user
  directly, never relayed by an agent. Keep durable/approval-gated flows on
  kanban; use profile routes for in-turn fan-out.
- Switching from model_map loses per-task model tiers: each tier needs its
  own profile (e.g. cheap read-only lookup profile, deep read-only analysis
  profile, optional workspace-write engineer).
- Listing a profile hands its keys and terminal access to the delegator:
  lock new worker profiles down with mounts (vault read-only, no Hermes-home
  mount), not just SOUL text; enable profile_routes only in the profiles that
  should delegate.
- New profiles need their own `.env`/`auth.json` credentials and the default
  profile's aux/fallback sections; prefer `hermes profile create` on the host.

### Cron (scheduled jobs)

Durable scheduler — `cron/jobs.py` + `cron/scheduler.py`. Drive it via
the `cronjob` tool, the `hermes cron` CLI (`list`, `add`, `edit`,
`pause`, `resume`, `run`, `remove`), or the `/cron` slash command.

- **Schedules:** duration (`"30m"`, `"2h"`), "every" phrase
  (`"every monday 9am"`), 5-field cron (`"0 9 * * *"`), or ISO timestamp.
- **Per-job knobs:** `skills`, `model`/`provider` override, `script`
  (pre-run data collection; `no_agent=True` makes the script the whole
  job), `context_from` (chain job A's output into job B), `workdir`
  (run in a specific dir with its `AGENTS.md` / `CLAUDE.md` loaded),
  multi-platform delivery.
- **Invariants:** 3-minute hard interrupt per run, `.tick.lock` file
  prevents duplicate ticks across processes, cron sessions pass
  `skip_memory=True` by default, and cron deliveries are framed with a
  header/footer instead of being mirrored into the target gateway
  session (keeps role alternation intact).

User docs: https://hermes-agent.nousresearch.com/docs/user-guide/features/cron

### Curator (skill lifecycle)

Background maintenance for agent-created skills. Tracks usage, marks
idle skills stale, archives stale ones, keeps a pre-run tar.gz backup
so nothing is lost.

- **CLI:** `hermes curator <verb>` — `status`, `usage`, `run`, `pause`,
  `resume`, `pin`, `unpin`, `archive`, `restore`, `list-archived`, `prune`,
  `backup`, `rollback`.
- **Slash:** `/curator <subcommand>` mirrors the CLI.
- **Scope:** only touches skills with `created_by: "agent"` provenance.
  Bundled + hub-installed skills are off-limits. **Never deletes** —
  max destructive action is archive. Pinned skills are exempt from
  every auto-transition and every LLM review pass.
- **Cost:** the deterministic inactivity/prune sweep runs for free. The
  aux-model "consolidate overlapping skills into umbrellas" pass is
  **off by default** — opt in with `curator.consolidate: true` or
  `hermes curator run --consolidate`. Routine background curation costs
  zero tokens.
- **Telemetry:** sidecar at `~/.hermes/skills/.usage.json` holds
  per-skill `use_count`, `view_count`, `patch_count`,
  `last_activity_at`, `state`, `pinned`.

Config: `curator.*` (`enabled`, `interval_hours`, `min_idle_hours`,
`stale_after_days`, `archive_after_days`, `backup.*`).
User docs: https://hermes-agent.nousresearch.com/docs/user-guide/features/curator

### Kanban (multi-agent work queue)

Durable SQLite board for multi-profile / multi-worker collaboration.
Users drive it via `hermes kanban <verb>`; dispatcher-spawned workers
see a focused `kanban_*` toolset gated by `HERMES_KANBAN_TASK`, and
orchestrator profiles can opt into the broader `kanban` toolset. Normal
sessions still have zero `kanban_*` schema footprint unless configured.

- **CLI verbs (common):** `init`, `create`, `list` (alias `ls`),
  `show`, `assign`, `link`, `unlink`, `comment`, `complete`, `block`,
  `unblock`, `archive`, `tail`. Less common: `watch`, `stats`, `runs`,
  `log`, `dispatch`, `daemon`, `gc`.
- **Worker/orchestrator toolset:** `kanban_show`, `kanban_complete`,
  `kanban_block`, `kanban_heartbeat`, `kanban_comment`, `kanban_create`,
  `kanban_link`; profiles that explicitly enable the `kanban` toolset
  outside a dispatcher-spawned task also get `kanban_list` and
  `kanban_unblock` for board routing.
- **Dispatcher** runs inside the gateway by default
  (`kanban.dispatch_in_gateway: true`) — reclaims stale claims,
  promotes ready tasks, atomically claims, spawns assigned profiles.
  Auto-blocks a task after `failure_limit` consecutive spawn failures
  (default 2; configurable via `kanban.failure_limit` or per-task
  `max_retries`).
- **Isolation:** board is the hard boundary (workers get
  `HERMES_KANBAN_BOARD` pinned in env); tenant is a soft namespace
  within a board for workspace-path + memory-key isolation.

User docs: https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban
