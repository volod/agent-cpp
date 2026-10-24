#include "build_info/build_info.h"

#include <string>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace agent {
namespace {

using ::testing::MatchesRegex;

TEST(BuildInfoTest, ComesFromTheBuild) {
  const BuildInfo& info = GetBuildInfo();
  EXPECT_EQ(info.name, AGENT_PROJECT_NAME);
  EXPECT_EQ(info.version, AGENT_PROJECT_VERSION);
  EXPECT_EQ(info.repository, AGENT_PROJECT_URL);
  EXPECT_EQ(info.target, AGENT_TARGET_NAME);
  EXPECT_THAT(std::string(info.version),
              MatchesRegex("[0-9]+\\.[0-9]+\\.[0-9]+"));
}

TEST(BuildInfoTest, KnowsThePlatform) {
  const BuildInfo& info = GetBuildInfo();
  EXPECT_EQ(info.os, "linux");
  EXPECT_NE(info.arch, "unknown");
  EXPECT_THAT(std::string(info.compiler),
              MatchesRegex("(gcc|clang) [0-9]+\\.[0-9]+\\.[0-9]+"));
}

TEST(VersionLineTest, FormatsEveryField) {
  const BuildInfo info = {
      .name = "tool",
      .version = "1.2.3",
      .repository = "https://example.com/tool",
      .os = "linux",
      .arch = "armv7",
      .target = "luckfox-pico",
      .compiler = "gcc 15.2.0",
  };
  EXPECT_EQ(VersionLine(info),
            "tool 1.2.3 (https://example.com/tool, linux/armv7, luckfox-pico, "
            "gcc 15.2.0)");
}

}  // namespace
}  // namespace agent
