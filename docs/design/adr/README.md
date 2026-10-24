# Decision Records

A decision record keeps a choice that constrains later work, the alternatives that were
rejected and the evidence behind it, so agents do not reopen settled questions or silently
contradict them. Task records say what one task did; decision records say what every later task
must respect.

Write one when a task chooses a dependency, toolchain, target, error or concurrency model, file
format, or public contract, or reverses an earlier record. Copy the [template](template.md) to
`NNNN-<short-title>.md` with the next number, add a row below, and link it from the task record.
A record is never edited after it is accepted, except its status: a reversal is a new record
that marks the old one `superseded by NNNN`.

| Record | Decision | Status |
| --- | --- | --- |
| [0001](0001-errors-as-values.md) | No exceptions; `Status` and `StatusOr<T>` | accepted |
| [0002](0002-static-device-binaries.md) | Distribution cross compilers and static device binaries | accepted |
| [0003](0003-build-budget.md) | One build budget with compile, link and heavy job pools | accepted |
