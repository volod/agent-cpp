#include "base/status.h"

#include <memory>
#include <string>
#include <utility>

#include "gtest/gtest.h"

namespace agent {
namespace {

TEST(StatusTest, DefaultIsOk) {
  const Status status;
  EXPECT_TRUE(status.ok());
  EXPECT_EQ(status.code(), StatusCode::kOk);
  EXPECT_EQ(status.ToString(), "OK");
  EXPECT_EQ(status, OkStatus());
}

TEST(StatusTest, OkDropsMessage) {
  const Status status(StatusCode::kOk, "ignored");
  EXPECT_TRUE(status.message().empty());
}

TEST(StatusTest, FactoriesSetCodeAndMessage) {
  struct Case {
    Status status;
    StatusCode code;
    std::string text;
  };
  const Case cases[] = {
      {InvalidArgumentError("bad flag"), StatusCode::kInvalidArgument,
       "INVALID_ARGUMENT: bad flag"},
      {NotFoundError("no file"), StatusCode::kNotFound, "NOT_FOUND: no file"},
      {FailedPreconditionError("not ready"), StatusCode::kFailedPrecondition,
       "FAILED_PRECONDITION: not ready"},
      {OutOfRangeError("index 9"), StatusCode::kOutOfRange,
       "OUT_OF_RANGE: index 9"},
      {UnavailableError("busy"), StatusCode::kUnavailable, "UNAVAILABLE: busy"},
      {InternalError("bug"), StatusCode::kInternal, "INTERNAL: bug"},
      {DataLossError("torn write"), StatusCode::kDataLoss,
       "DATA_LOSS: torn write"},
  };
  for (const Case& c : cases) {
    EXPECT_FALSE(c.status.ok()) << c.text;
    EXPECT_EQ(c.status.code(), c.code) << c.text;
    EXPECT_EQ(c.status.ToString(), c.text);
  }
}

TEST(StatusTest, EveryCodeHasAName) {
  for (int value = 0; value <= static_cast<int>(StatusCode::kDataLoss);
       ++value) {
    const auto code = static_cast<StatusCode>(value);
    if (code == StatusCode::kUnknown) continue;
    EXPECT_NE(StatusCodeToString(code), "UNKNOWN") << value;
  }
}

TEST(StatusOrTest, HoldsValue) {
  StatusOr<std::string> result = std::string("value");
  ASSERT_TRUE(result.ok());
  EXPECT_TRUE(result.status().ok());
  EXPECT_EQ(*result, "value");
  EXPECT_EQ(result->size(), 5u);
  EXPECT_EQ(std::move(result).value(), "value");
}

TEST(StatusOrTest, HoldsError) {
  const StatusOr<int> result = NotFoundError("missing");
  EXPECT_FALSE(result.ok());
  EXPECT_EQ(result.status(), NotFoundError("missing"));
}

TEST(StatusOrTest, OkStatusBecomesInternalError) {
  const StatusOr<int> result = OkStatus();
  EXPECT_EQ(result.status().code(), StatusCode::kInternal);
}

TEST(StatusOrTest, HoldsMoveOnlyValue) {
  StatusOr<std::unique_ptr<int>> result = std::make_unique<int>(7);
  ASSERT_TRUE(result.ok());
  const std::unique_ptr<int> value = std::move(result).value();
  EXPECT_EQ(*value, 7);
}

TEST(StatusOrDeathTest, ValueOnErrorAborts) {
  const StatusOr<int> result = InternalError("boom");
  EXPECT_DEATH(
      { (void)result.value(); },
      "StatusOr::value\\(\\) on error: INTERNAL: boom");
}

Status FailIf(bool fail) {
  return fail ? InvalidArgumentError("failed") : OkStatus();
}

StatusOr<int> Chain(bool fail) {
  AGENT_RETURN_IF_ERROR(FailIf(fail));
  return 42;
}

TEST(ReturnIfErrorTest, PropagatesErrorsAndContinuesOnOk) {
  EXPECT_EQ(*Chain(false), 42);
  EXPECT_EQ(Chain(true).status(), InvalidArgumentError("failed"));
}

}  // namespace
}  // namespace agent
