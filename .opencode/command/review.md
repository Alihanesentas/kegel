---
description: Run the quality-reviewer subagent on the current diff before committing.
agent: build
---

Delegate to the `quality-reviewer` subagent: audit the current working-tree diff (`git diff` + staged changes) against the CLAUDE.md checklist. Return its VERDICT (APPROVE / REQUEST_CHANGES / BLOCK), blocking issues with file:line, and anything it could not verify. Do not fix anything yourself — just report. $ARGUMENTS
