# C++ Review Checklist

Self-review every task against this list before verifying it, and record findings as audit
notes in the task record. Each item names a failure mode that compiles, often passes tests on
amd64, and breaks later or on another target.

## Correctness and lifetime

- [ ] No dangling views: every `std::string_view`, `std::span`, reference or iterator outlives
      neither the object it points into nor a reallocation of it.
- [ ] Moved-from objects are not read; `std::move` is not applied to `const` objects.
- [ ] Every `Status` and `StatusOr` result is checked or propagated (`[[nodiscard]]` warns).
- [ ] Integer arithmetic cannot overflow or silently narrow; `size_t` to `int` conversions are
      checked; signed and unsigned values are not compared without a cast.
- [ ] No undefined behavior: no out-of-bounds access, uninitialized reads, `reinterpret_cast`
      type punning (use `std::bit_cast` or `std::memcpy`), or misaligned access.

## Portability (amd64, aarch64, armv7)

- [ ] Data that crosses a file, socket or device boundary uses fixed-width types and a defined
      byte order; no `long`, `size_t` or struct layout in a format.
- [ ] Nothing assumes 64-bit pointers or `long`: on armv7 both are 32 bits, and `time_t` width
      depends on the libc build.
- [ ] `char` signedness is not relied on (it is unsigned on Arm Linux).
- [ ] Platform-specific code is in a dedicated file selected in CMake, and `make cross` ran
      for every target the task names.

## Design and style

- [ ] Ownership is visible in types: values, `std::unique_ptr`, or a borrowed reference whose
      owner is documented; no owning raw pointers.
- [ ] Headers include what they use, declare nothing they do not need to, and every new public
      declaration has a comment with its contract and error codes.
- [ ] New includes between modules follow an edge in the
      [architecture](../design/architecture.md#dependency-direction) and the `DEPS` of the
      target; there is no cycle.
- [ ] No new global mutable state, singletons or hidden I/O; streams, clocks and paths are
      passed in.
- [ ] Names follow Google style: `CamelCase` types and functions, `snake_case` variables,
      `trailing_` private members, `kConstant` constants.

## Tests and evidence

- [ ] Tests cover the happy path, edge cases (empty, maximum, malformed input) and each error
      code a function can return; a bug fix has a regression test that failed before the fix.
- [ ] Tests are deterministic: no sleeps, wall-clock dependence, network, or test-order
      coupling; temporary files live under `testing::TempDir()`.
- [ ] `make ci` passed, including `host-asan`; warnings were fixed, not silenced.
- [ ] Heavy or CUDA translation units are marked `HEAVY` or `CUDA`; no build step bypasses the
      [build budget](development.md#build-budget).
