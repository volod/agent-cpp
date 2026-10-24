agent_cc_library(
  NAME base
  SRCS status.cc
  HDRS status.h)

agent_cc_test(
  NAME base_status_test
  SRCS status_test.cc
  DEPS agent::base)
