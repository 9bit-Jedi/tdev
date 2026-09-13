---
name: u:implementation
description: Implement a Linear issue end-to-end via worktree, plan approval, focused implementation, tests, pre-commit, and a suggested commit message.
---

# Linear Issue → PR Implementation

1. Read the Linear issue and understand its requirements, context, and acceptance criteria.

2. Create a new local branch and worktree using `gwa` (alias for `git worktree add`).

   * Branch/worktree name: `<LINEAR-ID>-<two-word-context>`
   * Keep the context short and unique.
   * Branch and worktree must use the same name.
   * Move the current claude conversation to the new worktree. Use `mv /home/utsah/.claude/projects/-home-utsah-codingal-main/<CLAUDE_SESSION_ID-uuid>.jsonl /home/utsah/.claude/projects/<new-worktree-folder-name>/`. If sister folder doesn't exist, use mkdir.

3. Before coding, inspect the relevant code and produce a very short implementation plan using Ponytail Ultra:

   * Files/components affected
   * Required changes
   * Tests needed, if any
   * Assumptions, edge cases, compatibility concerns, and production impact
   * Consider all relevant application layers and interactions.

4. Share the findings and plan for approval. Do not implement anything until approval is received.

5. After approval, implement the changes quickly using Ponytail Ultra.

   * Keep changes focused on the Linear issue.
   * Avoid unrelated refactors or changes.

6. Add unit tests for significant new functionality or meaningful behavior changes.

   * Skip tests for small/non-significant changes when existing coverage is sufficient.
   * Tests must follow existing codebase conventions and remain compatible with likely future changes.

7. Run:
   `pre-commit run`

   Use it to format and validate the changed code.

8. Do not commit anything.

   * At the end, suggest a commit message in this format:
   * `<LINEAR-ID>: <8-20 words describing the major changes>`

Core rule: Understand → Inspect → Plan → Get approval → Implement → Validate → Suggest commit message.
