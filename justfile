# Requires Just 1.44+ and CMake 3.29+.
set shell := ["sh", "-eu", "-c"]
set windows-shell := ["cmd.exe", "/D", "/V:OFF", "/C"]

_default_preset := if os() == "windows" { "windows-msvc-debug" } else if os() == "macos" { "unixlike-clang-debug" } else { "unixlike-gcc-debug" }
preset := _default_preset
build_dir := "out/build/" + preset
test_preset := "test-" + preset

# Show usage and available commands.
help:
    @cmake -E echo "Select a preset: just preset=NAME COMMAND"
    @cmake -E echo "List presets: just presets"
    @cmake -E echo "Default preset: {{_default_preset}}"
    @cmake -E echo "Configure first; repeat preset=NAME for each invocation."
    @cmake -E echo "check enables clang-tidy and leaves it enabled."
    @"{{just_executable()}}" --list

# List available presets.
presets:
    cmake --list-presets=all

# Configure the selected preset with optional simple CMake flags.
configure *args:
    cmake --preset "{{preset}}" -B "{{build_dir}}" {{args}}
    cmake -E copy_if_different "{{build_dir}}/compile_commands.json" compile_commands.json

# Build all default targets or one named target.
build $target="":
    cmake --build "{{build_dir}}" --preset "{{preset}}" --parallel {{if target == "" { "" } else if os() == "windows" { '--target "%target%"' } else { '--target "$target"' }}}
    cmake -E copy_if_different "{{build_dir}}/compile_commands.json" compile_commands.json

# Build, then run tests with an optional name filter.
test $regex="": build
    ctest --preset "{{test_preset}}" --test-dir "{{build_dir}}" {{if regex == "" { "" } else if os() == "windows" { '-R "%regex%"' } else { '-R "$regex"' }}}

# Enable clang-tidy, build, and test. Analysis stays enabled.
check:
    cmake --preset "{{preset}}" -B "{{build_dir}}" -Dmyproject_ENABLE_CLANG_TIDY:BOOL=ON "-DCLANGTIDY:FILEPATH={{require('clang-tidy')}}"
    cmake --build "{{build_dir}}" --preset "{{preset}}" --parallel
    cmake -E copy_if_different "{{build_dir}}/compile_commands.json" compile_commands.json
    ctest --preset "{{test_preset}}" --test-dir "{{build_dir}}"

# List build targets.
targets:
    cmake --build "{{build_dir}}" --preset "{{preset}}" --target help

# Clean outputs while keeping configuration and dependencies.
clean:
    cmake --build "{{build_dir}}" --preset "{{preset}}" --target clean

# Clean and build.
rebuild:
    cmake --build "{{build_dir}}" --preset "{{preset}}" --parallel --clean-first
    cmake -E copy_if_different "{{build_dir}}/compile_commands.json" compile_commands.json

# Run the existing format target.
format:
    cmake --build "{{build_dir}}" --preset "{{preset}}" --target format
