# Providers & Model Aliases

Set via `hermes model` (picker) or `hermes setup`. 35+ provider profiles ship as
plugins under `plugins/model-providers/`; user plugins of the same name override.
Full docs: https://hermes-agent.nousresearch.com/docs/integrations/providers

### Providers

| Provider | Auth | Key env var(s) |
|----------|------|----------------|
| openrouter | API key | `OPENROUTER_API_KEY` |
| anthropic | API key | `ANTHROPIC_API_KEY` (also `CLAUDE_CODE_OAUTH_TOKEN`) |
| nous | OAuth device code | `hermes auth add nous` (or `NOUS_API_KEY`) |
| openai-codex | OAuth | `hermes auth add openai-codex` |
| qwen-oauth | OAuth | `hermes auth add qwen-oauth` |
| minimax-oauth | OAuth | `hermes auth add minimax-oauth` |
| copilot | Token | `COPILOT_GITHUB_TOKEN` / `GH_TOKEN` (Copilot device flow — `gh auth login` tokens do NOT work) |
| copilot-acp | External CLI | Copilot CLI on PATH or `COPILOT_CLI_PATH` |
| gemini | API key | `GOOGLE_API_KEY` or `GEMINI_API_KEY` |
| xai | API key | `XAI_API_KEY` (SuperGrok OAuth also supported) |
| deepseek | API key | `DEEPSEEK_API_KEY` |
| zai (GLM) | API key | `GLM_API_KEY` / `ZAI_API_KEY` |
| minimax / minimax-cn | API key | `MINIMAX_API_KEY` / `MINIMAX_CN_API_KEY` |
| kimi-coding / -cn | API key | `KIMI_API_KEY` / `KIMI_CN_API_KEY` |
| alibaba (+coding-plan) | API key | `DASHSCOPE_API_KEY` / `ALIBABA_CODING_PLAN_API_KEY` |
| xiaomi | API key | `XIAOMI_API_KEY` |
| huggingface | Token | `HF_TOKEN` |
| fireworks / novita / nvidia / deepinfra / gmi / arcee / stepfun / upstage / kilocode / ai-gateway / opencode-zen / opencode-go / ollama-cloud | API key | `<NAME>_API_KEY` |
| bedrock / vertex / azure-foundry | Cloud SDK / key | AWS SDK creds / Vertex ADC / `AZURE_FOUNDRY_API_KEY` |
| custom | Config | `model.base_url` + `model.api_key` in config.yaml |

Multiple credentials per provider pool and rotate automatically (`hermes auth`).
Fallback chain when the primary fails: `hermes fallback add|remove|list`.

### User-defined model aliases

Work with `/model <name>` in CLI and every gateway platform. Resolved by
`hermes_cli/model_switch.py::resolve_alias()`; user aliases are checked BEFORE
the built-in table, so a user `sonnet`/`grok` shadows the built-in.

```yaml
# Full form
model_aliases:
  fav:
    model: claude-sonnet-4.6
    provider: anthropic
  local-qwen:
    model: qwen3.5:397b
    provider: custom
    base_url: "https://ollama.com/v1"
  theta:
    model: theta-1
    provider: custom
    base_url: "https://theta.example.com/v1"
    key_env: THETA_API_KEY        # or: api_key: "${THETA_API_KEY}"

# Short form ("provider/model"), also via CLI:
#   hermes config set model.aliases.fav openrouter/anthropic/claude-sonnet-4.6
model:
  aliases:
    fav: openrouter/anthropic/claude-sonnet-4.6
```

`/model fav` — session-scoped; add `--global` to persist as default.

An alias with its own `base_url` authenticates with its own credential
(`api_key`, which also accepts a `"${VAR}"` reference, or `key_env`). With
neither set the key is resolved from the alias HOST, never carried over from
the provider that was active before the switch.

### Choosing models for Hermes slots (main, fallback, auxiliary)

Procedure when the user asks which model/provider to use for a slot:

1. **Map the slot first.** Read `config.yaml` (and each profile's) for `model`,
   fallback chain, `provider_routing`, and `auxiliary.*` (compression, vision,
   etc.). "Summarization" in Hermes mostly means `auxiliary.compression` —
   recommend for the slot actually doing the work, not the main model.
   **Enumerate every aux task from source, not from config**: `_AUX_TASKS` in
   `hermes_cli/main_provider_setup.py` plus `background_review`/`moa_*` in
   `hermes_cli/config_defaults.py`. A task with no block is `auto` = the main
   model (e.g. vision, voice_chat, kanban_decomposer, goal_judge, group_router)
   — it still needs a proposal. Propose for idle lanes too (e.g. `mcp` with no
   servers yet): the user will use them later, so "unconfigured" is never a
   reason to leave a slot alone. Drop dead blocks (`config_defaults.py` notes
   web_extract/session_search/skills_hub have no aux LLM any more).
2. **Pull live prices, don't quote from memory.** OpenRouter model list and
   per-host endpoints:
   ```bash
   curl -s https://openrouter.ai/api/v1/models | python3 -c 'import json,sys
   for m in json.load(sys.stdin)["data"]:
     if m["id"] in ("vendor/model-a","vendor/model-b"):
       p=m["pricing"];f=lambda k:round(float(p.get(k) or 0)*1e6,4)
       print(m["id"],m["context_length"],f("prompt"),f("completion"),f("input_cache_read"),"tools" in m["supported_parameters"])'
   curl -s https://openrouter.ai/api/v1/models/<vendor>/<model>/endpoints   # provider_name, quantization, pricing, uptime_last_30m
   ```
   Pipe curl straight into `json.load(sys.stdin)`; if you must load captured
   text, use `json.loads(s, strict=False)` (responses contain raw control chars).
3. **Gather benchmarks with sources** (Artificial Analysis index/Omniscience/
   AA-LCR, Vals, vendor blogs), note where sources disagree, and cite each number.
4. **Present a comparison table + a proposed plan; change nothing** until the
   user approves. Every revision re-presents the FULL plan, never a delta:
   (1) main fallback chain table, (2) aux table covering every task with
   what-it-does/frequency, now, proposed, why, (3) MoA reference/aggregator
   table, plus the YAML and a where-money-gets-spent table against the spend
   cap. Scope: list every config that gets the change (default + each profile). Offer a cheap empirical bake-off (same real transcript to each
   candidate, compare summaries against source for invented/missing facts) and
   estimate its cost against the user's spend cap.

5. **Apply (after approval).** When the `hermes` CLI isn't available (docker
   sandbox), edit each config with a Python regex pass on the text (keeps
   comments), copy each to `config.yaml.bak-<ts>` first, then validate by
   loading every file with PyYAML (`pip install -q --target /tmp/y pyyaml`;
   `PYTHONPATH=/tmp/y python3 -c ...`) and printing the resolved slots, plus a
   `diff` against the backup. Pass the explicit backup filename — older
   `.bak-*` files may exist and break a glob. Compare the pre-edit backup with
   the PREVIOUS change's backup too: the user may edit configs between your
   passes (CLI pickers, hand edits). Report such external changes and adapt
   the plan to them; never silently revert them.

Config gotchas (verified in source):
- Setting `auxiliary.vision.provider` flips `agent.image_input_mode: auto` to
  text mode — the main model stops seeing images natively. Pair it with
  `agent.image_input_mode: native`. `video_analyze` sends raw video, so the
  vision lane needs a video-capable model if the video toolset is enabled.
- `fallback_providers` entries take only provider/model; set fallback thinking
  via `agent.reasoning_overrides: {"openrouter/<vendor>/<model>": low}`.
- MCP sampling: a server's model hint overrides `auxiliary.mcp.model`
  (`tools/mcp_tool_sampling.py::_resolve_model`); pin with
  `mcp_servers.<name>.sampling.model` when servers are added.
- The aux auto-chain backup is a PAID OpenRouter model (gemini flash); set
  `auxiliary.openrouter_model` (e.g. a `:free` model) to control it.
- `voice_chat` runs a whole agent turn (history + tools) on that model, so it
  needs a long-context, tool-capable route.
- Groq free tier is 8K tokens/minute per model: one long main-session turn
  exceeds it, so Groq only suits small calls (MoA references, single images),
  never the main fallback chain or voice_chat.

Pitfalls:
- Artificial Analysis index versions differ (the same model can show 45 or 33);
  quote the current page and per-effort scores — non-reasoning modes often score
  far lower (DeepSeek Flash: 33 max / 29 high / 19 off), which matters when
  proposing `reasoning_effort: none`.
- The cheapest OpenRouter listing is usually an fp4 host, sometimes with poor
  uptime — price the first-party/fp8 endpoint too and recommend pinning via
  `provider_routing` (`only`/`order`/`ignore`). Verify in source which call paths
  (main agent vs auxiliary clients) actually honor `provider_routing` before
  promising it applies.
- Always-on/"max" reasoning models bill thinking as output tokens — a low
  per-token price can still cost more than a model that can disable thinking.
- Hallucination benchmarks like AA-Omniscience measure recall without context,
  not grounded summarization — state that limit instead of treating them as a
  summarization score; no public summarization leaderboard ≠ evidence of "best".
- Prompt caches are keyed per model/provider: a fallback switch re-reads the
  whole history at full input price, so frequent fallback erases cache savings.
- Tiny local models (≈4B) as `auxiliary.compression` produce summaries that
  invent tool names and mislabel the active task — flag compression quality
  when the session's own compaction summary shows it.

Built-in aliases (catalog-resolved against the active provider): `sonnet`,
`opus`, `haiku`, `claude`, `gpt5`, `gpt`, `codex`, `o3`, `o4`, `gemini`,
`deepseek`, `grok`, `llama`, `qwen`, `minimax`, `nemotron`, `kimi`, `glm`,
`step`, `mimo`, `trinity`.
