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

# Set the project name
set(AMD_TARGET_NAME "amd_work_bench")
set(AMD_TARGET_LIBNAME "libwork_bench")
set(AMD_PROJECT_NAME "awb_main")

project(${AMD_PROJECT_NAME})

add_executable(${AMD_PROJECT_NAME}
    src/awb_main.cpp
    src/cmdline_mgmt.cpp
    src/crash_mgmt.cpp
    src/msg_mgmt.cpp
    src/stacktrace.cpp
    src/startup_mgmt.cpp
)

##
if(NOT USE_LOCAL_CLI11)
    add_subdirectory(${CMAKE_SOURCE_DIR}/deps/3rd_party/CLI11 ${CMAKE_CURRENT_BINARY_DIR}/../../deps/3rd_party/CLI11)
    set(CLI11_LIBRARIES CLI11::CLI11)
    set(CLI11_INCLUDE_DIRS)
else()
    find_package(CLI11 CONFIG QUIT)
endif()


# Build the target binary
#set(WORK_BENCH_INCLUDE ${CMAKE_SOURCE_DIR}/deps/work_bench/include)
#set(WORK_BENCH_DEPENDS_INCLUDE ${CMAKE_SOURCE_DIR}/deps/external/DynLibMgmt/include)

##add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../../deps/external/DynLibMgmt ${CMAKE_CURRENT_BINARY_DIR}/main/cmdline/DynLibMgmt EXCLUDE_FROM_ALL)
target_include_directories(${AMD_PROJECT_NAME} SYSTEM BEFORE PUBLIC ${WORK_BENCH_INCLUDE})
target_include_directories(${AMD_PROJECT_NAME} PUBLIC include ${CLI11_LIBRARIES})

setup_compiler_flags(${AMD_PROJECT_NAME})
setup_compiler_flags(${AMD_TARGET_LIBNAME})
add_dependencies(amd_work_bench_all ${AMD_PROJECT_NAME})

set_target_properties(${AMD_PROJECT_NAME} PROPERTIES
    OUTPUT_NAME ${AMD_WORK_BENCH_APPLICATION_NAME}
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_MAIN_OUTPUT_DIRECTORY}
)

target_compile_definitions(${AMD_PROJECT_NAME} PRIVATE
    AMD_WORK_BENCH_PROJECT_NAME=${PROJECT_NAME}
)

target_link_libraries(${AMD_PROJECT_NAME} PRIVATE ${AMD_TARGET_LIBNAME} ${BACKTRACE_LIBRARIES} pthread ${CLI11_LIBRARIES})
