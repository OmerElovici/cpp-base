include("${Catch2_SOURCE_DIR}/extras/Catch.cmake")

# Unit tests, discovered individually by CTest.
add_executable(tests tests.cpp)
# Use Catch2's __LINE__ fallback: __COUNTER__ triggers Clang's C++23 pedantic checks.
target_compile_definitions(tests PRIVATE CATCH_CONFIG_NO_COUNTER)
target_link_libraries(
  tests
  PRIVATE myproject::myproject_warnings
          myproject::myproject_options
          myproject::sample_library
          Catch2::Catch2WithMain)

myproject_configure_linker(tests)

if(WIN32 AND BUILD_SHARED_LIBS)
  add_custom_command(
    TARGET tests
    PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:tests> $<TARGET_FILE_DIR:tests>
    COMMAND_EXPAND_LISTS)
endif()

catch_discover_tests(tests TEST_PREFIX "unit." PROPERTIES LABELS "unit")

# CLI smoke tests.
add_test(NAME cli.has_help COMMAND intro --help)
add_test(NAME cli.version_matches COMMAND intro --version)
set_tests_properties(cli.has_help cli.version_matches PROPERTIES LABELS "cli")
set_tests_properties(cli.version_matches PROPERTIES PASS_REGULAR_EXPRESSION "${PROJECT_VERSION}")

add_test(
  NAME cmake.sanitizers.apple_excludes_leak
  COMMAND ${CMAKE_COMMAND} -P
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/test_sanitizers_apple_excludes_leak.cmake")
add_test(
  NAME cmake.sanitizers.non_apple_includes_leak
  COMMAND ${CMAKE_COMMAND} -P
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/test_sanitizers_non_apple_includes_leak.cmake")
set_tests_properties(
  cmake.sanitizers.apple_excludes_leak
  cmake.sanitizers.non_apple_includes_leak
  PROPERTIES LABELS "cmake")
