# MIT License
#
# Copyright (c) 2023 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#

#
cmake_minimum_required(VERSION 3.20)

set(AMD_TARGET_SDKNAME "amd_work_benchSDK")
set(AMD_TARGET_LIBNAME "libwork_bench")

project(${AMD_TARGET_SDKNAME}
    VERSION "0.0.1"
    LANGUAGES CXX C
    DESCRIPTION "amd-work-bench SDK Library"
    HOMEPAGE_URL "https://github.amd.com/LSTT/amd-work-bench"
)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "" FORCE)
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/build_utils.cmake")

set(AMD_APP_BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PARENT_SCOPE)
include(build_plugin_utils)

set(AMD_WORK_BENCH_EXTERNAL_PLUGIN_BUILD ON PARENT_SCOPE)
set(AMD_WORK_BENCH_EXTERNAL_PLUGIN_BUILD ON)
add_custom_target(amd_work_bench_all)

# Add the subdirectories when they exist
function(add_existing_subdirectory directory_name)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${directory_name}/CMakeLists.txt")
        add_subdirectory("${directory_name}" EXCLUDE_FROM_ALL)
    endif()
endfunction()

set(FMT_INSTALL OFF CACHE BOOL "" FORCE)
add_existing_subdirectory(deps/3rd_party/fmt)
set(FMT_LIBRARIES fmt::fmt-header-only PARENT_SCOPE)
set(FMT_LIBRARIES fmt::fmt-header-only)

#add_existing_subdirectory(deps/3rd_party/stacktrace)
#set(BOOST_STACKTRACE_LIBRARIES Boost::stacktrace PARENT_SCOPE)
#set(BOOST_STACKTRACE_LIBRARIES Boost::stacktrace)

add_existing_subdirectory(deps/3rd_party/json)
set(NLOHMANN_JSON_LIBRARIES nlohmann_json PARENT_SCOPE)
set(NLOHMANN_JSON_LIBRARIES nlohmann_json)

add_existing_subdirectory(deps/3rd_party/spdlog)
set(SPDLOG_LIBRARIES spdlog::spdlog_header_only PARENT_SCOPE)
set(SPDLOG_LIBRARIES spdlog::spdlog_header_only)

#spdlog::spdlog_header_only
# spdlog::spdlog
# add_existing_subdirectory(deps/3rd_party/boost)
# set(BOOST_LIBRARIES boost::regex PARENT_SCOPE)
# set(BOOST_LIBRARIES boost::regex)
#
find_package(CURL REQUIRED)
set(CURL_LIBRARIES ${CURL_LIBRARIES} PARENT_SCOPE)

add_subdirectory(deps/work_bench)

message(WARNING ">> AMD_TARGET_LIBNAME: ${AMD_TARGET_LIBNAME}")

set_target_properties(${AMD_TARGET_LIBNAME} PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../${AMD_TARGET_LIBNAME}.so"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/deps/work_bench/include")
