# Shared logic for GNU/Linux cross toolchains. Board files set, before including this file:
#
#   AGENT_CROSS_TRIPLE      compiler prefix, e.g. aarch64-linux-gnu
#   AGENT_CROSS_PROCESSOR   CMAKE_SYSTEM_PROCESSOR, e.g. aarch64
#   AGENT_CROSS_QEMU        qemu-user binary used to run tests, e.g. qemu-aarch64
#   AGENT_CROSS_CPU_FLAGS   CPU tuning flags for the board
#
# Overrides, from the environment or -D:
#   AGENT_CROSS_PREFIX      full compiler prefix, e.g. /opt/sdk/bin/aarch64-linux-gnu- (a vendor
#                          toolchain; it must still meet the GCC 13 / Clang 18 floor)
#   AGENT_CROSS_SYSROOT     target sysroot for headers and libraries (default: the compiler's)
#   AGENT_CROSS_GCC_VERSION versioned distribution compiler, e.g. 14 for aarch64-linux-gnu-g++-14
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR ${AGENT_CROSS_PROCESSOR})

foreach(_agent_var AGENT_CROSS_PREFIX AGENT_CROSS_SYSROOT AGENT_CROSS_GCC_VERSION)
  if(NOT DEFINED ${_agent_var} AND DEFINED ENV{${_agent_var}})
    set(${_agent_var} "$ENV{${_agent_var}}")
  endif()
endforeach()
# try_compile projects re-read this file; forward the overrides to them.
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
  AGENT_CROSS_PREFIX AGENT_CROSS_SYSROOT AGENT_CROSS_GCC_VERSION)

if(NOT AGENT_CROSS_PREFIX)
  set(AGENT_CROSS_PREFIX "${AGENT_CROSS_TRIPLE}-")
endif()
set(_agent_suffix "")
if(AGENT_CROSS_GCC_VERSION)
  set(_agent_suffix "-${AGENT_CROSS_GCC_VERSION}")
endif()
set(CMAKE_C_COMPILER "${AGENT_CROSS_PREFIX}gcc${_agent_suffix}")
set(CMAKE_CXX_COMPILER "${AGENT_CROSS_PREFIX}g++${_agent_suffix}")

set(CMAKE_C_FLAGS_INIT "${AGENT_CROSS_CPU_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${AGENT_CROSS_CPU_FLAGS}")

if(AGENT_CROSS_SYSROOT)
  set(CMAKE_SYSROOT "${AGENT_CROSS_SYSROOT}")
  set(_agent_qemu_root "${AGENT_CROSS_SYSROOT}")
else()
  # Ubuntu's cross packages install the target libraries under /usr/<triple>.
  set(_agent_qemu_root "/usr/${AGENT_CROSS_TRIPLE}")
endif()
set(CMAKE_FIND_ROOT_PATH "${_agent_qemu_root}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Tests run under qemu-user when it is installed (package qemu-user on Ubuntu 24.04 and 26.04).
# -L lets dynamically linked binaries find the target loader; static binaries ignore it.
find_program(AGENT_QEMU_PROGRAM ${AGENT_CROSS_QEMU})
if(AGENT_QEMU_PROGRAM)
  set(CMAKE_CROSSCOMPILING_EMULATOR "${AGENT_QEMU_PROGRAM};-L;${_agent_qemu_root}")
endif()
