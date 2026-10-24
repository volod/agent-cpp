#!/bin/sh
# Checks that relative Markdown links and heading anchors resolve inside the repository.
#
#   tools/doc-links.sh [-C <root>]
#
# Scans tracked and new, not ignored, *.md and *.mdc files, skipping vendored trees and hidden
# directories other than .github and .cursor. Links inside fenced code and inline code are not
# links. Anchors follow GitHub: lowercase, spaces to hyphens, other punctuation dropped, -1, -2
# for repeated headings. Exit codes: 0 every link resolves, 1 broken links, 2 usage error.
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if [ "${1:-}" = -C ] && [ $# -eq 2 ]; then
  root=$2
elif [ $# -ne 0 ]; then
  echo "usage: tools/doc-links.sh [-C <root>]" >&2
  exit 2
fi

list=$(mktemp)
trap 'rm -f "$list"' EXIT
git -C "$root" ls-files --cached --others --exclude-standard | while IFS= read -r path; do
  if [ -e "$root/$path" ]; then
    printf '%s\n' "$path"
  fi
done >"$list"

awk -v root="$root" '
function scanned(p,   parts, n, i) {
  if (p !~ /\.(md|mdc)$/ || p ~ /(^|\/)(build|dist|vendor|node_modules|testdata|third_party)\//)
    return 0
  n = split(p, parts, "/")
  for (i = 1; i < n; i++)
    if (parts[i] ~ /^\./ && parts[i] != ".github" && parts[i] != ".cursor") return 0
  return 1
}
function slug(text,   s) {
  s = tolower(text)
  gsub(/[^a-z0-9 _-]/, "", s)
  gsub(/ /, "-", s)
  return s
}
# Resolves . and .. in a /-separated path; "\001" when it climbs above the root.
function normalize(p,   parts, n, i, depth, out, k) {
  n = split(p, parts, "/")
  depth = 0
  for (i = 1; i <= n; i++) {
    if (parts[i] == "" || parts[i] == ".") continue
    if (parts[i] == "..") {
      if (depth == 0) return "\001"
      depth--
    } else {
      stack[++depth] = parts[i]
    }
  }
  out = ""
  for (k = 1; k <= depth; k++) out = out (k > 1 ? "/" : "") stack[k]
  return out
}
function problem(msg) {
  print msg > "/dev/stderr"
  problems++
}
function check(src, number, target,   hash, file, anchor, dir, resolved) {
  sub(/^</, "", target)
  sub(/>$/, "", target)
  if (target == "" || target ~ /^[a-z]+:/) return  # http:, https:, mailto:
  hash = index(target, "#")
  file = hash ? substr(target, 1, hash - 1) : target
  anchor = hash ? substr(target, hash + 1) : ""
  if (file == "") {
    resolved = src
  } else {
    dir = src
    if (!sub(/\/[^\/]*$/, "", dir)) dir = ""
    resolved = normalize((dir == "" ? "" : dir "/") file)
    if (resolved == "\001") {
      problem(src ":" number ": link \"" target "\" leaves the repository")
      return
    }
    if (resolved != "" && !(resolved in have)) {
      problem(src ":" number ": broken link \"" target "\"")
      return
    }
  }
  if (anchor != "" && (resolved in markdown) && !((resolved, anchor) in anchors))
    problem(src ":" number ": missing anchor \"" target "\"")
}
{
  have[$0] = 1
  dir = $0
  while (sub(/\/[^\/]*$/, "", dir)) have[dir] = 1
  if (scanned($0)) {
    files[++count] = $0
    markdown[$0] = 1
  }
}
END {
  for (f = 1; f <= count; f++) {
    path = files[f]
    fence = 0
    n = 0
    split("", seen)
    while ((getline line < (root "/" path)) > 0) {
      n++
      if (line ~ /^[ \t]*(```|~~~)/) {
        fence = !fence
        line = ""
      } else if (fence) {
        line = ""
      }
      text[f, n] = line
      if (match(line, /^#+[ \t]/) && RLENGTH <= 7) {
        title = substr(line, RLENGTH + 1)
        sub(/[ \t#]+$/, "", title)
        sub(/^[ \t]+/, "", title)
        if (title == "") continue
        base = slug(title)
        anchors[path, seen[base] ? base "-" seen[base] : base] = 1
        seen[base]++
      }
    }
    close(root "/" path)
    lines[f] = n
  }
  for (f = 1; f <= count; f++) {
    for (k = 1; k <= lines[f]; k++) {
      s = text[f, k]
      gsub(/`[^`]*`/, "", s)
      while (match(s, /\]\([^)[:space:]]*\)/)) {
        check(files[f], k, substr(s, RSTART + 2, RLENGTH - 3))
        s = substr(s, RSTART + RLENGTH)
      }
    }
  }
  if (problems) {
    print "lint-doc-links: " problems " problem(s)" > "/dev/stderr"
    exit 1
  }
  print "lint-doc-links: ok"
}' "$list"
