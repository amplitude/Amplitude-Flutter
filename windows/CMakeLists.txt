cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "amplitude_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "amplitude_flutter_plugin")

# Fetch nlohmann/json (header-only, skip install to avoid permission issues)
include(FetchContent)
set(JSON_Install OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
  json
  URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(json)

list(APPEND PLUGIN_SOURCES
  "amplitude_flutter_plugin.cpp"
  "amplitude_flutter_plugin.h"
  "amplitude_instance.cpp"
  "amplitude_instance.h"
  "event_queue.cpp"
  "event_queue.h"
  "http_transport.cpp"
  "http_transport.h"
  "device_info.cpp"
  "device_info.h"
  "storage.cpp"
  "storage.h"
  "uuid.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/amplitude_flutter/amplitude_flutter_plugin_c_api.h"
  "amplitude_flutter_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  nlohmann_json::nlohmann_json
  winhttp.lib
  bcrypt.lib
)

set(amplitude_flutter_bundled_libraries "" PARENT_SCOPE)
