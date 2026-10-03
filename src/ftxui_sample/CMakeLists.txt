add_executable(intro main.cpp)

target_link_libraries(
  intro
  PRIVATE myproject::myproject_options
          myproject::myproject_warnings
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          ftxui::screen
          ftxui::dom
          ftxui::component)

myproject_configure_linker(intro)

target_compile_definitions(
  intro
  PRIVATE MYPROJECT_NAME="${PROJECT_NAME}"
          MYPROJECT_VERSION="${PROJECT_VERSION}")
