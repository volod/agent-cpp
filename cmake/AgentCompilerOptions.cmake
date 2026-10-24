# Warning, hardening, sanitizer and linking options applied to every first-party target through
# agent_apply_options(). Third-party targets (GoogleTest) never receive them.
include_guard(GLOBAL)

set(_agent_common_warnings
  -Wall
  -Wextra
  -Wpedantic
  -Wcast-align
  -Wconversion
  -Wdouble-promotion
  -Wformat=2
  -Wimplicit-fallthrough
  -Wmissing-declarations
  -Wnon-virtual-dtor
  -Wnull-dereference
  -Wold-style-cast
  -Woverloaded-virtual
  -Wshadow
  -Wsign-conversion
  -Wundef
  -Wunused)
set(_agent_gcc_warnings
  -Wduplicated-branches
  -Wduplicated-cond
  -Wlogical-op
  -Wuseless-cast)
set(_agent_clang_warnings
  -Wcomma
  -Wextra-semi
  -Wunreachable-code)

# Applies first-party options to `target`; `scope` is PRIVATE or INTERFACE.
function(agent_apply_options target scope)
  if(scope STREQUAL "INTERFACE")
    return()
  endif()
  set(_cxx "$<COMPILE_LANGUAGE:CXX>")
  target_compile_options(${target} PRIVATE "$<${_cxx}:${_agent_common_warnings}>")
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(${target} PRIVATE "$<${_cxx}:${_agent_gcc_warnings}>")
  else()
    target_compile_options(${target} PRIVATE "$<${_cxx}:${_agent_clang_warnings}>")
  endif()
  if(AGENT_WARNINGS_AS_ERRORS)
    target_compile_options(${target} PRIVATE "$<${_cxx}:-Werror>")
  endif()

  # Hardening. Ubuntu compilers may predefine _FORTIFY_SOURCE, so undefine it first.
  target_compile_options(${target} PRIVATE
    "$<${_cxx}:-fstack-protector-strong>"
    "$<$<AND:${_cxx},$<NOT:$<CONFIG:Debug>>>:-U_FORTIFY_SOURCE;-D_FORTIFY_SOURCE=3>")
  target_compile_definitions(${target} PRIVATE "$<$<CONFIG:Debug>:_GLIBCXX_ASSERTIONS>")

  if(AGENT_SANITIZERS)
    list(JOIN AGENT_SANITIZERS "," _agent_sanitize)
    target_compile_options(${target} PRIVATE
      "$<${_cxx}:-fsanitize=${_agent_sanitize};-fno-omit-frame-pointer;-fno-sanitize-recover=all>")
    target_link_options(${target} PRIVATE "-fsanitize=${_agent_sanitize}")
  endif()
endfunction()

# Link options for executables: fully static when AGENT_STATIC is set, so one binary runs on any
# glibc or uclibc root file system of its architecture (Raspberry Pi OS, Luckfox Buildroot).
function(agent_apply_executable_options target)
  if(AGENT_STATIC)
    target_link_options(${target} PRIVATE -static)
  endif()
endfunction()
