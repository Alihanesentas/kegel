---
description: Sync this fork with the upstream repo (cagdascoskun/kegel) and update local master.
agent: build
---

Sync the fork with upstream:
1. Verify remotes: `git remote -v` (origin = Alihanesentas/kegel, upstream = cagdascoskun/kegel). If upstream is missing, add it.
2. `git fetch upstream && git fetch origin`
3. Report how far behind/ahead local master is vs upstream/master and origin/master.
4. If the working tree is clean and local has no divergent commits, fast-forward master to upstream/master and push to origin. Otherwise STOP and show the divergence — never force-push and never discard local commits.
$ARGUMENTS
