#include "cli/cli.h"

#include <format>
#include <ostream>
#include <span>
#include <string>
#include <string_view>

#include "base/status.h"
#include "build_info/build_info.h"

namespace agent::cli {
namespace {

std::string Usage(std::string_view program) {
  return std::format(
      "Usage: {} <command>\n"
      "\n"
      "Commands:\n"
      "  version    Print the name, version, repository, platform and target\n"
      "  help       Print this help (also -h, --help)\n",
      program);
}

// Writes `text` to `out` and reports a failed write, for example a closed pipe.
Status Write(std::ostream& out, std::string_view text) {
  out << text;
  out.flush();
  if (!out) return UnavailableError("cannot write to standard output");
  return OkStatus();
}

ExitCode UsageError(std::ostream& err, std::string_view program,
                    std::string_view message) {
  err << program << ": " << message << "\n\n" << Usage(program);
  return ExitCode::kUsage;
}

ExitCode Finish(const Status& status, std::ostream& err,
                std::string_view program) {
  if (status.ok()) return ExitCode::kSuccess;
  err << program << ": " << status.message() << '\n';
  return ExitCode::kFailure;
}

}  // namespace

ExitCode Run(std::span<const std::string_view> args, std::ostream& out,
             std::ostream& err) {
  const BuildInfo& info = GetBuildInfo();
  const std::string_view program = info.name;
  if (args.empty()) return UsageError(err, program, "missing command");

  const std::string_view command = args.front();
  if (command == "help" || command == "-h" || command == "--help") {
    if (args.size() > 1)
      return UsageError(err, program, "help takes no arguments");
    return Finish(Write(out, Usage(program)), err, program);
  }
  if (command == "version" || command == "--version") {
    if (args.size() > 1)
      return UsageError(err, program, "version takes no arguments");
    return Finish(Write(out, VersionLine(info) + "\n"), err, program);
  }
  return UsageError(err, program,
                    std::format("unknown command \"{}\"", command));
}

}  // namespace agent::cli
