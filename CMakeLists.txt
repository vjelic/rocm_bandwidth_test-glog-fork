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

# Build is not supported on Windows plaform
if(WIN32)
    message(FATAL_ERROR "Windows platfom is not supported!")
    return()
endif()

# Flag to enable / disable verbose output.
set(CMAKE_VERBOSE_MAKEFILE ON)

# Export compile commands for linters and autocompleters
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# C++ standard settings
set(CMAKE_CXX_STANDARD 23 CACHE STRING "C++ Standard in use")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INCLUDE_DIRECTORIES_BEFORE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

#
# CMake specific directories
set(AMD_APP_BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set(AMD_APP_CMAKE_DIRECTORY ${AMD_APP_BASE_DIRECTORY}/cmake)
set(AMD_APP_CMAKE_MODULES_DIRECTORY ${AMD_APP_BASE_DIRECTORY}/cmake/modules)
list(APPEND CMAKE_MODULE_PATH "${AMD_APP_CMAKE_MODULES_DIRECTORY}")
set(AMD_EXTERNAL_DEPS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/deps/external)


#
# CMake specific directories

#
# CMake options
set(AMD_TARGET_NAME "amd_work_bench")
set(AMD_TARGET_LIBNAME "libwork_bench")
option(AMD_APP_DEBUG_INFO_COMPRESS          "Compressed debug information"                                          ON)
option(AMD_APP_BUILD_PLUGINS                "Build plugins"                                                         ON)
option(AMD_APP_STORE_PLUGINS_IN_SHARE       "Store the plugins in the share/${AMD_TARGET_NAME}/plugins"             OFF)
option(AMD_APP_STATIC_LINK_PLUGINS          "Statically link plugins into the '${AMD_TARGET_NAME}' executable"      OFF)
option(AMD_APP_LTO_ENABLED                  "Link Time Optimization if/when possible"                               OFF)
option(AMD_APP_TREAT_WARNINGS_AS_ERRORS     "Treat default warnings as errors"                                      ON)
option(AMD_APP_ENABLE_UNITY_BUILD           "Build the project using unity build"                                   OFF)
option(AMD_APP_BUILD_PACKAGE                "Build package"                                                         ON)
option(AMD_APP_DISABLE_STACKTRACE           "Disable stack trace support"                                           OFF)
option(AMD_APP_SETUP_SDK                    "Setup SDK structure"                                                   ON)
option(AMD_APP_BUILD_DOCS                   "Build documentation"                                                   ON)
option(AMD_APP_BUILD_EXAMPLES               "Build examples"                                                        ON)
option(AMD_APP_BUILD_TESTS                  "Build unit tests"                                                      OFF)


# Setup build utils
include(${AMD_APP_CMAKE_DIRECTORY}/build_utils.cmake)

#
# Specify name of project to build, and validate requiments
setup_build_version(AMD_TARGET_VERSION AMD_TARGET_VERSION_TEXT)
set_variable_in_parent(AMD_WORK_BENCH_VERSION ${AMD_TARGET_VERSION})
setup_cmake(AMD_TARGET_NAME AMD_WORK_BENCH_VERSION)

##
set(AMD_PROJECT_NAME        ${AMD_TARGET_NAME})
set(AMD_PROJECT_DESCRIPTION "amd-work-bench utility")
set(AMD_PROJECT_AUTHOR_ORGANIZATION "AMD, Inc.")
set(AMD_PROJECT_GITHUB_REPO         "https://github.amd.com/LSTT/amd-work-bench")
set(AMD_PROJECT_AUTHOR_DOMAIN       "https://www.amd.com")
set(AMD_PROJECT_AUTHOR_MAINTAINER   "daniel.oliveira@amd.com")
set(AMD_PROJECT_VERSION_MAJOR       "2025")
set(AMD_PROJECT_VERSION_MINOR       "02")
set(AMD_PROJECT_VERSION_PATCH       "24")
set(AMD_PROJECT_VERSION_FULL "${AMD_PROJECT_VERSION_MAJOR}.${AMD_PROJECT_VERSION_MINOR}.${AMD_PROJECT_VERSION_PATCH}")

project(${AMD_TARGET_NAME}
    VERSION ${AMD_TARGET_VERSION_TEXT}
    LANGUAGES CXX C
    DESCRIPTION "amd-work-bench utility"
    HOMEPAGE_URL "https://github.amd.com/LSTT/amd-work-bench"
)

#
# Build Version
# Todo: github commit hash
message(STATUS "[[ Building... Project: " ${CMAKE_PROJECT_NAME} "   v." ${AMD_TARGET_VERSION_TEXT} " / " ${AMD_TARGET_VERSION} " ]] ...")

setup_project()
add_custom_target(amd_work_bench_all ALL)
setup_default_build_options()
check_compiler_requirements(AMD_TARGET_NAME)
check_builtin_plugin_set()
check_os_build_definitions()
add_build_definitions()

#
# Packaging and Install
setup_packaging_options()
setup_install_target()
add_bundled_libraries()

#
add_subdirectory(deps/external/dynamic_lib_mgmt)
add_subdirectory(deps/work_bench)
add_subdirectory(main)


# Build additional components
if(AMD_APP_BUILD_PLUGINS)
    add_plugin_directories()
endif()

if(AMD_APP_BUILD_DOCS)
    # add_subdirectory(docs)
endif()

if(AMD_APP_BUILD_EXAMPLES)
    # add_subdirectory(examples)
endif()

# Build unit tests
if(AMD_APP_BUILD_TESTS)
    if (NOT TARGET unit_tests)
        enable_testing()
        add_custom_target(unit_tests)
        add_subdirectory(tests EXCLUDE_FROM_ALL)
    endif()
endif()

#
# Additional resources for packaging/install
if(AMD_APP_SETUP_SDK)
    setup_sdk_options()
endif()

# Package the build
if (AMD_APP_BUILD_PACKAGE)
    setup_distribution_package()
endif()

#
adjust_ide_support_targets()
