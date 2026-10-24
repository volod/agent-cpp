// Error values for fallible operations. The project does not use exceptions
// (Google C++ style); a function that can fail on expected conditions returns
// `Status` or `StatusOr<T>`.
//
// The API is a small subset of absl::Status / absl::StatusOr with the same
// names, so code can move to Abseil without rewriting call sites if a
// capability ever adds that dependency.

#ifndef AGENT_BASE_STATUS_H_
#define AGENT_BASE_STATUS_H_

#include <optional>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>

namespace agent {

// Canonical error codes; values match absl::StatusCode and google.rpc.Code.
enum class StatusCode : int {
  kOk = 0,
  kCancelled = 1,
  kUnknown = 2,
  kInvalidArgument = 3,
  kDeadlineExceeded = 4,
  kNotFound = 5,
  kAlreadyExists = 6,
  kPermissionDenied = 7,
  kResourceExhausted = 8,
  kFailedPrecondition = 9,
  kAborted = 10,
  kOutOfRange = 11,
  kUnimplemented = 12,
  kInternal = 13,
  kUnavailable = 14,
  kDataLoss = 15,
};

// Returns the upper snake case name of `code`, for example "INVALID_ARGUMENT".
std::string_view StatusCodeToString(StatusCode code);

// The outcome of an operation: OK, or an error code with a human-readable
// message. Callers branch on `code()`, never on the message text.
class [[nodiscard]] Status {
 public:
  // Constructs an OK status.
  Status() = default;
  // Constructs a status; the message is dropped when `code` is kOk.
  Status(StatusCode code, std::string_view message);

  bool ok() const { return code_ == StatusCode::kOk; }
  StatusCode code() const { return code_; }
  std::string_view message() const { return message_; }

  // "OK", or "<CODE>: <message>".
  std::string ToString() const;

  friend bool operator==(const Status&, const Status&) = default;

 private:
  StatusCode code_ = StatusCode::kOk;
  std::string message_;
};

inline Status OkStatus() { return Status(); }
Status InvalidArgumentError(std::string_view message);
Status NotFoundError(std::string_view message);
Status FailedPreconditionError(std::string_view message);
Status OutOfRangeError(std::string_view message);
Status UnavailableError(std::string_view message);
Status InternalError(std::string_view message);
Status DataLossError(std::string_view message);

namespace internal_status {
// Aborts the process after a StatusOr was accessed without a value: a
// programming error, not an expected failure.
[[noreturn]] void DieOnBadAccess(const Status& status);
}  // namespace internal_status

// Either a value of type T or a non-OK Status.
template <typename T>
class [[nodiscard]] StatusOr {
  static_assert(!std::is_same_v<std::remove_cvref_t<T>, Status>,
                "StatusOr<Status> is not allowed");

 public:
  // An error. An OK `status` is a programming error and becomes kInternal.
  StatusOr(Status status)  // NOLINT(*-explicit-constructor): as absl.
      : status_(status.ok()
                    ? InternalError("StatusOr constructed from OK status")
                    : std::move(status)) {}
  // A value.
  StatusOr(T value)  // NOLINT(*-explicit-constructor): as absl.
      : value_(std::move(value)) {}

  bool ok() const { return value_.has_value(); }

  // OK when a value is held.
  const Status& status() const { return status_; }

  // The value. Calling these on an error aborts; check `ok()` first.
  const T& value() const& {
    if (!value_.has_value()) internal_status::DieOnBadAccess(status_);
    return *value_;
  }
  T& value() & {
    if (!value_.has_value()) internal_status::DieOnBadAccess(status_);
    return *value_;
  }
  T&& value() && {
    if (!value_.has_value()) internal_status::DieOnBadAccess(status_);
    return *std::move(value_);
  }
  const T& operator*() const& { return value(); }
  T& operator*() & { return value(); }
  const T* operator->() const { return &value(); }
  T* operator->() { return &value(); }

 private:
  Status status_;  // OK exactly when value_ holds a value.
  std::optional<T> value_;
};

}  // namespace agent

// Returns from the enclosing function when `expr` (a Status) is not OK. The
// enclosing function returns Status or StatusOr<T>.
#define AGENT_RETURN_IF_ERROR(expr)                                    \
  do {                                                                 \
    if (::agent::Status agent_status_ = (expr); !agent_status_.ok()) { \
      return agent_status_;                                            \
    }                                                                  \
  } while (false)

#endif  // AGENT_BASE_STATUS_H_
