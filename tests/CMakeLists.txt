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
# TODO: Set these down to children CMakeLists.txt with 'PARENT_SCOPE'
set(AMD_PROJECT_NAME "unit_tests")
set(AMD_TARGET_NAME "tests_common")
set(AMD_TARGET_LIBNAME "libamd_work_bench")
project(${AMD_PROJECT_NAME})

# TODO:  Add needed subdirectories
add_subdirectory(common)
target_compile_definitions(${AMD_TARGET_NAME} PUBLIC AMD_WORK_BENCH_PROJECT_NAME="${PROJECT_NAME}")

add_subdirectory(plugins)


## End of CMakeLists.txt

