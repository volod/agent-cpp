# agent-cpp: C++20 project skeleton for people and coding agents.
#
# Configure through a preset (`cmake --preset host-debug`) or `make`; see
# docs/guide/development.md. The project version below is the single version source.
cmake_minimum_required(VERSION 3.28)

project(
  agent-cpp
  VERSION 0.1.0
  DESCRIPTION "Agentic C++20 project skeleton"
  HOMEPAGE_URL "https://github.com/volod/agent-cpp"
  LANGUAGES CXX)

if(NOT PROJECT_IS_TOP_LEVEL)
  message(FATAL_ERROR "agent-cpp is an application; build it as the top-level project.")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# Headers, not C++20 modules: module scanning slows every build and confuses clang-tidy.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

option(AGENT_BUILD_TESTS "Build unit and black-box tests" ON)
option(AGENT_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)
option(AGENT_STATIC "Link executables fully statically (cross targets)" OFF)
option(AGENT_ENABLE_CUDA "Enable the CUDA language for targets marked CUDA" OFF)
option(AGENT_CCACHE "Use ccache as the compiler launcher when it is installed" ON)
set(AGENT_SANITIZERS "" CACHE STRING "Sanitizers for every target, e.g. address;undefined")
set(AGENT_TARGET_NAME "host" CACHE STRING "Deployment target name reported by `version`")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(AgentToolchainChecks)
include(AgentBuildBudget)
include(AgentCompilerOptions)
include(AgentTargets)
if(AGENT_ENABLE_CUDA)
  include(AgentCuda)
endif()

if(AGENT_BUILD_TESTS)
  enable_testing()
  include(AgentGoogleTest)
endif()

add_subdirectory(src)
if(AGENT_BUILD_TESTS)
  add_subdirectory(tests)
endif()

include(GNUInstallDirs)
install(FILES README.md LICENSE DESTINATION "${CMAKE_INSTALL_DOCDIR}")
