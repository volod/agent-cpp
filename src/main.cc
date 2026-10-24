// Process wiring only: collect the arguments, run the CLI on the standard
// streams and return its exit code. Behavior belongs in cli/ and the modules it
// calls.

#include <cstddef>
#include <iostream>
#include <span>
#include <string_view>
#include <vector>

#include "cli/cli.h"

int main(int argc, char** argv) {
  const std::span<char*> raw(argv, static_cast<std::size_t>(argc));
  const std::vector<std::string_view> args(raw.begin() + (raw.empty() ? 0 : 1),
                                           raw.end());
  return static_cast<int>(agent::cli::Run(args, std::cout, std::cerr));
}
