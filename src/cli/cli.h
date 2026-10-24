// The command-line contract: commands, help, output streams and exit codes.
// This is the only module that writes to the process streams or decides an exit
// code; product modules return Status values to it.

#ifndef AGENT_CLI_CLI_H_
#define AGENT_CLI_CLI_H_

#include <ostream>
#include <span>
#include <string_view>

namespace agent::cli {

// Process exit codes; see docs/design/spec.md#command-line-contract.
enum class ExitCode : int {
  kSuccess = 0,
  kFailure = 1,
  kUsage = 2,
};

// Runs the command named by `args` (the arguments after the program name).
// Results and requested help go to `out`; usage errors and diagnostics go to
// `err`.
ExitCode Run(std::span<const std::string_view> args, std::ostream& out,
             std::ostream& err);

}  // namespace agent::cli

#endif  // AGENT_CLI_CLI_H_
