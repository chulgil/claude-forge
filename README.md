<p align="center">
  <img src="docs/banner.png" alt="Claude Forge" width="100%">
</p>

<h1 align="center">Claude Forge</h1>

<p align="center">
  <strong>Production-grade configuration framework for Claude Code</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href="https://claude.com/claude-code"><img src="https://img.shields.io/badge/Claude%20Code-%E2%89%A51.0-blueviolet" alt="Claude Code"></a>
  <img src="https://img.shields.io/badge/agents-23-green" alt="23 Agents">
  <img src="https://img.shields.io/badge/commands-79-orange" alt="79 Commands">
  <img src="https://img.shields.io/badge/hooks-23-red" alt="23 Hooks">
</p>

---

## What is Claude Forge?

Claude Forge is a batteries-included configuration framework that transforms Claude Code from a basic CLI into a full-featured development environment. It ships 23 specialized agents, 79 slash commands, 21 skill workflows, 23 security/automation hooks, and 10 rule files -- all wired together with a one-command installer.

> [Korean README (한국어)](README.ko.md)

---

## Quick Start

```bash
# 1. Clone
git clone --recurse-submodules https://github.com/sangrokjung/claude-forge.git
cd claude-forge

# 2. Install (creates symlinks to ~/.claude)
./install.sh

# 3. Launch Claude Code
claude
```

---

## Features

| Category | Count | Highlights |
|----------|-------|------------|
| **Agents** | 23 | planner, architect, code-reviewer, security-reviewer, tdd-guide, database-reviewer, web-designer, codex-reviewer, gemini-reviewer, ... |
| **Commands** | 79 | `/commit-push-pr`, `/handoff-verify`, `/explore`, `/tdd`, `/plan`, `/orchestrate`, `/generate-image`, ... |
| **Skills** | 21 | build-system, security-pipeline, eval-harness, team-orchestrator, session-wrap, ... |
| **Hooks** | 23 | 7-layer security defense, cross-model auto-review, MCP rate limiting, secret filtering |
| **Rules** | 10 | coding-style, security, git-workflow, golden-principles, agent orchestration, ... |
| **MCP Servers** | 9 | context7, memory, exa, gmail, github, fetch, jina-reader, desktop-commander, coingecko |

---

## Architecture

```
~/.claude/                      (symlinked by install.sh)
  ├── agents/                   23 specialized agent definitions
  ├── commands/                 79 slash commands
  ├── skills/                   21 multi-step workflows
  ├── hooks/                    23 event-driven scripts
  ├── rules/                    10 auto-loaded rule files
  ├── scripts/                  Utilities (md-to-docx, pdf-enhance)
  ├── cc-chips/                 CC CHIPS status bar (submodule)
  ├── cc-chips-custom/          Custom status bar overlay
  ├── knowledge/                Knowledge base
  ├── reference/                Reference documentation
  ├── setup/                    Installation guides
  └── settings.json             Permissions, hooks, env config
```

The installer creates **symlinks** from the repo to `~/.claude/`, so updates are instant via `git pull`.

---

## Key Features

### Cross-Model Review Pipeline

Automatic code review with multiple AI models for diverse perspectives:

- **Codex Reviewer**: OpenAI Codex-based second opinion on code changes
- **Gemini Reviewer**: Google Gemini 3 Pro frontend-focused review
- **Code Reviewer**: Claude-native comprehensive review

All three run automatically via PostToolUse hooks when files are edited.

### Security Hooks (7-Layer Defense)

| Layer | Hook | Trigger |
|-------|------|---------|
| 1 | `output-secret-filter.sh` | Every tool output |
| 2 | `remote-command-guard.sh` | Bash commands |
| 3 | `db-guard.sh` | SQL execution |
| 4 | `email-guard.sh` | Email sending |
| 5 | `ads-guard.sh` | Ad platform operations |
| 6 | `calendar-guard.sh` | Calendar modifications |
| 7 | `security-auto-trigger.sh` | Code changes |

### CC CHIPS Status Bar

Real-time status line showing model, session ID, token usage, and MCP stats. Powered by [CC CHIPS](https://github.com/roger-me/CC-CHIPS) with custom overlay.

### Agent Teams Support

Multi-agent collaboration with:
- Hub-and-spoke communication (leader coordinates)
- File ownership separation (no conflicts)
- Phase-based team rotation
- Decisions externalized to `decisions.md`

---

## Customization

Override any setting without modifying tracked files:

```bash
# Create your local overrides (git-ignored)
cp setup/settings.local.template.json ~/.claude/settings.local.json

# Edit with your secrets/preferences
vim ~/.claude/settings.local.json
```

`settings.local.json` is merged on top of `settings.json` by Claude Code.

---

## MCP Servers

Pre-configured in `mcp-servers.json`:

| Server | Purpose |
|--------|---------|
| context7 | Real-time library documentation |
| memory | Persistent knowledge graph |
| exa | AI-powered web search |
| gmail | Email management |
| github | Repository/PR/issue management |
| fetch | Web content fetching |
| jina-reader | URL-to-markdown conversion |
| desktop-commander | Desktop file/terminal operations |
| coingecko | Cryptocurrency market data |

Install via `./install.sh` or manually with `claude mcp add`.

---

## Project Structure

```
claude-forge/
  ├── .claude-plugin/       Plugin manifest
  ├── .github/workflows/    CI validation
  ├── agents/               Agent definitions (.md)
  ├── cc-chips/             Status bar submodule
  ├── cc-chips-custom/      Custom status bar overlay
  ├── commands/             Slash commands (.md + directories)
  ├── docs/                 Screenshots, diagrams
  ├── hooks/                Event-driven shell scripts
  ├── knowledge/            Knowledge base entries
  ├── reference/            Reference documentation
  ├── rules/                Auto-loaded rule files
  ├── scripts/              Utility scripts
  ├── setup/                Installation guides + templates
  ├── skills/               Multi-step skill workflows
  ├── install.sh            macOS/Linux installer
  ├── install.ps1           Windows installer
  ├── mcp-servers.json      MCP server configurations
  ├── settings.json         Claude Code settings
  ├── CONTRIBUTING.md       Contribution guide
  ├── SECURITY.md           Security policy
  └── LICENSE               MIT License
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding agents, commands, skills, and hooks.

---

## License

[MIT](LICENSE) -- use it, fork it, build on it.
