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

set(AMD_TARGET_LIBNAME "libwork_bench")
project(${AMD_WORK_BENCH_PLUGIN_NAME}_tests)

#   TODO: Put together the list of the tests here
set(AVAILABLE_TESTS_LIST 
    testA
    TestB
)

add_library(${PROJECT_NAME} SHARED
    src/main_builtin_plugin_tests.cpp
)

target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/plugins/builtin/include)
target_link_libraries(${PROJECT_NAME} PRIVATE ${AMD_TARGET_LIBNAME})

foreach(available_test IN LISTS AVAILABLE_TESTS_LIST)
    add_test(NAME "Plugin_${AMD_WORK_BENCH_PLUGIN_NAME}/${available_test}" COMMAND $<TARGET_FILE:plugins_test> "${available_test}" WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
endforeach()
