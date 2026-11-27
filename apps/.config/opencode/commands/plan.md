---
description: Generate a strict plan file for a local 9B model to execute
---

Analyze the referenced files and task below to implement: $ARGUMENTS

Write the output directly to `~/.config/opencode/plans/current-plan.md`. You are writing these instructions for a small local 9B model to execute—it needs zero ambiguity, exact file paths, and concrete verification steps.

Format `~/.config/opencode/plans/current-plan.md` using strictly this structure:

## 1. Scope & Guardrails

- **Target files:** (List ONLY the files to be modified)
- **Do NOT touch:** (List files/systems to ignore)
- **Required imports/APIs:** (List exact module names and versions—no guessing)

## 2. Step-by-Step Implementation

(Break changes into small, atomic steps. One file per step.)

### Step 1: [Exact File Path]

- **Locate:** `[Exact anchor line or block of existing code]`
- **Action:** [Replace / Insert After / Delete]
- **Code:**

```[language]
[Exact code snippet to apply]
```
