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
set(AMD_PROJECT_NAME                "libamd_tb_engine")
set(AMD_PROJECT_DESCRIPTION         "TransferBench Engine Library")
set(AMD_PROJECT_AUTHOR_ORGANIZATION "AMD, Inc.")
set(AMD_PROJECT_GITHUB_REPO         "https://github.com/ROCm/rocm_bandwidth_test")
set(AMD_PROJECT_AUTHOR_DOMAIN       "https://www.amd.com")
set(AMD_PROJECT_AUTHOR_MAINTAINER   "gilbert.lee@amd.com; daniel.oliveira@amd.com")
set(AMD_PROJECT_VERSION_MAJOR       "2025")
set(AMD_PROJECT_VERSION_MINOR       "03")
set(AMD_PROJECT_VERSION_PATCH       "21")
set(AMD_PROJECT_VERSION_FULL        "${AMD_PROJECT_VERSION_MAJOR}.${AMD_PROJECT_VERSION_MINOR}.${AMD_PROJECT_VERSION_PATCH}")

project(${AMD_PROJECT_NAME}
    VERSION ${AMD_PROJECT_VERSION_FULL}
    LANGUAGES CXX C
    DESCRIPTION ${AMD_PROJECT_DESCRIPTION}
    HOMEPAGE_URL ${AMD_PROJECT_GITHUB_REPO}
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
set(ROCM_INCLUDE_DIRS ${ROCM_PATH}/include ${ROCM_PATH}/include/hsa ${ROCM_PATH}/include/hip)
set(ROCM_LIBRARY_DIRS ${ROCM_PATH}/lib)

find_package(ROCmCMakeBuildTools 0.8 REQUIRED PATHS ${ROCM_PATH})
find_package(hsa-runtime64 REQUIRED PATHS ${ROCM_PATH})


### Important Note: 
##  A good approach here would be: '${AMD_PROJECT_NAME} INTERFACE'
##  This way, the library will be available to all targets that link to it.
##  This is a good practice for libraries that are meant to be used by other targets.
##  However, that bring some issues with the way the library is built and installed, not to mention 
##  the crazy number of compiler warnings that will be generated, due to the fact that both `TBENGINE` 
##  and HIP/HSA are much more relaxed about the warnings, whereas the rest of the code is not, and we
##  would need to work around all of that with a lot of compiler flags and other stuff: 
##      - pragma GCC diagnostic ignored "-Wunused-parameter"
##      - pragma GCC diagnostic ignored "-Wpedantic"
##      - pragma GCC diagnostic ignored "-Wdeprecated-declarations"
##      - pragma GCC diagnostic ignored "-Wignored-qualifiers"
##      - pragma GCC diagnostic ignored "-Wdeprecated"
##
##  Errors like (just to point a few): 
##    - error: ISO C++ prohibits anonymous structs
##    - error: attributes are not permitted in this position 
##    - note: attributes may be inserted here extern "C" ^ hipError_t 
##    - error: ISO C++ forbids flexible array member ‘data’
##    - error: expected primary-expression before ‘,’ token
##    - error: unused parameter ‘xyz’
## 
##  with all of that, we would be ignoring a lot of warnings that are actually important, and that would
##  be a bad practice, and also we delay the adoption of newer standards/practices. 
##
##  Due to that, we are going to use the 'SHARED' option, so we don't mix builds with different approaches
##  in just one binary. 
##        
####
### Add the include and library paths
####add_library(${AMD_PROJECT_NAME} INTERFACE)
####target_compile_definitions(${AMD_PROJECT_NAME} INTERFACE 
####    __HIP_PLATFORM_AMD__ 
####)
####
####target_include_directories(${AMD_PROJECT_NAME} INTERFACE 
####    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
####    $<INSTALL_INTERFACE:include>
####)
##
add_library(${AMD_PROJECT_NAME} SHARED 
    include/TransferBench.hpp
)

#target_compile_definitions(${AMD_PROJECT_NAME} PUBLIC 
#    __HIP_PLATFORM_AMD__ 
#)

## Relax the compiler warnings
target_compile_options(${AMD_PROJECT_NAME} PRIVATE
    -Wno-pedantic           # Disable pedantic warnings
    -Wno-error              # Don’t treat warnings as errors
    -Wno-unused-parameter   # Don’t treat unused parameters as errors
)

target_include_directories(${AMD_PROJECT_NAME} INTERFACE 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${ROCM_INCLUDE_DIRS}>
    $<INSTALL_INTERFACE:include>
)

## Library properties
if(BUILD_INTERNAL_BINARY_VERSION)
    set(BUILD_BINARY_VERSION ${BUILD_INTERNAL_BINARY_VERSION})
else()
    set(BUILD_BINARY_VERSION ${AMD_PROJECT_VERSION_FULL})
endif()

set_target_properties(${AMD_PROJECT_NAME} PROPERTIES
    LINKER_LANGUAGE CXX
    SOVERSION ${BUILD_BINARY_VERSION}
    PREFIX ""
    PUBLIC_HEADER include/TransferBench.hpp
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

find_library(NUMA_LIBRARY NAMES numa libnuma)
if(NOT NUMA_LIBRARY) 
    message(FATAL_ERROR "NUMA library not found!")
endif()

find_library(HSA_LIBRARY NAMES hsa-runtime64 libhsa-runtime64 PATHS ${ROCM_LIBRARY_DIRS})
if(NOT HSA_LIBRARY) 
    message(FATAL_ERROR "HSA library not found!")
endif()

## External links
target_link_libraries(${AMD_PROJECT_NAME} INTERFACE 
    ${NUMA_LIBRARY} 
    ${HSA_LIBRARY} 
    pthread
)

# 
## Install target
install(TARGETS ${AMD_PROJECT_NAME} 
    LIBRARY DESTINATION lib
    PUBLIC_HEADER DESTINATION include
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE 
                GROUP_READ GROUP_WRITE GROUP_EXECUTE 
                WORLD_READ WORLD_EXECUTE
)

## End of CMakeLists.txt
