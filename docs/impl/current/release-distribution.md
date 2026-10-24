# Release Distribution

## Packaging

`make dist [TARGET=T] [TAG=vX.Y.Z]` produces the archive the
[specification](../../design/spec.md#release-distribution) requires.

- `make/dist.mk` takes the name and version that `make/config.mk` reads from `project()` in
  `CMakeLists.txt`, rejects an
  unknown `TARGET`, a `TAG` other than `v<version>` and `linux-amd64` on a non-x86_64 host
  before building, and defaults to `linux-amd64`.
- It configures the target's release preset with `-DAGENT_BUILD_TESTS=OFF` and
  `-DAGENT_TARGET_NAME=<target>`, builds it, stages `dist/<name>-<version>-<target>/` with
  `cmake --install --strip` (the executable under `bin/`, `README.md` and `LICENSE` under
  `share/doc/<name>/`), and writes a `.tar.gz` with GNU tar: sorted entries, owner `0:0`,
  `SOURCE_DATE_EPOCH` (default `0`) timestamps and `gzip -n`.
- Release presets link statically: `host-release` for `linux-amd64`, `rpi5-release`,
  `luckfox-release`.

## Release workflow

`.github/workflows/release.yml` runs on pushed tags matching `v*.*.*`: the `gate` job runs
`make ci` and `make cross` in `ubuntu:24.04`; the `build` matrix runs
`make dist TARGET=<T> TAG=<tag>` for `linux-amd64`, `rpi5` and `luckfox-pico`; the `publish`
job writes and verifies `SHA256SUMS` and runs
`gh release create <tag> dist/* --verify-tag --generate-notes`. `ci.yml` runs `make dist` for
every target on each push and pull request.

## Tests

`tools/tests/make_test.sh` covers the tag check and unknown targets; CI builds and uploads the
archives for every target.
