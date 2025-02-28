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

if (NOT USE_SYSTEM_TB_ENGINE)
    message(WARNING ">> Building: TransferBench (TB) as a shared library (plugin)...")

    # Build the TransferBench shared library at config time
    #execute_process(
    #    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/build_libamd_tb.sh 
    #    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/
    #    RESULT_VARIABLE BUILD_SCRIPT_RESULT
    #    OUTPUT_VARIABLE BUILD_SCRIPT_OUTPUT
    #)
    #if (NOT BUILD_SCRIPT_RESULT EQUAL 0)
    #    message(FATAL_ERROR ">> Failed to build TransferBench (TB) shared library (plugin) with error: ${BUILD_SCRIPT_OUTPUT}")
    #endif()

    # Build the TransferBench shared library at build time
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/build_libamd_tb_done.log
        COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/build_libamd_tb.sh
        COMMAND touch ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/build_libamd_tb_done.log
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/
        COMMENT "Building 'libamd_tb' dependency library ..."
    )
    add_custom_target(build_libamd_tb DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/build_libamd_tb_done.log)
    add_subdirectory(transferbench ${CMAKE_CURRENT_BINARY_DIR}/transferbench EXCLUDE_FROM_ALL)

    # Set the include directories
    set(AMD_WORK_BENCH_COMMON_INCLUDE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../common/)
    set(ROCM_PATH "/opt/rocm")
    set(TB_PLUGIN_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/include ${CMAKE_CURRENT_SOURCE_DIR}/transferbench/include/Presets ${ROCM_PATH}/include)
    set(TB_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/deps/libamd_tb.so")

else()
    find_package(TransferBench REQUIRED)
endif()


##
# Add the plugin
set(AMD_WORK_BENCH_PLUGIN_NAME_BUILD "transferbench")
add_amd_work_bench_plugin(
    NAME
        ${AMD_WORK_BENCH_PLUGIN_NAME_BUILD}

    SOURCES
        src/plugin_transferbench.cpp
        src/view_transferbench.cpp
        transferbench/include/plugin_tb_link.hpp

        
    INCLUDES
        include
        ${AMD_WORK_BENCH_COMMON_INCLUDE_DIRECTORY}
        ${TB_PLUGIN_INCLUDE_DIRS}


    LIBRARIES
        ${JTHREAD_LIBRARIES}
        ${TB_LIBRARY}
)

# Add required libraries
add_definitions(-DAMD_LEGACY_PLUGIN_VIEW)
set(AMD_WORK_BENCH_PLUGIN_LIB_LINK_LIST "pthread")
target_link_libraries(${AMD_WORK_BENCH_PLUGIN_NAME_BUILD} PRIVATE ${TB_LIBRARY} ${AMD_WORK_BENCH_PLUGIN_LIB_LINK_LIST})
add_dependencies(${AMD_WORK_BENCH_PLUGIN_NAME_BUILD} build_libamd_tb)