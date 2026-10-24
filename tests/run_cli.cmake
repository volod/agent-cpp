# Runs the built binary once and checks its exit code and streams. Invoked by CTest as
#   cmake -DCLI=<binary> -DEMULATOR=<a|b|c> -DARGS=<a|b> -DEXPECT_CODE=<n>
#         -DEXPECT_STDOUT=<regex> -DEXPECT_STDERR=<regex> -P run_cli.cmake
# Lists use '|' because ';' does not survive the command line. An empty regex requires an empty
# stream. EMULATOR is CMAKE_CROSSCOMPILING_EMULATOR (qemu-user) for cross builds.
cmake_minimum_required(VERSION 3.28)

string(REPLACE "|" ";" _emulator "${EMULATOR}")
string(REPLACE "|" ";" _args "${ARGS}")
execute_process(
  COMMAND ${_emulator} "${CLI}" ${_args}
  RESULT_VARIABLE _code
  OUTPUT_VARIABLE _stdout
  ERROR_VARIABLE _stderr)

set(_failures "")
if(NOT _code STREQUAL EXPECT_CODE)
  string(APPEND _failures "exit code ${_code}, want ${EXPECT_CODE}\n")
endif()
foreach(_stream stdout stderr)
  string(TOUPPER "${_stream}" _upper)
  set(_want "${EXPECT_${_upper}}")
  set(_got "${_${_stream}}")
  if(_want STREQUAL "")
    if(NOT _got STREQUAL "")
      string(APPEND _failures "${_stream} must be empty, got:\n${_got}\n")
    endif()
  elseif(NOT _got MATCHES "${_want}")
    string(APPEND _failures "${_stream} does not match \"${_want}\", got:\n${_got}\n")
  endif()
endforeach()

if(_failures)
  message(FATAL_ERROR "${CLI} ${ARGS}:\n${_failures}")
endif()
