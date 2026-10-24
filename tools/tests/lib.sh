# Helpers sourced by tools/tests/*_test.sh: a scratch directory removed on exit, `expect` for
# one table row, and `finish` for the summary line and exit code.
# shellcheck shell=sh

tools=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
# shellcheck disable=SC2034 # read by the tests that source this file
repo=$(dirname -- "$tools")
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
tests=0
failures=0

# expect <name> <exit code> <text the combined output must contain> <command> [args...]
expect() {
  name=$1
  want_code=$2
  want_text=$3
  shift 3
  tests=$((tests + 1))
  code=0
  out=$("$@" 2>&1) || code=$?
  if [ "$code" != "$want_code" ]; then
    failures=$((failures + 1))
    printf 'FAIL %s: exit %s, want %s\n%s\n' "$name" "$code" "$want_code" "$out" >&2
    return 0
  fi
  case $out in
    *"$want_text"*) ;;
    *)
      failures=$((failures + 1))
      printf 'FAIL %s: output lacks "%s"\n%s\n' "$name" "$want_text" "$out" >&2
      ;;
  esac
}

# assert <name> <command> [args...]: the command must succeed.
assert() {
  name=$1
  shift
  tests=$((tests + 1))
  if ! "$@" >/dev/null 2>&1; then
    failures=$((failures + 1))
    printf 'FAIL %s\n' "$name" >&2
  fi
}

finish() {
  if [ "$failures" -ne 0 ]; then
    printf '%s: %s of %s tests failed\n' "${0##*/}" "$failures" "$tests" >&2
    exit 1
  fi
  printf '%s: %s tests passed\n' "${0##*/}" "$tests"
}
