---
name: create-skills
description: Create a new Claude Code skill (SKILL.md) from scratch, or improve an existing one. Use this when the user wants to BUILD or WRITE a skill — "make a skill for X", "create a skill that does Y", "turn this workflow into a skill", "improve this skill", "write a SKILL.md for Z". This is for AUTHORING new skills, not for finding or installing existing ones from a library (use find-skill for that).
---

# Create Skills

A skill for designing, writing, and iteratively improving Claude Code skills (SKILL.md files).

At a high level, creating a skill looks like this:

- Decide what you want the skill to do and roughly how it should work
- Write a draft of the skill
- Run a few test prompts and evaluate the results (with and without the skill)
- Refine based on feedback
- Repeat until the skill reliably does what was intended

Your job is to figure out where the user is in this process and jump in to help them move forward.

---

## Step 1: Capture Intent

Start by understanding what workflow or behavior the user wants to capture. If the current conversation already demonstrates the workflow (e.g., they say "turn this into a skill"), extract the intent from conversation history first — tools used, sequence of steps, corrections made, input/output formats — before asking.

Otherwise, ask only what's still unclear:

1. What should this skill enable Claude to do?
2. When should it trigger? (what user phrases or contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs benefit from tests. Skills with subjective outputs (writing style, design) often don't need them. Suggest the appropriate default based on the skill type.

---

## Step 2: Research and Interview

Ask about edge cases, input/output formats, example files, success criteria, and dependencies before writing test prompts. Come prepared with context to reduce burden on the user.

**Search external knowledge before writing.** For any non-trivial domain, search the web or official docs first:
- What are the current best practices for this task?
- Are there established patterns, schemas, or tool-specific conventions to embed?
- What failure modes are known?

A skill grounded in real external knowledge is substantially more useful than one written from general intuition alone. Don't skip this step for domain-specific skills.

---

## Step 3: Write the SKILL.md

### Structure

Skills are directories, not single files. Use subdirectories actively — they're what separate a good skill from a great one:

```
skill-name/
├── SKILL.md                (required)
│   ├── YAML frontmatter    (name, description required)
│   └── Markdown body       (instructions, patterns, examples)
├── references/             (domain knowledge, loaded on demand)
│   ├── topic-a.md
│   └── topic-b.md
├── agents/                 (sub-agent instruction sets for internal sub-workflows)
│   └── grader.md           (e.g., a grader the skill spawns to evaluate outputs)
├── scripts/                (executable helpers for deterministic/repetitive steps)
│   └── process.py
└── assets/                 (templates, icons, static files used in output)
    └── template.html
```

**When to add each folder:**
- `references/` — any domain knowledge > ~100 lines that the main SKILL.md shouldn't repeat inline. Claude reads these on demand.
- `agents/` — when the skill orchestrates sub-tasks best delegated to a separate agent (grading, comparing, analyzing). These are skill-internal instruction sets, not globally-installed agents.
- `scripts/` — when a step is deterministic and repetitive enough that a script is faster and more reliable than asking Claude to do it ad hoc.
- `assets/` — templates, HTML viewers, fonts, or static files the skill produces or references.

Don't add folders for the sake of it — but don't shy away from them either. A flat SKILL.md that tries to include everything gets unwieldy fast.

### YAML frontmatter

```yaml
---
name: skill-name           # kebab-case
description: >             # Primary trigger mechanism — include when to use AND when not to.
  What this skill does, when to invoke it, what phrases should trigger it.
  Be slightly "pushy" — Claude tends to undertrigger. Include concrete task types
  and domain keywords. Clarify what it does NOT handle if there's overlap risk.
---
```

**Description is the most important field.** It controls whether Claude invokes the skill. Make it specific and contextual. Include keywords, task types, and example phrases. Clarify the boundary from adjacent skills (e.g., "for finding existing skills, use find-skill instead").

### Progressive Disclosure

Skills load in three levels:
1. **Frontmatter** (name + description) — always in context (~100 words)
2. **SKILL.md body** — loaded when skill triggers (<500 lines ideal)
3. **References/** — read on demand (no size limit)

Keep SKILL.md under 500 lines. If it's getting long, factor out sections into `references/` and link them clearly.

### Writing Patterns

**Output format** — define it explicitly:
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Summary
## Key findings
## Recommendations
```

**Examples** — include concrete before/after:
```markdown
## Example
Input: "Added JWT auth"
Output: "feat(auth): implement JWT-based authentication"
```

**Explain the why** — don't just mandate. LLMs respond better to reasoning than `MUST`. Instead of "ALWAYS add type hints", write "Add type hints throughout — they make code self-documenting and help catch errors early, which matters in ML systems where debugging is painful."

**Keep it lean** — remove anything not pulling its weight. If the skill is getting complex, consider splitting it.

---

## Step 4: Test Cases

After writing the draft, propose 2-3 realistic test prompts — things a real user would actually say. Share them with the user before running.

Save to `evals/evals.json`:
```json
{
  "skill_name": "my-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

---

## Step 5: Run and Evaluate

For each test case, run two versions:
- **With-skill**: Claude has access to the skill
- **Baseline**: Claude without the skill (or with the old version when improving)

Organize results by iteration:
```
skill-workspace/
├── iteration-1/
│   ├── eval-0/
│   │   ├── with_skill/outputs/
│   │   └── without_skill/outputs/
│   └── eval-1/...
└── iteration-2/...
```

While runs are in progress, draft assertions — objectively verifiable checks on the output. Update `evals/evals.json` with them.

After runs complete: grade each assertion, aggregate into a benchmark summary, and present results to the user qualitatively before making improvements.

---

## Step 6: Iterate

Based on user feedback:

1. **Generalize** — don't make narrow fixes for specific examples. Find the root cause and fix the principle.
2. **Explain the why** — reframe rigid rules as reasoning so the model understands the intent.
3. **Bundle repeated work** — if every test run independently wrote the same helper script, put it in `scripts/` so future invocations don't repeat it.
4. **Keep it lean** — remove instructions that aren't helping.

Repeat the test → review → improve loop until:
- The user says they're happy
- All feedback is empty (everything looks good)
- You're not making meaningful progress

---

## Step 7: Optimize the Description

After the skill is done, offer to optimize the description for better triggering accuracy.

Generate 20 eval queries — a mix of should-trigger and should-not-trigger. The most valuable negatives are near-misses: queries that share keywords with the skill but actually need something different. Run the optimization loop:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <current-model-id> \
  --max-iterations 5
```

Apply `best_description` from the output to the skill's frontmatter.

---

## Where to Save

- **Project-specific** skill: `.claude/skills/` in the project root
- **Global** skill: `~/.claude/skills/` (available across all projects)

---

## Tips for Great Skills

**Be specific in scope.** A skill that does one thing well beats a skill that tries to do everything.

**Test the description mentally.** Read it and ask: "Would Claude activate this skill when I want it to? Would it activate when I don't?" Adjust if either answer is wrong.

**Avoid overlap.** If multiple skills exist, make sure their descriptions don't significantly overlap — they'll compete for the same tasks.

**References for depth.** For complex skills, put deep reference material in `references/` subdirectories and link them clearly from SKILL.md. Claude reads them only when needed.
