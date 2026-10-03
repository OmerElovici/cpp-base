include(CheckCXXSourceCompiles)

function(myproject_supports_sanitizers)
  set(SUPPORTS_ASAN OFF)
  set(SUPPORTS_UBSAN OFF)

  if(WIN32)
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
      set(SUPPORTS_ASAN ON)
    endif()
  else()
    set(TEST_PROGRAM "int main() { return 0; }")

    # Keep probe flags local to this function and check compile and link support.
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

      if(HAS_UBSAN_LINK_SUPPORT)
        set(SUPPORTS_UBSAN ON)
      endif()
    endif()

    set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

    if(HAS_ASAN_LINK_SUPPORT)
      set(SUPPORTS_ASAN ON)
    endif()
  endif()

  set(SUPPORTS_ASAN ${SUPPORTS_ASAN} PARENT_SCOPE)
  set(SUPPORTS_UBSAN ${SUPPORTS_UBSAN} PARENT_SCOPE)
endfunction()

macro(myproject_setup_options)
  if(PROJECT_IS_TOP_LEVEL)
    myproject_supports_sanitizers()
  else()
    set(SUPPORTS_ASAN OFF)
    set(SUPPORTS_UBSAN OFF)
  endif()

  option(myproject_ENABLE_IPO "Enable IPO/LTO" ${PROJECT_IS_TOP_LEVEL})
  option(myproject_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ${PROJECT_IS_TOP_LEVEL})
  option(myproject_ENABLE_COVERAGE "Enable coverage instrumentation" OFF)
  option(myproject_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
  option(myproject_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
  option(myproject_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
  option(myproject_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
  option(myproject_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer (Clang only)" OFF)
  option(myproject_ENABLE_UNITY_BUILD "Enable unity builds for project targets" OFF)
  option(myproject_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
  option(myproject_ENABLE_FORMAT "Enable the clang-format target" ON)
  option(myproject_ENABLE_PCH "Enable precompiled headers" OFF)
  option(myproject_ENABLE_CACHE "Enable ccache" ${PROJECT_IS_TOP_LEVEL})

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      myproject_ENABLE_IPO
      myproject_WARNINGS_AS_ERRORS
      myproject_ENABLE_COVERAGE
      myproject_ENABLE_SANITIZER_ADDRESS
      myproject_ENABLE_SANITIZER_LEAK
      myproject_ENABLE_SANITIZER_UNDEFINED
      myproject_ENABLE_SANITIZER_THREAD
      myproject_ENABLE_SANITIZER_MEMORY
      myproject_ENABLE_UNITY_BUILD
      myproject_ENABLE_CLANG_TIDY
      myproject_ENABLE_FORMAT
      myproject_ENABLE_PCH
      myproject_ENABLE_CACHE)
  endif()
endmacro()

macro(myproject_global_options)
  if(myproject_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    myproject_enable_ipo()
  endif()
endmacro()

macro(myproject_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
    if(myproject_ENABLE_FORMAT)
      include(cmake/format.cmake)
    endif()
  endif()

  add_library(myproject_warnings INTERFACE)
  add_library(myproject_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  myproject_set_project_warnings(
    myproject_warnings
    ${myproject_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  include(cmake/Sanitizers.cmake)
  myproject_enable_sanitizers(
    myproject_options
    ${myproject_ENABLE_SANITIZER_ADDRESS}
    ${myproject_ENABLE_SANITIZER_LEAK}
    ${myproject_ENABLE_SANITIZER_UNDEFINED}
    ${myproject_ENABLE_SANITIZER_THREAD}
    ${myproject_ENABLE_SANITIZER_MEMORY})

  # Initialize real targets created after local_options(), after dependencies
  # have already been added. UNITY_BUILD on an interface target is not inherited.
  # Leave a user's native CMAKE_UNITY_BUILD setting intact when this option is OFF.
  if(myproject_ENABLE_UNITY_BUILD)
    set(CMAKE_UNITY_BUILD ON)
  endif()

  # Define PCH before clang-tidy checks for incompatible compiler/PCH combinations.
  if(myproject_ENABLE_PCH)
    target_precompile_headers(myproject_options INTERFACE <vector> <string> <utility>)
  endif()

  if(myproject_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    myproject_enable_cache()
  endif()

  if(myproject_ENABLE_CLANG_TIDY)
    include(cmake/ClangTidy.cmake)
    myproject_enable_clang_tidy(myproject_options ${myproject_WARNINGS_AS_ERRORS})
  endif()

  if(myproject_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    myproject_enable_coverage(myproject_options)
  endif()

endmacro()
