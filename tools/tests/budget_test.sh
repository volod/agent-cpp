#!/bin/sh
# Tests of the build budget in cmake/AgentBuildBudget.cmake against fixture /proc and cgroup
# files; needs cmake.
set -eu
# shellcheck source=lib.sh
. "$(dirname -- "$0")/lib.sh"

# machine <name> <MemTotal kB> <MemAvailable kB> <Cpus_allowed_list> [<cgroup path>]
machine() {
  dir=$scratch/$1
  mkdir -p "$dir/proc/self" "$dir/sys/fs/cgroup"
  printf 'MemTotal:       %s kB\nMemFree:        1 kB\nMemAvailable:   %s kB\n' "$2" "$3" \
    >"$dir/proc/meminfo"
  printf 'Name:\tcmake\nCpus_allowed_list:\t%s\n' "$4" >"$dir/proc/self/status"
  printf '0::%s\n' "${5:-/}" >"$dir/proc/self/cgroup"
}

budget() {
  AGENT_BUDGET_ROOT=$dir cmake -P "$repo/cmake/AgentBuildBudget.cmake"
}

machine host 16777216 12582912 0-7
expect "host memory and cores" 0 \
  "compile=4 link=2 heavy=1 (cpus=8, memory total=16.0G available=12.0G usable=8.8G)" budget
expect "AGENT_MAX_JOBS caps every pool" 0 "compile=1 link=1 heavy=1" \
  env AGENT_MAX_JOBS=1 AGENT_BUDGET_ROOT="$dir" cmake -P "$repo/cmake/AgentBuildBudget.cmake"
expect "AGENT_MAX_JOBS never raises" 0 "compile=4 link=2 heavy=1" \
  env AGENT_MAX_JOBS=64 AGENT_BUDGET_ROOT="$dir" cmake -P "$repo/cmake/AgentBuildBudget.cmake"

# 7844 MiB usable: 3.83 compile jobs and 1.92 link jobs round up, 0.64 heavy jobs do not.
machine round 10485760 10129408 0-15
expect "remainder of 80 percent rounds up" 0 \
  "compile=4 link=2 heavy=1 (cpus=16, memory total=10.0G available=9.6G usable=7.6G)" budget

machine affinity 67108864 67108864 0-3,8,10-11
expect "affinity ranges" 0 "compile=5 link=2 heavy=2 (cpus=7," budget

# The memory limit sits on an ancestor of the process's cgroup, the CPU quota on the cgroup.
machine limited 16777216 12582912 0-7 /a/b
mkdir -p "$dir/sys/fs/cgroup/a/b"
echo 4294967296 >"$dir/sys/fs/cgroup/a/memory.max"
echo 1073741824 >"$dir/sys/fs/cgroup/a/memory.current"
echo max >"$dir/sys/fs/cgroup/a/b/memory.max"
echo "200000 100000" >"$dir/sys/fs/cgroup/a/b/cpu.max"
expect "cgroup limits" 0 \
  "compile=1 link=1 heavy=1 (cpus=2, memory total=4.0G available=3.0G usable=2.2G)" budget

dir=$scratch/empty
mkdir -p "$dir"
expect "unreadable /proc falls back to 8 GiB" 0 "memory total=8.0G available=4.0G" budget

finish
