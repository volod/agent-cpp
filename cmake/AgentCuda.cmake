# Optional CUDA support (AGENT_ENABLE_CUDA=ON, host presets only).
#
# - Architectures are explicit: set CMAKE_CUDA_ARCHITECTURES (preset or AGENT_CUDA_ARCHITECTURES
#   in the environment), for example "89" or "86;89". `native` is accepted for local presets;
#   `all` and `all-major` are rejected because they multiply compile time and memory.
# - When the distribution nvcc does not support the default g++, point CUDAHOSTCXX at a
#   supported one (for example g++-13) before configuring.
# - CUDA targets compile in the `heavy` job pool; see AgentBuildBudget.cmake.
include_guard(GLOBAL)

if(CMAKE_CROSSCOMPILING)
  message(FATAL_ERROR "AGENT_ENABLE_CUDA is host-only; cross targets have no CUDA toolchain.")
endif()

if(NOT CMAKE_CUDA_ARCHITECTURES AND DEFINED ENV{AGENT_CUDA_ARCHITECTURES})
  set(CMAKE_CUDA_ARCHITECTURES "$ENV{AGENT_CUDA_ARCHITECTURES}")
endif()
if(NOT CMAKE_CUDA_ARCHITECTURES)
  message(FATAL_ERROR
    "AGENT_ENABLE_CUDA needs CMAKE_CUDA_ARCHITECTURES (for example 89, or native locally).")
endif()
if(CMAKE_CUDA_ARCHITECTURES MATCHES "^all")
  message(FATAL_ERROR "CMAKE_CUDA_ARCHITECTURES=${CMAKE_CUDA_ARCHITECTURES} is not allowed.")
endif()

enable_language(CUDA)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)
find_package(CUDAToolkit REQUIRED)
message(STATUS "agent: CUDA ${CMAKE_CUDA_COMPILER_VERSION}, architectures ${CMAKE_CUDA_ARCHITECTURES}")
