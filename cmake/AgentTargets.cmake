# Target helpers in the spirit of Bazel's cc_library / cc_binary / cc_test. Every first-party
# target is declared through them so warnings, hardening, sanitizers, static linking and job
# pools apply uniformly. Include paths are rooted at src/: `#include "base/status.h"`.
#
#   agent_cc_library(NAME <name> [SRCS ...] [HDRS ...] [DEPS ...] [HEAVY] [CUDA])
#       Static library `agent_<name>` with alias `agent::<name>`; header-only when SRCS is empty.
#   agent_cc_binary(NAME <name> SRCS ... [DEPS ...] [HEAVY] [CUDA])
#       Installed executable `<name>`.
#   agent_cc_test(NAME <name> SRCS ... [DEPS ...] [HEAVY] [CUDA] [LABELS ...])
#       GoogleTest executable `<name>` registered with CTest (label `unit` plus LABELS).
#
# HEAVY puts the target's compiles in the `heavy` job pool (see AgentBuildBudget.cmake). CUDA
# implies HEAVY and requires AGENT_ENABLE_CUDA; declare such targets inside
# `if(AGENT_ENABLE_CUDA)`.
include_guard(GLOBAL)

set(_agent_flags HEAVY CUDA)
set(_agent_lists SRCS HDRS DEPS LABELS)

function(_agent_heavy_pool target heavy cuda)
  if(cuda AND NOT AGENT_ENABLE_CUDA)
    message(FATAL_ERROR "${target} is marked CUDA but AGENT_ENABLE_CUDA is OFF.")
  endif()
  if((heavy OR cuda) AND AGENT_HEAVY_POOL)
    set_property(TARGET ${target} PROPERTY JOB_POOL_COMPILE ${AGENT_HEAVY_POOL})
  endif()
endfunction()

function(agent_cc_library)
  cmake_parse_arguments(PARSE_ARGV 0 arg "${_agent_flags}" "NAME" "${_agent_lists}")
  set(target agent_${arg_NAME})
  if(arg_SRCS)
    add_library(${target} STATIC)
    target_sources(${target} PRIVATE ${arg_SRCS} ${arg_HDRS})
    target_include_directories(${target} PUBLIC "${PROJECT_SOURCE_DIR}/src")
    target_link_libraries(${target} PUBLIC ${arg_DEPS})
    agent_apply_options(${target} PRIVATE)
    _agent_heavy_pool(${target} "${arg_HEAVY}" "${arg_CUDA}")
  else()
    add_library(${target} INTERFACE)
    target_sources(${target} INTERFACE ${arg_HDRS})
    target_include_directories(${target} INTERFACE "${PROJECT_SOURCE_DIR}/src")
    target_link_libraries(${target} INTERFACE ${arg_DEPS})
  endif()
  add_library(agent::${arg_NAME} ALIAS ${target})
endfunction()

function(agent_cc_binary)
  cmake_parse_arguments(PARSE_ARGV 0 arg "${_agent_flags}" "NAME" "${_agent_lists}")
  add_executable(${arg_NAME} ${arg_SRCS})
  target_link_libraries(${arg_NAME} PRIVATE ${arg_DEPS})
  agent_apply_options(${arg_NAME} PRIVATE)
  agent_apply_executable_options(${arg_NAME})
  _agent_heavy_pool(${arg_NAME} "${arg_HEAVY}" "${arg_CUDA}")
  include(GNUInstallDirs)
  install(TARGETS ${arg_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
endfunction()

function(agent_cc_test)
  if(NOT AGENT_BUILD_TESTS)
    return()
  endif()
  cmake_parse_arguments(PARSE_ARGV 0 arg "${_agent_flags}" "NAME" "${_agent_lists}")
  add_executable(${arg_NAME} ${arg_SRCS})
  target_link_libraries(${arg_NAME} PRIVATE ${arg_DEPS} GTest::gmock GTest::gtest_main)
  agent_apply_options(${arg_NAME} PRIVATE)
  agent_apply_executable_options(${arg_NAME})
  _agent_heavy_pool(${arg_NAME} "${arg_HEAVY}" "${arg_CUDA}")
  if(AGENT_CAN_RUN_TESTS)
    # PRE_TEST discovery lists the tests when CTest runs, so building never needs the emulator.
    gtest_discover_tests(${arg_NAME}
      DISCOVERY_MODE PRE_TEST
      PROPERTIES LABELS "unit;${arg_LABELS}")
  endif()
endfunction()
