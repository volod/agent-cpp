# Task Records

`make task-start TASK=<id>` creates a record from the [template](template.md) as
`NNNN-<task-id>.md`, using the
[naming rules](../../guide/planning-workflow.md#durable-task-records), and adds a row here;
`make task-close TASK=<id>` marks the row `accepted`. Records keep the full task and its
evidence after it leaves the [plan](../plan.md); [current-state pages](../current.md) link them.

| Record | Task | Result |
| --- | --- | --- |
