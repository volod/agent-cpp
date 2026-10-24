# Fails configuration early when the C++ compiler cannot build this C++20 code base.
#
# The floor is the Ubuntu 24.04 baseline: GCC 13 (first release with <format>) and Clang 18.
# Vendor SDK toolchains older than this (for example the Luckfox Pico SDK's GCC 8) are not
# supported; use the distribution cross compilers instead. See docs/guide/cross-compilation.md.
include_guard(GLOBAL)

set(_agent_min_gcc 13)
set(_agent_min_clang 18)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  set(_agent_min ${_agent_min_gcc})
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(_agent_min ${_agent_min_clang})
else()
  message(FATAL_ERROR
    "Unsupported C++ compiler ${CMAKE_CXX_COMPILER_ID}; use GCC >= ${_agent_min_gcc} "
    "or Clang >= ${_agent_min_clang}.")
endif()

if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${_agent_min})
  message(FATAL_ERROR
    "${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION} is too old for this project; "
    "need >= ${_agent_min}. See docs/guide/cross-compilation.md#toolchains.")
endif()

if(AGENT_STATIC AND AGENT_SANITIZERS)
  message(FATAL_ERROR "AGENT_STATIC and AGENT_SANITIZERS cannot be combined.")
endif()
