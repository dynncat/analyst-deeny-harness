---
name: create-subagents
description: Design and write a new Claude Code subagent definition from scratch. Use this when the user wants to BUILD or AUTHOR a custom subagent — "make a subagent for X", "create an agent that does Y", "I need an agent for Z", "write a subagent definition", "turn this workflow into a reusable agent". This is for CREATING new subagents, not for finding or installing existing ones from a library (use hire-subagent or find-skill for that).
---

# Create Subagents

A skill for designing and writing Claude Code subagent definitions that are well-structured, correctly scoped, and immediately usable.

Subagents are Markdown files with YAML frontmatter stored in `.claude/agents/` (project-scoped) or `~/.claude/agents/` (global). When Claude Code encounters a task matching an agent's description, it can delegate to that agent automatically — or the user can invoke it explicitly.

---

## Step 1: Capture Intent

Extract as much as possible from the current conversation before asking follow-up questions. If the user says "turn this into a subagent," derive the role and behaviors from what was already demonstrated.

Ask only what's still unclear:

1. **Role**: What specialist should this agent be? (e.g., "LLM evaluation expert", "SQL data engineer", "paper reviewer")
2. **Trigger**: When should Claude Code automatically invoke this agent? What user phrases or request types should activate it?
3. **Key behaviors**: What must this agent always do? Any hard rules or strong preferences?
4. **Scope**: Global (used across all projects) or project-specific?

---

## Step 2: Research Before Writing

For any non-trivial domain, **search external knowledge first** before writing the agent definition:
- What are current best practices and conventions in this domain?
- What tools, frameworks, or APIs should the agent know about?
- What failure modes or gotchas are commonly encountered?

A subagent grounded in real external knowledge is substantially more capable than one written from general intuition. Especially for specialist agents (ML engineer, security auditor, etc.), a 10-minute web search before writing makes a meaningful difference.

---

## Step 3: Choose Tool Permissions

Give the agent the minimum tools it needs for its role:

| Role type | Tools |
|-----------|-------|
| Read-only (reviewer, auditor, analyst) | `Read, Grep, Glob` |
| Research (web, literature, discovery) | `Read, Grep, Glob, WebFetch, WebSearch` |
| Code writer (developer, engineer, implementer) | `Read, Write, Edit, Bash, Glob, Grep` |
| Documentation writer | `Read, Write, Edit, Glob, Grep, WebFetch, WebSearch` |
| Full access (orchestrator, autonomous executor) | All tools |

Start minimal. Overly permissive agents are less predictable and harder to audit.

---

## Step 4: Choose the Model

| Model | When to use | Examples |
|-------|-------------|---------|
| `haiku` | Fast, narrow tasks; lookups; summaries | doc writer, build checker |
| `sonnet` | Standard implementation and reasoning (default) | developer, reviewer, debugger |
| `opus` | Deep analysis, architecture, complex reasoning | architect, security auditor, research synthesizer |

Default to `sonnet` unless there's a clear reason to go up or down.

---

## Step 5: Write the Subagent File

```markdown
---
name: agent-name           # kebab-case, unique, descriptive
description: >             # Primary trigger mechanism — be specific and slightly "pushy".
  When to invoke this agent. Include concrete task types, trigger phrases, and domain
  keywords. Claude tends to undertrigger — use "invoke for any...", "use when the user..."
  to help. Clarify what it does NOT handle if there's risk of overlap with another agent.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

You are a [specific role with expertise areas].

[Core persona and guiding philosophy — 2-4 sentences. Why does this agent exist? What makes it good at this specific task?]

---

## [Core section — workflow, responsibilities, or key behaviors]

[What the agent actually does, step by step or as principles]

## [Domain-specific patterns or checklists]

[Frameworks, decision rules, or heuristics the agent reliably applies]

## Output Standards

[What good output looks like — format, depth, tone]
```

### Writing a strong description

The description is the most important field. It controls when this agent is invoked.

**Weak:** `description: Python development expert`

**Strong:** `description: Expert Python engineer for implementation, debugging, and refactoring. Invoke when the user wants to write, fix, or improve Python code — especially data pipelines, ML scripts, async services, or CLI tools. Also use when the user says "write this in Python", "fix my Python error", or asks about Python-specific patterns like decorators, generators, or type hints. For architectural decisions across multiple services, use the architect agent instead.`

Rules for good descriptions:
- Lead with task types, not role title
- Include domain keywords (e.g., "LLM", "PyTorch", "RAG") for semantic matching
- Add example trigger phrases the user might actually say
- Clarify the boundary from other agents if there's potential overlap
- Be slightly pushy: "invoke for any...", "use when..." — Claude tends to undertrigger

See [references/description-patterns.md](references/description-patterns.md) for a full pattern guide with before/after examples and a mental-test checklist.

### Writing a strong persona

**Weak:** "You are a Python engineer."

**Strong:** "You are a senior Python engineer specializing in data pipelines and ML systems, with strong opinions about readability, testability, and avoiding premature abstraction. You write code you'd be proud to review."

### Explain the why, not just the what

Don't mandate with `MUST`/`ALWAYS`. Explain the reasoning — LLMs respond better to understanding than to rigid rules.

Instead of: *"ALWAYS add type hints"*
Write: *"Add type hints throughout — they make code self-documenting and catch errors early, which matters in ML systems where debugging is painful."*

### Use an archetype template

If unsure where to start, pick the closest archetype from [templates/archetypes.md](templates/archetypes.md) and fill it in. Four archetypes are available: domain specialist, read-only analyst, researcher, and lightweight utility.

See [references/examples.md](references/examples.md) for annotated real-world examples of each archetype.

---

## Step 6: Determine Storage Location

| Location | When to use |
|----------|-------------|
| `~/.claude/agents/` (global) | Role-specific agent that should follow you across all projects |
| `.claude/agents/` (project) | Agent tightly coupled to a specific codebase or project context |

Project agents override global agents with the same name.

Confirm the path with the user before writing.

---

## Step 7: Consider Companion Reference Files

For agents that need deep domain knowledge embedded, consider creating a `references/` folder alongside the agent file:

```
my-agent/
├── my-agent.md          (the agent definition)
└── references/
    ├── domain-basics.md
    └── tool-configs.md
```

Instruct the agent to read specific reference files when needed. This keeps the main `.md` file concise while giving the agent access to deep knowledge on demand. This pattern is used throughout `setup/research/agents/` — see `llm-sft-engineer/` or `llm-rl-engineer/` for examples.

---

## Step 8: Write and Review

Write the file to the chosen location. After writing, confirm:
- Where it was saved
- What triggers it (description summary)
- What tools it has and what model it uses

Do a quick mental test: "Would Claude invoke this agent when I want it to? Would it invoke it when I don't?" Adjust the description if either answer is wrong.

Offer to refine behavior or description based on the user's feedback.

---

## Tips

**Keep it lean.** Agents with 10+ sections become unpredictable. Prefer 4-6 well-chosen sections. If it's getting complex, consider splitting into two agents with distinct scopes.

**Avoid overlap.** If multiple agents exist, make sure their descriptions don't significantly overlap or they'll compete for the same tasks. When in doubt, add an explicit exclusion in the description ("for X, use Y agent instead").

**Test mentally before writing.** Simulate a few user prompts and ask yourself: would this description cause Claude to select this agent? Would any unintended prompts also match?

**Consider reference files.** For agents that need deep domain knowledge, store reference material in a `references/` subdirectory alongside the agent file and instruct the agent to read them as needed.
