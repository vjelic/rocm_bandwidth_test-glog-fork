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

# Set the project name
set(AMD_TARGET_LIBNAME "libdynlibmgmt")
project(${AMD_TARGET_LIBNAME}
    VERSION "0.0.1"
    LANGUAGES CXX C
    DESCRIPTION "Dynamic (Shared) Library Management"
    HOMEPAGE_URL "https://github.com/ROCm/"
)

message(STATUS "[[ Building... Project: " ${AMD_TARGET_LIBNAME} " ]] ...")

# Flag to enable / disable verbose output.
set(CMAKE_VERBOSE_MAKEFILE ON)

# Export compile commands for linters and autocompleters
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CXX_STANDARD 23 CACHE STRING "C++ Standard in use")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INCLUDE_DIRECTORIES_BEFORE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# CMake specific directories
set(AMD_APP_BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set(DYN_LIB_MGMT_SOURCES src/dynlib_mgmt.cpp) 
set(DYN_LIB_MGMT_HEADERS include) 

##
if(DYNAMIC_LIBRARY_MGMT_STATIC_BUILD)
    add_library(${AMD_TARGET_LIBNAME} STATIC ${DYN_LIB_MGMT_SOURCES})
else()
    add_library(${AMD_TARGET_LIBNAME} SHARED ${DYN_LIB_MGMT_SOURCES})
endif()

set(AMD_WORK_BENCH_LIBRARY_TYPE PUBLIC)
target_compile_definitions(${AMD_TARGET_LIBNAME} PRIVATE AMD_PROJECT_NAME="${AMD_TARGET_LIBNAME}")

## Build Library
set(BUILD_INCLUDE_LIST ${CMAKE_CURRENT_SOURCE_DIR}/${DYN_LIB_MGMT_HEADERS} ${AMD_EXTERNAL_DEPS_DIRECTORY})
target_include_directories(${AMD_TARGET_LIBNAME} SYSTEM BEFORE PUBLIC ${BUILD_INCLUDE_LIST})
target_include_directories(${AMD_TARGET_LIBNAME} ${AMD_WORK_BENCH_LIBRARY_TYPE} include ${EXTERNAL_LIB_INCLUDES}) 
target_link_directories(${AMD_TARGET_LIBNAME} ${AMD_WORK_BENCH_LIBRARY_TYPE})
target_link_libraries(${AMD_TARGET_LIBNAME} ${AMD_WORK_BENCH_LIBRARY_TYPE})
set_property(TARGET ${AMD_TARGET_LIBNAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION FALSE)

##
set(DYNAMIC_LIBRARY_MGMT_CXX_FLAGS "${DYNAMIC_LIBRARY_MGMT_CXX_FLAGS} -Werror -Wextra -Wall -Wpedantic -Wno-unused-variable -Wno-unused-function -rdynamic -Wno-array-bounds -Wno-deprecated-declarations -Wno-unknown-pragmas -Wno-restrict -Wno-stringop-overread -Wno-stringop-overflow -Wno-dangling-reference -fexceptions -frtti")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${DYNAMIC_LIBRARY_MGMT_CXX_FLAGS}")
set_target_properties(${AMD_TARGET_LIBNAME} PROPERTIES COMPILE_FLAGS ${DYNAMIC_LIBRARY_MGMT_CXX_FLAGS})
set_target_properties(${AMD_TARGET_LIBNAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set_target_properties(${AMD_TARGET_LIBNAME} PROPERTIES PREFIX "")
