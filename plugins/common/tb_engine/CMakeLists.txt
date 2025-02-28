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

##
set(AMD_PROJECT_NAME                "tb_engine")
set(AMD_PROJECT_DESCRIPTION         "TransferBench Engine Library")
set(AMD_PROJECT_AUTHOR_ORGANIZATION "AMD, Inc.")
set(AMD_PROJECT_GITHUB_REPO         "https://github.amd.com/LSTT/amd-work-bench")
set(AMD_PROJECT_AUTHOR_DOMAIN       "https://www.amd.com")
set(AMD_PROJECT_AUTHOR_MAINTAINER   "gilbert.lee@amd.com; daniel.oliveira@amd.com")
set(AMD_PROJECT_VERSION_MAJOR       "2025")
set(AMD_PROJECT_VERSION_MINOR       "02")
set(AMD_PROJECT_VERSION_PATCH       "24")
set(AMD_PROJECT_VERSION_FULL        "${AMD_PROJECT_VERSION_MAJOR}.${AMD_PROJECT_VERSION_MINOR}.${AMD_PROJECT_VERSION_PATCH}")

project(${AMD_PROJECT_NAME}
    VERSION ${AMD_PROJECT_VERSION_FULL}
    LANGUAGES CXX C
    DESCRIPTION "amd-work-bench utility"
    HOMEPAGE_URL "https://github.amd.com/LSTT/amd-work-bench"
)
# C++ standard settings
set(CMAKE_CXX_STANDARD 23 CACHE STRING "C++ Standard in use")
set(CMAKE_CXX_STANDARD_REQUIRED ON)

##
message(STATUS "[[ Building... Project: " ${AMD_PROJECT_NAME} "   v." ${AMD_PROJECT_VERSION_FULL} " ]] ...")
if (DEFINED ENV{ROCM_PATH})
    set(ROCM_PATH "$ENV{ROCM_PATH}" CACHE STRING "ROCm install directory")
else()
    set(ROCM_PATH "/opt/rocm" CACHE STRING "ROCm install directory")
endif()

# ROCm paths
set(ROCM_INCLUDE_DIRS ${ROCM_PATH}/include)
set(ROCM_LIBRARY_DIRS ${ROCM_PATH}/lib)

find_package(ROCmCMakeBuildTools 0.8 REQUIRED PATHS ${ROCM_PATH})
find_package(hsa-runtime64 REQUIRED PATHS ${ROCM_PATH})

# Add the include and library paths
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY .)
add_library(${AMD_PROJECT_NAME} SHARED include/TransferBench.hpp)
set_target_properties(${AMD_PROJECT_NAME} PROPERTIES LINKER_LANGUAGE CXX)
set_target_properties(${AMD_PROJECT_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/" LIBRARY_OUTPUT_NAME "libamd_tb_engine" PREFIX "")
set_property(TARGET ${AMD_PROJECT_NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)

#target_include_directories(${AMD_PROJECT_NAME} INTERFACE include ${ROCM_INCLUDE_DIRS})
#target_link_directories(${AMD_PROJECT_NAME} INTERFACE ${ROCM_LIBRARY_DIRS})
#target_link_libraries(${AMD_PROJECT_NAME} INTERFACE hsa-runtime64::hsa-runtime64 numa pthread)

target_include_directories(${AMD_PROJECT_NAME} PRIVATE include ${ROCM_INCLUDE_DIRS})
target_link_directories(${AMD_PROJECT_NAME} PUBLIC ${ROCM_LIBRARY_DIRS})
target_link_libraries(${AMD_PROJECT_NAME} PRIVATE hsa-runtime64 numa pthread)
