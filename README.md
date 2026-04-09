# Salvo

A coordinated sub-agent swarm for [OpenCode](https://github.com/opencode-ai/opencode). Give it a spec, it builds, tests, and reviews your code autonomously — using local models.

## The Problem

Local LLMs (Qwen, Gemma, Llama, etc.) stop generating after 1-3 tool calls. Every agentic coding tool fights this. They all lose. Your agent reads a file, writes some code, maybe runs a test — then stops. You hit enter. It does one more thing. Stops again. That's not autonomous. That's a fancy autocomplete.

## The Fix

Stop fighting the model. Work *with* it.

Salvo splits work across focused sub-agents. Each one does exactly one job and returns — by design. An orchestrator coordinates the pipeline. The model's tendency to stop becomes the architecture, not a bug.

```
Orchestrator (primary)
  ├── @code-writer    — implements features
  ├── @test-writer    — writes and runs tests
  ├── @code-reviewer  — PASS/FAIL code review
  ├── @task-tracker   — tracks progress in tasks.json
  └── @bug-reporter   — documents unfixable issues
```

**spec → implement → test → review → ship.** Each step is one focused agent call. No token-burning retry loops. No hoping the model keeps going.

## Quick Start

### Prerequisites

- [OpenCode](https://github.com/opencode-ai/opencode) installed and configured with at least one model provider
- A model that supports tool calling (Qwen 3.5, Gemma 4, Llama 3.3, etc.)

### Install

```bash
git clone https://github.com/nicdavidson/salvo.git
cd salvo
./setup.sh install
```

That puts `oc-salvo` on your PATH. Then in any project:

```bash
cd my-project
oc-salvo init
```

Done. Agents are copied into `.opencode/agent/` and ready to go.

### Run

```bash
cd your-project
opencode
```

The orchestrator is your default agent. Give it work:

```
Build a REST API for managing todo items with SQLite storage.
```

Or point it at a spec file:

```
Read spec.md and build everything in it.
```

Or use sub-agents directly:

```
@code-writer Add a /api/users endpoint with pagination.
```

## Agents

| Agent | Purpose | Mode | Can edit files? |
|-------|---------|------|----------------|
| `orchestrator` | Drives the full build pipeline | primary (default) | yes |
| `@code-writer` | Implements features | subagent | yes |
| `@test-writer` | Writes and runs tests | subagent | yes |
| `@code-reviewer` | Reviews code quality | subagent | **no** (read-only) |
| `@task-tracker` | Manages `tasks.json` + `progress.md` | subagent | yes (state files only) |
| `@bug-reporter` | Documents bugs when fixes fail | subagent | **no** (read-only) |

## How the Pipeline Works

```
┌─────────────────────────────────────────────────┐
│                  Orchestrator                    │
│                                                  │
│  1. Parse spec → break into features             │
│  2. @task-tracker init                           │
│                                                  │
│  For each feature:                               │
│    ├── @code-writer  → implement                 │
│    ├── @test-writer  → write + run tests         │
│    │   └── FAIL? → @code-writer fix (2x max)     │
│    │       └── Still failing? → @bug-reporter    │
│    ├── @code-reviewer → review                   │
│    │   └── FAIL? → @code-writer fix (2x max)     │
│    └── @task-tracker → mark complete             │
│                                                  │
│  3. @task-tracker summary                        │
└─────────────────────────────────────────────────┘
```

- **Max 2 fix attempts** per issue — prevents infinite token-burning loops
- **Unresolvable issues** get documented as bug reports, not retried forever
- **Progress tracking** via `tasks.json` survives session restarts

## Configuration

### Setting a model

Agents ship without a hardcoded model — they use whatever OpenCode defaults to. To pin a specific model, add `model:` to any agent's frontmatter:

```yaml
---
description: Implements features from specs or task descriptions.
model: ollama/qwen3.5:27b
---
```

### Customizing agents

Each agent is a single markdown file in `.opencode/agent/`. The frontmatter controls behavior:

```yaml
---
description: What this agent does (shown in @ menu)
prompt: System prompt for the agent
mode: primary | subagent
model: provider/model-name        # optional
temperature: 0.2                  # optional
tools:
  read: true
  write: true
  edit: true
  bash: true
  glob: true
  grep: true
---
```

The body of the file is the agent's detailed instructions. Edit freely — these are yours.

### Already global

If you ran `./setup.sh install`, `oc-salvo` is already on your PATH. Just `oc-salvo init` in any project.

## Writing Good Specs

Salvo works best with clear specs. A good spec has:

```markdown
# Project: My App

## Feature 1: User Authentication
- POST /api/register — email + password, returns JWT
- POST /api/login — email + password, returns JWT
- Passwords hashed with bcrypt
- JWT expires in 24h

## Feature 2: Todo CRUD
- GET /api/todos — list all for authenticated user
- POST /api/todos — create, requires title
- DELETE /api/todos/:id — delete, only owner can delete
```

Concrete endpoints. Clear acceptance criteria. No ambiguity. The more specific your spec, the better Salvo builds it.

## Adding Your Own Agents

Create a new `.md` file in your project's `.opencode/agent/` directory:

```yaml
---
description: What it does
prompt: You are a... [system prompt]
mode: subagent
tools:
  read: true
  bash: true
---

## Purpose
What this agent is for.

## Rules
- What it should and shouldn't do.
```

The orchestrator can call any agent with `@agent-name`. Add new specialists as needed — a `@db-migrator`, `@api-designer`, `@security-auditor`, whatever your workflow needs.

## Contributing

PRs welcome. Some areas that could use work:

- **New agents** — security auditor, API designer, documentation writer, performance profiler
- **Orchestrator improvements** — better error recovery, parallel feature building, smarter retry logic
- **Model-specific tuning** — temperature, prompt tweaks for different model families
- **Pipeline variants** — not everything needs the full test+review cycle
- **Examples** — real specs and the code Salvo built from them

If you've got a local model setup and opinions about how agents should coordinate, this is your repo.

### How to contribute

1. Fork the repo
2. Create a branch (`git checkout -b my-agent`)
3. Add or modify agents in `agents/`
4. Test with OpenCode locally
5. Open a PR with what you changed and why

Keep agent files focused. One job per agent. If an agent needs 200 lines of instructions, it's doing too much.

## Why "Salvo"?

A salvo is a coordinated volley — multiple shots fired in sequence, each aimed at a specific target. That's what this does. Each agent fires one focused burst, hits its target, and the next one goes. No spray and pray. No single-agent-does-everything chaos.

## License

MIT
