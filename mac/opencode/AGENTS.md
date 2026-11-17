# Engineering rules

These override style considerations. Apply them to all implementation work.

- Build the simplest thing that works end to end: no speculative abstractions,
configuration, or indirection, and no stopgaps meant to be replaced later. Remove
obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Grow in layers on top of a product that already works; never trade a working
product for unfinished complexity. Keep components modular and concerns clearly
separated.
- Reuse before writing: check the project's existing dependencies, and their docs
and types, before adding a package or reimplementing. Prefer established,
well-maintained libraries.

## Working order — issue, go-ahead, fix, approval, commit

Nothing gets implemented before it is written down, and nothing gets committed
before Mike approves it. NOTE: This working order is only relevant when operating
in projects, general aid can skip.

1. **State the goal.** What is broken or being built, and what done looks like.
2. **Open the Plane work item** on plane.freno.me (workspace `frenocorp`) in the
   right project — see "Projects and identifiers" below. The body carries the
   observed symptom and the root cause, not just the title. One issue per fix; a
   parent when the work spans several. Set priority, but do not assign (waste of a
   call here).
3. **Stop for the go-ahead.** Wait for Mike to acknowledge the issue and say to
   proceed. Reading, mapping, and reproducing are fair game before this point;
   editing product code is not.
4. **Fix and verify** — ALWAYS use worktrees it is highly likely concurrent work
   will be ongoing, use `<proj-dir>/.worktrees/<plane-id>` (ex:
   `.worktrees/NOOK-198`), past that - Project dependent - consult local AGENTS.md.
   Prove the new test fails without the fix, not only that it passes with it.
5. **Report and stop.** Say what changed and what was verified, then wait for
   approval. Committing unapproved work is out of scope, as is sweeping someone
   else's unrelated in-flight edits into your commit.
6. **Commit and merge** in the house style: `area: imperative summary`, a body that
   explains *why* — the symptom and the cause, not a list of files — a `Tests:`
   line, and the issue identifier in the footer (ex: `NOOK-198`).
7. **Close the loop in Plane**: comment the short commit hash on the work item,
   then move it to In Review for Mike to dogfood, and prune the worktree.

When commenting, writing descriptions (anything but titles), always prefix with
"[<model_name>]", model_name being you.

A fix that uncovers a separate defect opens its own issue at step 4 rather than
widening the one in hand.

When claiming an issue, always mark as in progress, when asked to pickup work,
make sure to not pick work marked in progress.

If you find unrelated bugs, issues or anything needing a fix, opening a new issue
in Plane is appropriate.

## Projects and identifiers

Work items are `<PROJECT>-<sequence>`, ex: `NOOK-198`, `LINE-42`. The project
prefix is fixed per project and is part of every identifier, commit footer and
worktree path. Plane's own UUIDs stay internal.

| Identifier | Project | Use for |
| --- | --- | --- |
| `NOOK` | The Nook | Nook product work |
| `LINE` | Lineage | Lineage product work |
| `MAGN` | MagniFluo | MagniFluo product work |
| `FLEX` | FlexLove | FlexLove product work |
| `MISC` | Unsorted | Overflow — anything filed without a project. File here only when the project is genuinely unclear, and re-home items when triaging. |

States available in every project: `Backlog`, `Todo`, `In Progress`, `In Review`,
`Done`, `Cancelled` (British spelling — Plane's default), `Duplicate`. Priorities:
`urgent`, `high`, `medium`, `low`, `none`.

Plane lives behind `mcp__plane__*` tools (codemode transport), so calls are cheap
on context. `~/.pi/agent/extensions/plane-guard.ts` blocks actions this instance
cannot serve — if a call is blocked, the reason names the working alternative.

Plane MCP quirks (Community Edition 1.4.2, verified empirically):

- Most calls need `project_id` plus the work item's UUID `workitem_id`. The
  `PROJECT-N` identifier works only via
  `workitem` + `action: "retrieve_by_identifier"` + `workitem_identifier`.
- `workitem` + `action: "search"` returns **zero hits for every query**. Find
  items by identifier, or by `action: "list"` per project.
- `workitem` `list` and `state` `list` require `project_id`; states and labels are
  per-project, not workspace-wide, so resolve their IDs inside the target project.
- Comments: `workitem_comment` + `action: "create"` + `comment_html` (HTML only).
- **Work item relations do not exist on this build** (`workitem_relation` is dead).
  Record blocking/duplicate relationships as a `Related to:` line in the
  description instead, and file a parent for genuine hierarchy — `parent` works.
- `create` silently drops `assignees` when the assignee is the workspace owner.
  Assign via `action: "update"`, then read the item back to confirm.
- Pages, collections, initiatives, milestones, estimates, templates, releases and
  customer tooling are unavailable here; so are attachments and work logs.
- Plane rate-limits writes (HTTP 429) under bursts — pace writes and retry with a
  long backoff rather than assuming a failure is permanent.
