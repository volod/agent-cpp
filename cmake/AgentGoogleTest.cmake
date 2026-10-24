# GoogleTest, the only third-party dependency (test-only). It is built from a pinned, hashed
# release archive for every target, so cross builds never pick up a host-architecture system
# package. Offline: pass -DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=<unpacked googletest-1.17.0>.
include_guard(GLOBAL)

include(FetchContent)
include(GoogleTest)

set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
set(BUILD_GMOCK ON CACHE BOOL "" FORCE)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/releases/download/v1.17.0/googletest-1.17.0.tar.gz
  URL_HASH SHA256=65fab701d9829d38cb77c14acdc431d2108bfdbf8979e40eb8ae567edf10b27c
  DOWNLOAD_EXTRACT_TIMESTAMP ON
  SYSTEM
  EXCLUDE_FROM_ALL)
FetchContent_MakeAvailable(googletest)

if(AGENT_SANITIZERS)
  list(JOIN AGENT_SANITIZERS "," _agent_sanitize)
  foreach(_agent_gtest_target gtest gtest_main gmock gmock_main)
    target_compile_options(${_agent_gtest_target} PRIVATE "-fsanitize=${_agent_sanitize}")
  endforeach()
endif()

# Tests run on the host, or under CMAKE_CROSSCOMPILING_EMULATOR (qemu-user) when cross building.
# Without an emulator cross tests are still built, to be copied to the device, but not registered.
if(NOT CMAKE_CROSSCOMPILING OR CMAKE_CROSSCOMPILING_EMULATOR)
  set(AGENT_CAN_RUN_TESTS ON)
else()
  set(AGENT_CAN_RUN_TESTS OFF)
  message(STATUS "agent: no CMAKE_CROSSCOMPILING_EMULATOR; tests are built but not registered")
endif()
