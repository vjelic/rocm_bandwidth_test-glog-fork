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

cmake_minimum_required(VERSION 3.20)
include(build_plugin_utils)

if (NOT USE_SYSTEM_RBT_ENGINE)
    message(WARNING ">> Building: ROCm Bandwidth Test (RBT) as a shared library (plugin)...")
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../common/tb_engine ${CMAKE_CURRENT_BINARY_DIR}/../common/tb_engine EXCLUDE_FROM_ALL)

    # ROCm paths
    set(ROCM_PATH "/opt/rocm")
    set(ROCM_INCLUDE_DIRS ${ROCM_PATH}/include ${ROCM_PATH}/include/hsa ${ROCM_PATH}/include/hip)
    set(ROCM_LIBRARY_DIRS ${ROCM_PATH}/lib)

    # Set the include directories
    set(AMD_WORK_BENCH_COMMON_INCLUDE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../common/)
    set(RBT_PLUGIN_INCLUDE_DIRS include ${ROCM_INCLUDE_DIRS})
    #set(TB_ENGINE_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}../common/tb_engine/libamd_tb_engine.so")
else()
    find_package(ROCmCMakeBuildTools REQUIRED)
    find_package(hsa-runtime64 REQUIRED)
endif()

##
if(NOT USE_LOCAL_CLI11)
    #add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../../deps/3rd_party/CLI11 ${CMAKE_CURRENT_BINARY_DIR}/../../deps/3rd_party/CLI11)
    set(CLI11_LIBRARIES CLI11::CLI11)
    set(CLI11_INCLUDE_DIRS)
else()
    find_package(CLI11 CONFIG QUIT)
endif()

##
# Add the plugin
set(AMD_WORK_BENCH_PLUGIN_NAME_BUILD "rbt")
add_amd_work_bench_plugin(
    NAME
        ${AMD_WORK_BENCH_PLUGIN_NAME_BUILD}

    SOURCES
        src/plugin_rocm_bandwidth_test.cpp
        src/view_rocm_bandwidth_test.cpp

        
    INCLUDES
        include
        ${AMD_WORK_BENCH_COMMON_INCLUDE_DIRECTORY}
        ${CLI11_LIBRARIES}
        ${RBT_PLUGIN_INCLUDE_DIRS}


    LIBRARIES
        ${JTHREAD_LIBRARIES}
        ${CLI11_INCLUDE_DIRS}
        ${ROCM_LIBRARY_DIRS}
        ${TB_ENGINE_LIBRARY}
)

# Add required libraries
add_definitions(-DAMD_LEGACY_PLUGIN_VIEW)
#set(AMD_WORK_BENCH_PLUGIN_LIB_LINK_LIST "hsa-runtime64 numa pthread")
set(AMD_WORK_BENCH_PLUGIN_LIB_LINK_LIST "pthread")
target_link_libraries(${AMD_WORK_BENCH_PLUGIN_NAME_BUILD} PRIVATE ${TB_ENGINE_LIBRARY} ${AMD_WORK_BENCH_PLUGIN_LIB_LINK_LIST})
