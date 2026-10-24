// Build identity: what was built, from which version, for which platform and
// target. Values are fixed at compile time from the CMake project and the
// compiler's predefined macros.

#ifndef AGENT_BUILD_INFO_BUILD_INFO_H_
#define AGENT_BUILD_INFO_BUILD_INFO_H_

#include <string>
#include <string_view>

namespace agent {

struct BuildInfo {
  std::string_view name;        // CMake project name, e.g. "agent-cpp".
  std::string_view version;     // CMake project version, e.g. "0.1.0".
  std::string_view repository;  // CMake HOMEPAGE_URL.
  std::string_view os;          // "linux", or "unknown".
  std::string_view arch;        // "x86_64", "aarch64", "armv7", ...
  std::string_view
      target;  // AGENT_TARGET_NAME: "host", "rpi5", "luckfox-pico", ...
  std::string_view compiler;  // "gcc 15.2.0", "clang 21.1.6", ...
};

// The identity of this binary.
const BuildInfo& GetBuildInfo();

// One line for `version`, for example
// "agent-cpp 0.1.0 (https://github.com/volod/agent-cpp, linux/aarch64, rpi5,
// gcc 15.2.0)".
std::string VersionLine(const BuildInfo& info);

}  // namespace agent

#endif  // AGENT_BUILD_INFO_BUILD_INFO_H_
