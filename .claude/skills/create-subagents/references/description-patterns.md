# Description Field Patterns

The `description` field is the single most important part of a subagent definition. It controls whether Claude Code invokes the agent at all — a poorly written description means the agent never gets used, regardless of how good the body is.

---

## How Triggering Works

Claude sees each available agent as a name + description pair. When a user sends a message, Claude decides whether to delegate to an agent based on whether the description matches the intent.

Key mechanics:
- Claude reads **description only** to decide — it does NOT read the agent body at decision time
- Claude tends to **undertrigger** (not invoke when it should) more than overtrigger
- Descriptions with **concrete task types and example phrases** trigger more reliably than abstract role descriptions
- Claude won't delegate simple one-step tasks it can handle directly; descriptions should emphasize **complex or specialized** use cases

---

## Pattern 1: Task-first, not role-first

**Role-first (weak):**
```
description: Python expert for all Python-related work.
```

**Task-first (strong):**
```
description: Expert Python engineer for implementation, debugging, and refactoring.
  Invoke when the user wants to write, fix, or improve Python code — especially data
  pipelines, ML scripts, async services, or CLI tools.
```

Lead with what the agent *does*, not what it *is*. The role is implied by the tasks.

---

## Pattern 2: Include trigger phrases

List the literal things a user might say that should activate the agent:

```
description: ...Use for any SFT task — "fine-tune this model on my dataset",
  "set up LoRA training", "configure Axolotl for SFT", "my SFT loss isn't converging",
  "compare LoRA vs DoRA", "my model forgets after fine-tuning".
```

These phrase examples act as semantic anchors. Claude pattern-matches against them even when the user's actual phrasing differs.

---

## Pattern 3: Domain keyword density

Include specific, searchable terms from the domain:

```
description: Specializes in Axolotl, Unsloth, TRL SFTTrainer. Covers LoRA, QLoRA,
  DoRA, RSLoRA, GaLore, PEFT, gradient checkpointing, sample packing, flash attention.
```

Generic terms like "machine learning" are less effective than specific ones like "LoRA", "bfloat16", "GRPO". Specific keywords reduce false negatives.

---

## Pattern 4: Explicit boundary (exclusion)

When two agents have overlapping domains, add an explicit exclusion:

```
description: ...Focused purely on SFT — for RL-based post-training (DPO, GRPO, PPO),
  use llm-rl-engineer.
```

```
description: ...Does NOT write fixes — use a developer agent for remediation after audit.
```

Without this, Claude may invoke the wrong agent or split work incorrectly between overlapping agents.

---

## Pattern 5: "Also use when" for secondary use cases

Capture non-obvious invocation contexts:

```
description: ...Also use when surveying literature before starting a new research direction.
```

```
description: ...Also use at the start of a project to produce a codebase map for other agents.
```

This extends the agent's reach to pipeline/orchestration contexts, not just direct user requests.

---

## Pattern 6: Slightly pushy language

Claude undertriggers by default. Use slightly assertive phrasing:

**Passive (undertriggers):**
```
description: Available for Python help when needed.
```

**Active (triggers reliably):**
```
description: Invoke for any Python implementation task. Use when the user mentions
  Python, asks to write a script, or needs debugging help with Python code.
```

Phrases that help: "Invoke for any...", "Use when...", "Always use this agent when..."

---

## Anti-Patterns

### Too short
```
description: Security expert.
```
No task types, no trigger phrases, no boundaries. Claude has no information to match against.

### Too long and unfocused
Descriptions > 10 lines with no structure become noise. Front-load the most important trigger information in the first 2-3 lines.

### Abstract qualities only
```
description: A thoughtful, experienced, senior engineer who values quality and
  mentors junior developers.
```
These are persona qualities, not trigger signals. Move them to the agent body.

### Overlap without exclusion
If two agents both say they handle "code review," Claude picks one somewhat arbitrarily. Add explicit exclusions or differentiate the scope clearly.

---

## Template: Description Structure

```
{Primary role} for {core task types}.
Use when the user wants to {specific action} — especially for {domain/tech/context}.
Also invoke when the user says "{phrase 1}", "{phrase 2}", or asks about {topic}.
[Optional: For {related thing}, use {other-agent} instead.]
```

Example filled in:
```
Expert in LLM reward modeling and RL post-training for language models.
Use when the user wants to set up GRPO, DPO, or PPO training — especially for math
reasoning, code generation, or tasks with verifiable reward signals.
Also invoke when the user says "train with GRPO", "set up reward model", "my RL
loss isn't converging", or "compare DPO vs GRPO".
For supervised fine-tuning (SFT), use llm-sft-engineer instead.
```

---

## Checking Your Description

Before finalizing, run this mental test:

1. Say 5 things a user might ask that SHOULD trigger this agent. Would your description match?
2. Say 3 things a user might ask that SHOULD NOT trigger this agent. Would your description incorrectly match?
3. Is the first sentence enough context if Claude only reads that far?
4. Does it mention at least 3 specific domain terms?
5. Is there an explicit exclusion if another agent overlaps?
