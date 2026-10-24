#include "base/status.h"

#include <cstdio>
#include <cstdlib>
#include <string>
#include <string_view>

namespace agent {

std::string_view StatusCodeToString(StatusCode code) {
  switch (code) {
    case StatusCode::kOk:
      return "OK";
    case StatusCode::kCancelled:
      return "CANCELLED";
    case StatusCode::kUnknown:
      return "UNKNOWN";
    case StatusCode::kInvalidArgument:
      return "INVALID_ARGUMENT";
    case StatusCode::kDeadlineExceeded:
      return "DEADLINE_EXCEEDED";
    case StatusCode::kNotFound:
      return "NOT_FOUND";
    case StatusCode::kAlreadyExists:
      return "ALREADY_EXISTS";
    case StatusCode::kPermissionDenied:
      return "PERMISSION_DENIED";
    case StatusCode::kResourceExhausted:
      return "RESOURCE_EXHAUSTED";
    case StatusCode::kFailedPrecondition:
      return "FAILED_PRECONDITION";
    case StatusCode::kAborted:
      return "ABORTED";
    case StatusCode::kOutOfRange:
      return "OUT_OF_RANGE";
    case StatusCode::kUnimplemented:
      return "UNIMPLEMENTED";
    case StatusCode::kInternal:
      return "INTERNAL";
    case StatusCode::kUnavailable:
      return "UNAVAILABLE";
    case StatusCode::kDataLoss:
      return "DATA_LOSS";
  }
  return "UNKNOWN";
}

Status::Status(StatusCode code, std::string_view message)
    : code_(code), message_(code == StatusCode::kOk ? "" : message) {}

std::string Status::ToString() const {
  if (ok()) return "OK";
  std::string text(StatusCodeToString(code_));
  text += ": ";
  text += message_;
  return text;
}

Status InvalidArgumentError(std::string_view message) {
  return Status(StatusCode::kInvalidArgument, message);
}
Status NotFoundError(std::string_view message) {
  return Status(StatusCode::kNotFound, message);
}
Status FailedPreconditionError(std::string_view message) {
  return Status(StatusCode::kFailedPrecondition, message);
}
Status OutOfRangeError(std::string_view message) {
  return Status(StatusCode::kOutOfRange, message);
}
Status UnavailableError(std::string_view message) {
  return Status(StatusCode::kUnavailable, message);
}
Status InternalError(std::string_view message) {
  return Status(StatusCode::kInternal, message);
}
Status DataLossError(std::string_view message) {
  return Status(StatusCode::kDataLoss, message);
}

namespace internal_status {

void DieOnBadAccess(const Status& status) {
  static_cast<void>(std::fprintf(stderr, "StatusOr::value() on error: %s\n",
                                 status.ToString().c_str()));
  std::abort();
}

}  // namespace internal_status
}  // namespace agent
