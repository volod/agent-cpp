#!/bin/sh
# Tests of tools/doc-links.sh on a throwaway repository.
set -eu
# shellcheck source=lib.sh
. "$(dirname -- "$0")/lib.sh"

dir=$scratch/links
mkdir -p "$dir/docs/sub" "$dir/.hidden" "$dir/third_party/lib"
git -C "$dir" init -q
cat >"$dir/docs/guide.md" <<'EOF'
# Guide

## Heavy compilation (Ninja / CMake / CUDA)

## Repeated

## Repeated

Same file [anchor](#repeated-1), [directory](sub/), [up](../README.md#top).
EOF
printf '# Top\n' >"$dir/README.md"
printf '# Sub\n' >"$dir/docs/sub/page.md"
printf '[broken](missing.md)\n' >"$dir/.hidden/notes.md"
printf '[broken](missing.md)\n' >"$dir/third_party/lib/README.md"

links() {
  sh "$tools/doc-links.sh" -C "$dir"
}

# case <name> <markdown line> <exit code> <expected output>
case_line() {
  printf '%s\n' "$2" >"$dir/docs/sub/case.md"
  expect "$1" "$3" "$4" links
}

case_line "good links" '[a](page.md) [b](../guide.md#heavy-compilation-ninja--cmake--cuda)' 0 \
  "lint-doc-links: ok"
case_line "external and mail links" '[a](https://example.com/x.md) [b](mailto:a@b.c)' 0 \
  "lint-doc-links: ok"
case_line "inline code is not a link" 'Write `[a](nowhere.md)` like this.' 0 "lint-doc-links: ok"
case_line "fenced code is not a link" "$(printf '```\n[a](nowhere.md)\n```')" 0 "lint-doc-links: ok"
case_line "angle brackets" '[a](<page.md>)' 0 "lint-doc-links: ok"
case_line "broken file" 'x [a](nowhere.md)' 1 'docs/sub/case.md:1: broken link "nowhere.md"'
case_line "missing anchor" '[a](../guide.md#nope)' 1 'missing anchor "../guide.md#nope"'
case_line "repeated heading suffix" '[a](../guide.md#repeated-2)' 1 'missing anchor'
case_line "leaves the repository" '[a](../../../outside.md)' 1 'leaves the repository'
case_line "line numbers" "$(printf 'one\n\n[a](gone.md)')" 1 'docs/sub/case.md:3: broken link'
case_line "two problems" '[a](x.md) [b](y.md)' 1 'lint-doc-links: 2 problem(s)'
expect "usage" 2 "usage:" sh "$tools/doc-links.sh" extra

finish
