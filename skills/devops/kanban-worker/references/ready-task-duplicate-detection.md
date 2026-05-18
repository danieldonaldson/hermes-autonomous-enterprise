# Ready Task Duplicate Detection — Worked Example

> Found during PMO board health scan, 2026-05-15 21:00.

## The Pattern

8 tasks in `ready` (unassigned) status, all children of an already-completed parent task, with **identical titles** to 8 tasks that were already completed hours earlier under the same parent.

### Source of truth: the `kanban list` output

```
▶ t_7f1e03f4  ready     (unassigned)          Engineer: webhook — convert_to_intent unit tests
▶ t_3bed0500  ready     (unassigned)          Engineer: webhook — handler endpoint tests (verify_webhook + handle_webhook)
▶ t_bf36a0d6  ready     (unassigned)          Engineer: statemachine — build mock repositories
▶ t_d26ea8a6  ready     (unassigned)          Engineer: statemachine — idle/welcome + MainMenu routing tests
▶ t_85b1def5  ready     (unassigned)          Engineer: statemachine — browse flow tests
▶ t_0ab7479a  ready     (unassigned)          Engineer: statemachine — sell flow tests
▶ t_731d864c  ready     (unassigned)          Engineer: statemachine — purchases + system commands tests
▶ t_8e87a43d  ready     (unassigned)          Engineer: statemachine — edge case tests
```

### Cross-referenced done tasks (same titles, completed hours earlier)

```
✓ t_aa9bffea  done  tech-lead  Engineer: webhook — convert_to_intent unit tests
✓ t_ec0c3430  done  tech-lead  Engineer: webhook — handler endpoint tests (verify_webhook + handle_webhook)
✓ t_98635f6b  done  tech-lead  Engineer: statemachine — build mock repositories
✓ t_bbb6d270  done  tech-lead  Engineer: statemachine — idle/welcome + MainMenu routing tests
✓ t_e078c131  done  tech-lead  Engineer: statemachine — browse flow tests
✓ t_30d3eeda  done  tech-lead  Engineer: statemachine — sell flow tests
✓ t_6aa7f43a  done  tech-lead  Engineer: statemachine — purchases + system commands tests
✓ t_4e93641b  done  tech-lead  Engineer: statemachine — edge case tests
```

### Verification: same parent, both times

```bash
# Ready tasks' parent
$ hermes kanban show t_7f1e03f4 | grep 'parents:'
  parents:   t_6b196e06

# Done tasks' parent
$ hermes kanban show t_aa9bffea | grep 'parents:'
  parents:   t_6b196e06
```

Both sets of tasks are children of `t_6b196e06` ("Engineer: Wire Webhook Handler to Session State Machine") — which was completed at 2026-05-15 09:02.

### Root cause

The ready tasks were created at 19:19-19:20 by "user" — someone manually ran a decomposition for an already-completed parent task. The original child tasks (done at 09:11-09:39) had already covered the entire scope. The new tasks were spawned in `ready` with no assignee because no profile was claiming them.

### Confirming duplicate (not a re-do)

Check the completed timestamps on the done tasks vs the creation timestamp on the ready tasks:

- Done tasks: **completed** 2026-05-15 09:11 to 09:39
- Ready tasks: **created** 2026-05-15 19:19 to 19:20

There is no way work needed to be re-done 10 hours after completion with zero new requirements. The ready tasks are duplicates.

### Cleanup

Archive the duplicates (they cannot be assigned — doing so would double-execute completed work):

```bash
hermes kanban complete t_7f1e03f4 --summary "Duplicate of t_aa9bffea. Archived."
hermes kanban complete t_3bed0500 --summary "Duplicate of t_ec0c3430. Archived."
hermes kanban complete t_bf36a0d6 --summary "Duplicate of t_98635f6b. Archived."
hermes kanban complete t_d26ea8a6 --summary "Duplicate of t_bbb6d270. Archived."
hermes kanban complete t_85b1def5 --summary "Duplicate of t_e078c131. Archived."
hermes kanban complete t_0ab7479a --summary "Duplicate of t_30d3eeda. Archived."
hermes kanban complete t_731d864c --summary "Duplicate of t_6aa7f43a. Archived."
hermes kanban complete t_8e87a43d --summary "Duplicate of t_4e93641b. Archived."
```

### Prevention

To prevent this pattern, a decomposition agent or human operator should:
1. **Check the parent task's status** before creating child tasks — if the parent is already `done`, children are unlikely to be needed
2. **Cross-reference titles** against existing tasks under the same parent — if matching titles exist, the decomposition has already been executed
3. **Check the created/completed timestamps** — if the existing tasks were completed today, a new set is almost certainly a duplicate
