#include "build_info/build_info.h"

#include <format>
#include <string>

#ifndef AGENT_PROJECT_NAME
#error "AGENT_PROJECT_NAME must be defined by the build"
#endif

#define AGENT_STRINGIFY_INNER(x) #x
#define AGENT_STRINGIFY(x) AGENT_STRINGIFY_INNER(x)

namespace agent {
namespace {

constexpr std::string_view kOs =
#if defined(__linux__)
    "linux";
#else
    "unknown";
#endif

constexpr std::string_view kArch =
#if defined(__x86_64__)
    "x86_64";
#elif defined(__aarch64__)
    "aarch64";
#elif defined(__arm__) && defined(__ARM_ARCH)
        "armv" AGENT_STRINGIFY(__ARM_ARCH);
#elif defined(__riscv) && defined(__riscv_xlen)
        "riscv" AGENT_STRINGIFY(__riscv_xlen);
#else
        "unknown";
#endif

constexpr std::string_view kCompiler =
#if defined(__clang__)
    "clang " AGENT_STRINGIFY(__clang_major__) "." AGENT_STRINGIFY(
        __clang_minor__) "." AGENT_STRINGIFY(__clang_patchlevel__);
#elif defined(__GNUC__)
    "gcc " AGENT_STRINGIFY(__GNUC__) "." AGENT_STRINGIFY(
        __GNUC_MINOR__) "." AGENT_STRINGIFY(__GNUC_PATCHLEVEL__);
#else
    "unknown";
#endif

}  // namespace

const BuildInfo& GetBuildInfo() {
  static constexpr BuildInfo kInfo = {
      .name = AGENT_PROJECT_NAME,
      .version = AGENT_PROJECT_VERSION,
      .repository = AGENT_PROJECT_URL,
      .os = kOs,
      .arch = kArch,
      .target = AGENT_TARGET_NAME,
      .compiler = kCompiler,
  };
  return kInfo;
}

std::string VersionLine(const BuildInfo& info) {
  return std::format("{} {} ({}, {}/{}, {}, {})", info.name, info.version,
                     info.repository, info.os, info.arch, info.target,
                     info.compiler);
}

}  // namespace agent
