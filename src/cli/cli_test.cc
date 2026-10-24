#include "cli/cli.h"

#include <sstream>
#include <string>
#include <string_view>
#include <vector>

#include "build_info/build_info.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace agent::cli {
namespace {

using ::testing::HasSubstr;
using ::testing::IsEmpty;
using ::testing::StartsWith;

struct Result {
  ExitCode code;
  std::string out;
  std::string err;
};

Result RunWith(std::vector<std::string_view> args) {
  std::ostringstream out;
  std::ostringstream err;
  const ExitCode code = Run(args, out, err);
  return {code, out.str(), err.str()};
}

TEST(CliTest, VersionPrintsOneLineToStdout) {
  for (std::string_view command : {"version", "--version"}) {
    const Result result = RunWith({command});
    EXPECT_EQ(result.code, ExitCode::kSuccess) << command;
    EXPECT_EQ(result.out, VersionLine(GetBuildInfo()) + "\n") << command;
    EXPECT_THAT(result.err, IsEmpty()) << command;
  }
}

TEST(CliTest, HelpPrintsUsageToStdout) {
  for (std::string_view command : {"help", "-h", "--help"}) {
    const Result result = RunWith({command});
    EXPECT_EQ(result.code, ExitCode::kSuccess) << command;
    EXPECT_THAT(result.out, StartsWith("Usage: ")) << command;
    EXPECT_THAT(result.out, HasSubstr("version")) << command;
    EXPECT_THAT(result.err, IsEmpty()) << command;
  }
}

TEST(CliTest, UsageErrorsGoToStderrWithCodeTwo) {
  struct Case {
    std::vector<std::string_view> args;
    std::string_view message;
  };
  const Case cases[] = {
      {{}, "missing command"},
      {{"bogus"}, "unknown command \"bogus\""},
      {{"version", "extra"}, "version takes no arguments"},
      {{"help", "extra"}, "help takes no arguments"},
  };
  for (const Case& c : cases) {
    const Result result = RunWith(c.args);
    EXPECT_EQ(result.code, ExitCode::kUsage) << c.message;
    EXPECT_THAT(result.out, IsEmpty()) << c.message;
    EXPECT_THAT(result.err, HasSubstr(c.message));
    EXPECT_THAT(result.err, HasSubstr("Usage: ")) << c.message;
  }
}

TEST(CliTest, FailedWriteIsAFailure) {
  std::ostringstream out;
  out.setstate(std::ios::badbit);
  std::ostringstream err;
  const std::vector<std::string_view> args = {"version"};
  EXPECT_EQ(cli::Run(args, out, err), ExitCode::kFailure);
  EXPECT_THAT(err.str(), HasSubstr("cannot write to standard output"));
}

}  // namespace
}  // namespace agent::cli
