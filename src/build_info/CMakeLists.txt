agent_cc_library(
  NAME build_info
  SRCS build_info.cc
  HDRS build_info.h)

set(_agent_build_identity
  AGENT_PROJECT_NAME="${PROJECT_NAME}"
  AGENT_PROJECT_VERSION="${PROJECT_VERSION}"
  AGENT_PROJECT_URL="${PROJECT_HOMEPAGE_URL}"
  AGENT_TARGET_NAME="${AGENT_TARGET_NAME}")
target_compile_definitions(agent_build_info PRIVATE ${_agent_build_identity})

agent_cc_test(
  NAME build_info_test
  SRCS build_info_test.cc
  DEPS agent::build_info)
if(TARGET build_info_test)
  target_compile_definitions(build_info_test PRIVATE ${_agent_build_identity})
endif()
