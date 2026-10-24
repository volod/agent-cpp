# Black-box tests: run the installed-to-be binary through its command-line contract. Unit tests
# live beside their sources (src/**/*_test.cc).
if(NOT AGENT_CAN_RUN_TESTS)
  return()
endif()

list(JOIN CMAKE_CROSSCOMPILING_EMULATOR "|" _agent_emulator)

# agent_cli_test(<name> <exit-code> <stdout-regex> <stderr-regex> [args...])
function(agent_cli_test name code stdout stderr)
  list(JOIN ARGN "|" _args)
  add_test(
    NAME cli.${name}
    COMMAND "${CMAKE_COMMAND}"
      "-DCLI=$<TARGET_FILE:agent-cpp>"
      "-DEMULATOR=${_agent_emulator}"
      "-DARGS=${_args}"
      "-DEXPECT_CODE=${code}"
      "-DEXPECT_STDOUT=${stdout}"
      "-DEXPECT_STDERR=${stderr}"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/run_cli.cmake")
  set_tests_properties(cli.${name} PROPERTIES LABELS blackbox)
endfunction()

set(_version "^agent-cpp ${PROJECT_VERSION} \\(${PROJECT_HOMEPAGE_URL}, linux/[a-z0-9_]+, ")
string(APPEND _version "${AGENT_TARGET_NAME}, (gcc|clang) [0-9.]+\\)\n$")

agent_cli_test(version 0 "${_version}" "" version)
agent_cli_test(version_flag 0 "${_version}" "" --version)
agent_cli_test(help 0 "^Usage: agent-cpp <command>" "" help)
agent_cli_test(help_short 0 "^Usage: agent-cpp <command>" "" -h)
agent_cli_test(help_long 0 "^Usage: agent-cpp <command>" "" --help)
agent_cli_test(missing_command 2 "" "^agent-cpp: missing command\n\nUsage: ")
agent_cli_test(unknown_command 2 "" "^agent-cpp: unknown command \"bogus\"" bogus)
agent_cli_test(extra_argument 2 "" "version takes no arguments" version extra)
