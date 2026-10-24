# One directory per module, each with its own CMakeLists.txt declaring agent_cc_* targets. Keep
# this order consistent with docs/design/architecture.md#dependency-direction.
add_subdirectory(base)
add_subdirectory(build_info)
add_subdirectory(cli)

agent_cc_binary(
  NAME agent-cpp
  SRCS main.cc
  DEPS agent::cli)
