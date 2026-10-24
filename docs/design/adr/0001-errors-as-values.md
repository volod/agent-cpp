# 0001: No exceptions; Status and StatusOr

- Status: accepted
- Context links: [Toolchain and build](../spec.md#toolchain-and-build),
  [AGENTS.md errors rule](../../../AGENTS.md#c-conventions).

## Context

The Google C++ Style Guide does not use exceptions. Device targets are small (Luckfox Pico has
64-256 MB RAM), error paths must be visible in signatures for agents and reviewers, and C++20
has no `std::expected`.

## Decision

- First-party code never throws or catches. Expected failures return `agent::Status` or
  `agent::StatusOr<T>` from `src/base/status.h`, whose names and codes follow `absl::Status`.
- Callers branch on `Status::code()`, never on message text; `AGENT_RETURN_IF_ERROR` propagates.
- Accessing `StatusOr::value()` on an error, or any other broken invariant, aborts with a
  message. That is a programming error, not an error path.
- `-fno-exceptions` is not set: the standard library and GoogleTest still use exceptions
  internally, and an exception escaping from them terminates the process, which is acceptable.

## Alternatives

- Exceptions: invisible in signatures and against the style guide.
- Abseil (`absl::Status`): the reference implementation, but a large dependency to build for
  every cross target before the product needs anything else from it. The API subset is
  name-compatible, so moving to Abseil later is mechanical.
- `std::expected` (C++23) or `tl::expected`: a language-level change or a dependency, and no
  canonical error codes.

## Consequences

Every fallible API shows its failure in its return type, and tests assert codes. Interfacing
with throwing third-party code requires a thin adapter that catches at the boundary and returns
a `Status`; such an adapter is the only place `catch` may appear, and it needs a review note.
