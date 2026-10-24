agent_cc_library(
  NAME cli
  SRCS cli.cc
  HDRS cli.h
  DEPS agent::base agent::build_info)

agent_cc_test(
  NAME cli_test
  SRCS cli_test.cc
  DEPS agent::cli)
