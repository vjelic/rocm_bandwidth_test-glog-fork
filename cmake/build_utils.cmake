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

# Default GNU install directories
# #include(CMakePackageConfigHelpers)
include(FetchContent)

#
# Note: All functions definitions here
function(setup_rocm_auto_build_environment is_auto_detect_rocm_build is_rocm_build_package_result)
    message(STATUS ">> ROCm auto build environment checking...")
    if(is_rocm_build_package_result)
        message(STATUS ">> ROCm build package already set up!")
        return()
    endif()
    if(NOT is_auto_detect_rocm_build)
        set(${is_rocm_build_package_result} FALSE PARENT_SCOPE)    
        return()
    endif()

    ##
    message(STATUS "  >> ROCm build environment: ${${is_auto_detect_rocm_build}}")
    if(${is_auto_detect_rocm_build})
        ## Disable ROCM_WARN_TOOLCHAIN warnings by default
        set(ROCM_WARN_TOOLCHAIN_VAR OFF CACHE BOOL "ROCM_WARN_TOOLCHAIN warnings disabled: 'OFF'")
        set(ROCM_DEFAULT_PATH "/opt/rocm")
        if(DEFINED ENV{ROCM_PATH})
            message(STATUS "  >> ROCM_PATH is set. ROCm build package enabled and using: '$ENV{ROCM_PATH}'")
            set(ROCM_PATH "$ENV{ROCM_PATH}" CACHE STRING "ROCm install directory")
        else()
            message(STATUS "  >> ROCM_PATH is not set. ROCm build package will be set to: '${ROCM_DEFAULT_PATH}'")
            set(ROCM_PATH ${ROCM_DEFAULT_PATH} CACHE STRING "ROCm install directory")
        endif()

        ##list(APPEND CMAKE_PREFIX_PATH ${ROCM_PATH} ${ROCM_PATH}/hip)
        ##find_package(HIP QUIET PATHS ${ROCM_PATH})
        find_package(ROCmCMakeBuildTools QUIET PATHS ${ROCM_PATH})
        find_package(ROCM QUIET PATHS ${ROCM_PATH})
        find_package(hsa-runtime64 QUIET PATHS ${ROCM_PATH})
        if((ROCmCMakeBuildTools_FOUND OR ROCM_FOUND) AND hsa-runtime64_FOUND)
            message(STATUS "  >> ROCm build environment/dependencies were found. ROCm build/package is set up!")
            set(${is_rocm_build_package_result} TRUE PARENT_SCOPE)
        else()
            message(STATUS "  >> ROCm build environment/dependencies requirements not met. Only standalone build/package is available!")
            set(${is_rocm_build_package_result} FALSE PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(setup_build_version version_num version_text)
    set(TARGET_VERSION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${TARGET_VERSION_FILE})
    file(READ "${TARGET_VERSION_FILE}" file_version)
    string(STRIP ${file_version} file_version)
    string(REPLACE ".wip" "" file_version_text ${file_version})
    string(REPLACE ".WIP" "" file_version_text ${file_version})

    #string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+.*" "\\1" CPACK_PACKAGE_VERSION_MAJOR ${file_version_text})
    #string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+.*" "\\1" CPACK_PACKAGE_VERSION_MINOR ${file_version_text})
    #string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+).*" "\\1" CPACK_PACKAGE_VERSION_PATCH ${file_version_text})
    #set(PROJECT_VERSION ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH})
    set(${version_num} ${file_version} PARENT_SCOPE)
    set(${version_text} ${file_version_text} PARENT_SCOPE)
endfunction()

function(setup_project)
    enable_language(C CXX)
    set(PROJECT_MAIN_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}" PARENT_SCOPE)
endfunction()

function(has_minimum_compiler_version_for_standard cpp_standard compiler_id compiler_version result)
    set(COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT "")
    if(${cpp_standard} EQUAL 23)
        if(${compiler_id} MATCHES "GNU")
            set(COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT "13.3.0")
        elseif(${compiler_id} MATCHES "Clang")
            set(COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT "17.0.0")
        endif()
    elseif(${cpp_standard} EQUAL 20)
        if(${compiler_id} MATCHES "GNU")
            set(COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT "11.0.0")
        elseif(${compiler_id} MATCHES "Clang")
            set(COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT "16.0.0")
        endif()
    elseif(cpp_standard EQUAL 17)
        if(${compiler_id} MATCHES "GNU")
            set(COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT "10.0.0")
        elseif(${compiler_id} MATCHES "Clang")
            set(COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT "15.0.0")
        endif()
    endif()

    if (${compiler_version} VERSION_LESS ${COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT})
        set(${result} FALSE PARENT_SCOPE)
    else()
        set(${result} TRUE PARENT_SCOPE)
    endif()
endfunction()

function(check_default_compiler_requirements result)
    set(HAS_DEFAULT_COMPILER_REQUIREMENTS FALSE)
    if(AMD_APP_COMPILER_TRY_CLANG)
        set(CLANG_COMPILER_MAJOR_VERSION_REQUIRED "19")
        set(CLANG_COMPILER_MINOR_VERSION_REQUIRED "0")
        set(CLANG_COMPILER_REVISION_VERSION_REQUIRED "0")
        set(CLANG_COMPILER_MINIMUM_VERSION_REQUIRED "${CLANG_COMPILER_MAJOR_VERSION_REQUIRED}.${CLANG_COMPILER_MINOR_VERSION_REQUIRED}.${CLANG_COMPILER_REVISION_VERSION_REQUIRED}")
        set(ROCM_LLVM_BIN_PATH  "/opt/rocm/lib/llvm/bin/")
        message(WARNING ">> Trying to setup 'Clang++' as default compiler (COMPILER_TRY_CLANG=ON)")
        message(STATUS "  >> Minimum version required for setting: 'v${CLANG_COMPILER_MINIMUM_VERSION_REQUIRED}'")
        find_program(CLANG_COMPILER_CXX clang++ HINTS ${CMAKE_CXX_COMPILER_PATH} ${CMAKE_CXX_COMPILER} ${ROCM_LLVM_BIN_PATH})
        if(CLANG_COMPILER_CXX)
            execute_process( 
                COMMAND ${CLANG_COMPILER_CXX} -dumpversion
                OUTPUT_VARIABLE CLANG_COMPILER_VERSION
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )

            ## Check if the version is valid
            string(REGEX MATCHALL "[0-9]+" CLANG_COMPILER_VERSION_COMPONENTS "${CLANG_COMPILER_VERSION}")
            if(CLANG_COMPILER_VERSION_COMPONENTS)
                list(GET CLANG_COMPILER_VERSION_COMPONENTS 0 CLANG_COMPILER_VERSION_MAJOR)
                list(GET CLANG_COMPILER_VERSION_COMPONENTS 1 CLANG_COMPILER_VERSION_MINOR)
                list(GET CLANG_COMPILER_VERSION_COMPONENTS 2 CLANG_COMPILER_VERSION_REVISION)
                ## 
                if(CLANG_COMPILER_VERSION_MAJOR GREATER_EQUAL ${CLANG_COMPILER_MAJOR_VERSION_REQUIRED} AND 
                   CLANG_COMPILER_VERSION_MINOR GREATER_EQUAL ${CLANG_COMPILER_MINOR_VERSION_REQUIRED})
                    set(CLANG_COMPILER_VERSION_RESULT TRUE)
                else()
                    set(CLANG_COMPILER_VERSION_RESULT FALSE)
                endif()
            endif()
            
            if(NOT CLANG_COMPILER_VERSION_RESULT)
                message(WARNING ">> 'Clang++' compiler v'${CLANG_COMPILER_VERSION}' is not as default compiler! Minimum version required: 'v${CLANG_COMPILER_MINIMUM_VERSION_REQUIRED}'")
                message(STATUS  "  >> falling back default compiler 'g++' and requirements...")
            else()
                set(HAS_DEFAULT_COMPILER_REQUIREMENTS TRUE)
                get_filename_component(DEFAULT_COMPILER_DIRECTORY_NAME "${CLANG_COMPILER_CXX}" DIRECTORY)
                set(CLANG_COMPILER_C "${DEFAULT_COMPILER_DIRECTORY_NAME}/clang")
                set(CMAKE_CXX_COMPILER ${CLANG_COMPILER_CXX})
                set(CMAKE_C_COMPILER ${CLANG_COMPILER_C})
                #set(CMAKE_CXX_COMPILER_ID "Clang")
                #set(CMAKE_C_COMPILER_ID "Clang")
                message(STATUS "  >> Setting compiler to: '${CMAKE_CXX_COMPILER}' v${CLANG_COMPILER_VERSION_MAJOR}.${CLANG_COMPILER_VERSION_MINOR}.${CLANG_COMPILER_VERSION_REVISION}")
            endif()

        else()
            message(FATAL_ERROR ">> 'Clang++' compiler not found (COMPILER_TRY_CLANG=ON)!")
        endif()

        if (HAS_DEFAULT_COMPILER_REQUIREMENTS)
            set(${result} TRUE PARENT_SCOPE)
        else()
            set(${result} FALSE PARENT_SCOPE)
        endif()
    endif()        
endfunction()

function(check_compiler_requirements component_name)
    check_default_compiler_requirements(WAS_TRY_CLANG_DEFAULT_COMPILER)
    if(WAS_TRY_CLANG_DEFAULT_COMPILER)
        message(STATUS ">> COMPILER_TRY_CLANG=ON: Default compiler already set to 'Clang++' ...")
        return()
    endif()

    if(CMAKE_CXX_STANDARD EQUAL 23)
        #set(GCC_COMPILER_MINIMUM_VERSION "13.0.0")
        set(GCC_COMPILER_MINIMUM_VERSION "12.3.0")
        set(CLANG_COMPILER_MINIMUM_VERSION "17.0.0")
    elseif(CMAKE_CXX_STANDARD EQUAL 20)
        set(GCC_COMPILER_MINIMUM_VERSION "11.0.0")
        set(CLANG_COMPILER_MINIMUM_VERSION "16.0.0")
    elseif(CMAKE_CXX_STANDARD EQUAL 17)
        set(GCC_COMPILER_MINIMUM_VERSION "10.0.0")
        set(CLANG_COMPILER_MINIMUM_VERSION "15.0.0")
    endif()

    if(NOT GCC_COMPILER_MINIMUM_VERSION OR NOT CLANG_COMPILER_MINIMUM_VERSION)
        message(FATAL_ERROR ">> CXX Standard '${CMAKE_CXX_STANDARD}' not supported!")
    endif()

    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${GCC_COMPILER_MINIMUM_VERSION})
        message(FATAL_ERROR ">> ${${component_name}} requires GCC ${GCC_COMPILER_MINIMUM_VERSION} or newer.")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${CLANG_COMPILER_MINIMUM_VERSION})
        message(FATAL_ERROR ">> ${${component_name}} requires Clang ${CLANG_COMPILER_MINIMUM_VERSION} or newer.")
    elseif(NOT(CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang"))
        message(FATAL_ERROR ">> ${${component_name}} only supports 'GCC' or 'Clang'. The actual compiler '${CMAKE_CXX_COMPILER_ID}' is not supported!")
    endif()
endfunction()

function(setup_unity_build target_name)
    if(AMD_APP_ENABLE_UNITY_BUILD)
        set_target_properties(${target_name} PROPERTIES UNITY_BUILD ON UNITY_BUILD_MODE BATCH)
    endif()
endfunction()

function(setup_sdk_options)
    message(STATUS ">> Setting up SDK components:")
    if (NOT AMD_TARGET_NAME)
        set(AMD_TARGET_NAME "rocm-bandwidth-test")
        message(WARNING "  >> Project: 'AMD_TARGET_NAME' was not defined! Using default name: '${AMD_TARGET_NAME}'")
    endif()
    set(SDK_INSTALL_PATH "share/${AMD_TARGET_NAME}/sdk")
    set(SDK_BUILD_PATH "${CMAKE_BINARY_DIR}/sdk")
    set(SDK_INSTALL_PATH ${SDK_INSTALL_PATH} PARENT_SCOPE)
    set(SDK_BUILD_PATH ${SDK_BUILD_PATH} PARENT_SCOPE)
    message(STATUS "  >> SDK_INSTALL_PATH: '${SDK_INSTALL_PATH}'")
    message(STATUS "  >> SDK_BUILD_PATH  : '${SDK_BUILD_PATH}'")
    message(STATUS "  >> AMD_TARGET_NAME : '${AMD_TARGET_NAME}'")
    message(STATUS "  >> SOURCE_DIR : '${CMAKE_SOURCE_DIR}'")

    install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/work_bench DESTINATION "${SDK_INSTALL_PATH}/deps" PATTERN "**/src/*" EXCLUDE)
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/external DESTINATION "${SDK_INSTALL_PATH}/deps")
    if(NOT USE_LOCAL_FMT_LIB)
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/3rd_party/fmt DESTINATION "${SDK_INSTALL_PATH}/deps/3rd_party")
    endif()

    if(NOT USE_LOCAL_NLOHMANN_JSON)
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/3rd_party/json DESTINATION "${SDK_INSTALL_PATH}/deps/3rd_party")
    endif()

    #if(NOT USE_LOCAL_BOOST)
    #    install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/3rd_party/boost DESTINATION "${SDK_INSTALL_PATH}/deps/3rd_party")
    #endif()

    if(NOT USE_LOCAL_BOOST_STACKTRACE)
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/3rd_party/stacktrace DESTINATION "${SDK_INSTALL_PATH}/deps/3rd_party")
    endif()

    #if(NOT USE_LOCAL_CLI11) 
    #    install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/3rd_party/CLI11 DESTINATION ${SDK_INSTALL_PATH}/deps/3rd_party)
    #endif()

    install(DIRECTORY ${CMAKE_SOURCE_DIR}/cmake/modules/ DESTINATION "${SDK_INSTALL_PATH}/cmake")
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/cmake/sdk/ DESTINATION "${SDK_INSTALL_PATH}")
    install(FILES ${CMAKE_SOURCE_DIR}/cmake/build_utils.cmake DESTINATION "${SDK_INSTALL_PATH}/cmake")
    install(TARGETS ${AMD_TARGET_LIBNAME} ARCHIVE DESTINATION "${SDK_INSTALL_PATH}/deps")
endfunction()

function(add_include_from_library target_name library_name)
    get_target_property(LIBRARY_INCLUDE_DIRECTORIES ${library_name} INTERFACE_INCLUDE_DIRECTORIES)
    target_include_directories(${target_name} PRIVATE ${LIBRARY_INCLUDE_DIRECTORIES})
endfunction()

function(add_source_definitions target_name definition_text)
    set_property(SOURCE ${target_name} APPEND PROPERTY COMPILE_DEFINITIONS "${definition_text}")
endfunction()

function(adjust_ide_support_target target_name)
    return_is_target_non_adjustable(${target_name})

    get_target_property(target_source_folder ${target_name} SOURCE_DIR)
    if (${target_source_folder} MATCHES "3rd_party")
        return()
    endif()

    # Collect headers
    get_target_property(target_source_folder ${target_name} SOURCE_DIR)
    if (target_source_folder) 
        file(GLOB_RECURSE target_private_headers CONFIGURE_DEPENDS "${target_source_folder}/include/*.hpp")
        target_sources(${target_name} PRIVATE "${target_private_headers}")
    endif()

    # Organize sources
    get_target_property(target_source_files ${target_name} SOURCES)
    foreach(file IN LISTS target_source_files) 
        get_filename_component(file_path ${file} ABSOLUTE)
        if (NOT file_path MATCHES "^${target_source_folder}")
            continue()
        endif()
        source_group(TREE "${target_source_folder}" PREFIX "Source Tree" FILES ${file})
    endforeach()
endfunction()

function(adjust_ide_support_targets)
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)
    _adjust_targets_recursive(${CMAKE_SOURCE_DIR})
endfunction()

function(_adjust_target target folder)
    get_target_property(target_type ${target} TYPE)

    if (${target_type} MATCHES "EXECUTABLE|LIBRARY")
        set_target_properties(${target} PROPERTIES FOLDER "${folder}")
    endif()
endfunction()

function(add_library target_name)
    _add_library(${target_name} ${ARGN})
    adjust_ide_support_target(${target_name})
endfunction()    

function(add_executable target_name)
    _add_executable(${target_name} ${ARGN})
    adjust_ide_support_target(${target_name})
endfunction()    


#
# Note: All macro definitions here
macro(return_is_target_non_adjustable target_name) 
    get_target_property(target_is_aliased ${target_name} ALIASED_TARGET)
    get_target_property(target_is_imported ${target_name} IMPORTED)
    if (target_is_aliased OR target_is_imported)
        return()
    endif() 

    get_target_property(target_type ${target_name} TYPE)
    if(${target_type} MATCHES "INTERFACE_LIBRARY|UNKNOWN_LIBRARY")
        return()
    endif()
endmacro()

macro(_adjust_targets_recursive folder)
    get_property(subfolders DIRECTORY ${folder} PROPERTY SUBDIRECTORIES)
    foreach(subfolder IN LISTS subfolders)
        _adjust_targets_recursive(${subfolder})
    endforeach()

    if (${folder} STREQUAL ${CMAKE_SOURCE_DIR})
        return()
    endif()

    get_property(targets DIRECTORY ${folder} PROPERTY BUILDSYSTEM_TARGETS)
    file(RELATIVE_PATH relative_folder ${CMAKE_SOURCE_DIR} "${folder}/..")
    foreach(target ${targets})
        _adjust_target(${target} "${relative_folder}")
    endforeach()
endmacro()


macro(set_variable_in_parent variable value)
    get_directory_property(has_parent PARENT_DIRECTORY)

    if(has_parent)
        set(${variable} "${value}" PARENT_SCOPE)
    else()
        set(${variable} "${value}")
    endif()
endmacro()

macro(setup_cmake target_name target_version)
    message(STATUS ">> Building ${${target_name}} v${${target_version}} ...")
    set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "Set position independent code for all targets ..." FORCE)
    message(STATUS ">> Configuring CMake to use the following build tools...")

    #
    find_program(CCACHE_PATH ccache)
    find_program(NINJA_PATH ninja)
    find_program(LD_LLD_PATH ld.lld)
    find_program(LD_MOLD_PATH ld.mold)

    if(CCACHE_PATH)
        set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_PATH})
        set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PATH})
    else()
        message(WARNING ">> CCache was not found!")
    endif()

    if(NINJA_PATH)
        set(CMAKE_GENERATOR Ninja)
    else()
        message(WARNING ">> Ninja was not found! Using default generator.")
    endif()

    # Lets give priority to MOLD linker
    set(AMD_WORK_BENCH_LINKER_OPTION "")
    if(LD_MOLD_PATH AND AMD_APP_LINKER_TRY_MOLD)
        set(CMAKE_LINKER ${LD_MOLD_PATH})
        set(AMD_WORK_BENCH_LINKER_OPTION "-fuse-ld=mold")
    # Then LLD linker
    elseif(LD_LLD_PATH)
        set(CMAKE_LINKER ${LD_LLD_PATH})
        set(AMD_WORK_BENCH_LINKER_OPTION "-fuse-ld=lld")
    else()
        message(WARNING ">> LLD linker was not found! Using default linker.")
    endif()

    if(LD_MOLD_PATH OR LD_LLD_PATH AND AMD_WORK_BENCH_LINKER_OPTION)
        set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} ${AMD_WORK_BENCH_LINKER_OPTION})
        set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} ${AMD_WORK_BENCH_LINKER_OPTION})
        message(STATUS ">> Using linker: ${CMAKE_LINKER} with option: ${AMD_WORK_BENCH_LINKER_OPTION}")
    endif()
      

    # CMake policies for the project
    foreach(_policy
        CMP0028 CMP0046 CMP0048 CMP0051 CMP0054
        CMP0056 CMP0063 CMP0065 CMP0074 CMP0075
        CMP0077 CMP0082 CMP0093 CMP0127 CMP0135)
        if(POLICY ${_policy})
            cmake_policy(SET ${_policy} NEW)
        endif()
    endforeach()

    set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "Disable deprecated warning messages" FORCE)
endmacro()

macro(setup_default_build_options)
    # Linux Compiler options
    # Allow compiler flags to inherit any set by env
    if((CMAKE_CXX_COMPILER_ID MATCHES "Clang") OR(CMAKE_CXX_COMPILER_ID MATCHES "GNU"))
        # Options common for both compilers
        # add_compile_options(-Wall)

        # Specific for each compiler
        if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
            set(DEFAULT_BUILD_TYPE "Debug")
            message(WARNING ">> No build type was specified. Setting build to default type: ${DEFAULT_BUILD_TYPE} ...")
            set(CMAKE_BUILD_TYPE "${DEFAULT_BUILD_TYPE}" CACHE STRING "Type of build." FORCE)
            set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${DEFAULT_BUILD_TYPE})
        endif()

        string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE)
        set(AMD_TARGET_VERSION_TEXT ${AMD_TARGET_VERSION})

        if("${CMAKE_BUILD_TYPE}" STREQUAL "release")
            add_compile_definitions(NDEBUG)
        elseif("${CMAKE_BUILD_TYPE}" STREQUAL "debug")
            set(AMD_TARGET_VERSION_TEXT "${AMD_TARGET_VERSION_TEXT}-${CMAKE_BUILD_TYPE}")
            add_compile_definitions(DEBUG)
        endif()

    else()
        message(FATAL_ERROR ">> Compiler not supported!")
    endif()
endmacro()

macro(check_builtin_plugin_set)
    if(NOT AMD_APP_BUILD_PLUGINS)
        return()
    endif()

    file(GLOB PLUGINS_DIRECTORIES "plugins/*")
    if(NOT DEFINED AMD_WORK_BENCH_INCLUDE_PLUGINS)
        foreach(PLUGIN_DIRECTORY ${PLUGINS_DIRECTORIES})
            if(EXISTS ${PLUGIN_DIRECTORY}/CMakeLists.txt)
                get_filename_component(PLUGIN_NAME ${PLUGIN_DIRECTORY} NAME)

                if(NOT(${PLUGIN_NAME} IN_LIST AMD_WORK_BENCH_EXCLUDE_PLUGINS))
                    list(APPEND PLUGINS ${PLUGIN_NAME})
                endif()
            endif()
        endforeach()
    else()
        set(PLUGINS ${AMD_WORK_BENCH_INCLUDE_PLUGINS})
    endif()

    foreach(PLUGIN_NAME ${PLUGINS})
        message(STATUS ">> Enabled builtin plugin: '${PLUGIN_NAME}'")
    endforeach()

    if(NOT PLUGINS)
        message(FATAL_ERROR ">> No builtin plugins found.")
    endif()

    if(NOT("builtin" IN_LIST PLUGINS))
        message(FATAL_ERROR ">> No 'builtin' plugins were found for project: '${AMD_TARGET_NAME}'")
    endif()
endmacro()

macro(check_os_build_definitions)
    if(CMAKE_SYSTEM_NAME MATCHES "Linux")
        add_compile_definitions(OS_LINUX)
        include(GNUInstallDirs)

        if(AMD_APP_STORE_PLUGINS_IN_SHARE)
            set(PLUGIN_INSTALL_PATH "share/${AMD_TARGET_NAME}/plugins")
        else()
            set(PLUGIN_INSTALL_PATH "${CMAKE_INSTALL_LIBDIR}/${AMD_TARGET_NAME}/plugins")
            add_compile_definitions(SYSTEM_DEFAULT_PLUGIN_INSTALL_PATH="${CMAKE_INSTALL_FULL_LIBDIR}/${AMD_TARGET_NAME}")
        endif()

        set(PLUGIN_BUILTIN_LOOKUP_PATH_ALL_LIST 
        "./plugins" 
        "/opt/rocm/lib/${AMD_TARGET_NAME}"
        "${CMAKE_INSTALL_PREFIX}/lib/${AMD_TARGET_NAME}/plugins"
        "${CMAKE_INSTALL_PREFIX}/share/${AMD_TARGET_NAME}/plugins"
    )
    list(JOIN PLUGIN_BUILTIN_LOOKUP_PATH_ALL_LIST ":" PLUGIN_BUILTIN_LOOKUP_PATH_ALL_STRING)
    set(SYSTEM_PLUGIN_BUILTIN_LOOKUP_PATH_ALL "${PLUGIN_BUILTIN_LOOKUP_PATH_ALL_LIST}")
    add_compile_definitions(SYSTEM_PLUGIN_BUILTIN_LOOKUP_PATH_ALL="${PLUGIN_BUILTIN_LOOKUP_PATH_ALL_STRING}")


    else()
        message(FATAL_ERROR ">> System is not supported!")
    endif()
endmacro()

macro(add_build_definitions)
    if(NOT AMD_TARGET_VERSION)
        message(FATAL_ERROR ">> Project: 'AMD_TARGET_VERSION' was not defined!")
    endif()

    message(STATUS ">> Project: '${PROJECT_NAME}' v${${PROJECT_NAME}_VERSION} ...")
    set (CMAKE_RC_FLAGS "${CMAKE_RC_FLAGS} -DPROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR} 
                                           -DPROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR} 
                                           -DPROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}")

    if(AMD_APP_STATIC_LINK_PLUGINS)
        add_compile_definitions(AMD_APP_STATIC_LINK_PLUGINS)
    endif()

    if (AMD_APP_STANDALONE_BUILD_PACKAGE)
        ## Standalone definition
        add_compile_definitions(AMD_APP_STANDALONE_BUILD_PACKAGE)
    elseif(AMD_APP_ENGINEERING_BUILD_PACKAGE)
        ## Engineering definition
        add_compile_definitions(AMD_APP_ENGINEERING_BUILD_PACKAGE)
    elseif(AMD_APP_ROCM_BUILD_PACKAGE)
        ## ROCm definition
        add_compile_definitions(AMD_APP_ROCM_BUILD_PACKAGE)
    endif()
endmacro()

macro(setup_packaging_options)
    set(TARGET_FS_LIBRARY_PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE
        GROUP_READ GROUP_EXECUTE
        WORLD_READ WORLD_EXECUTE)
        
    set(TARGET_FS_EXECUTABLE_PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE
        GROUP_READ GROUP_WRITE GROUP_EXECUTE
        WORLD_READ WORLD_EXECUTE)        
endmacro()

macro(setup_install_target)
    if(NOT TARGET uninstall)
        configure_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in
            ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
            IMMEDIATE @ONLY)
        add_custom_target(uninstall
            COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
    endif()
endmacro()

macro(add_bundled_libraries)
    set(EXTERNAL_LIBRARIES_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/external")
    set(3RD_PARTY_LIBRARIES_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/3rd_party")

    set(BUILD_SHARED_LIBS OFF)

    # add_subdirectory(${EXTERNAL_LIBRARIES_DIRECTORY}/DynLibMgmt EXCLUDE_FROM_ALL)
    # add_subdirectory(${EXTERNAL_LIBRARIES_DIRECTORY}/XYZ EXCLUDE_FROM_ALL)
    # add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/XYZ EXCLUDE_FROM_ALL)
    # set(EXTERNAL_XYZ_INCLUDE_DIRECTORIES "${EXTERNAL_LIBRARIES_DIRECTORY}/xyz")
    # set(3RD_PARTY_XYZ_INCLUDE_DIRECTORIES "${3RD_PARTY_LIBRARIES_DIRECTORY}/xyz")
    # FindPackageHandleStandardArgs name mismatched
    set(FPHSA_NAME_MISMATCHED ON CACHE BOOL "")

    ## TODO: It fails and needs to be fixed
    find_package(CURL REQUIRED)
    if(NOT USE_LOCAL_FMT_LIB)
        add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/fmt EXCLUDE_FROM_ALL)
        set(FMT_LIBRARIES fmt::fmt-header-only)
    else()
        find_package(fmt REQUIRED)
        set(FMT_LIBRARIES fmt::fmt)
    endif()

    #if(NOT USE_LOCAL_BOOST_STACKTRACE)
    #    add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/stacktrace EXCLUDE_FROM_ALL)
    #    set(BOOST_STACKTRACE_LIBRARIES Boost::stacktrace)
    #else()
    #    find_package(Boost REQUIRED COMPONENTS stacktrace)
    #    set(BOOST_STACKTRACE_LIBRARIES Boost::stacktrace)
    #endif()

    if(NOT USE_LOCAL_NLOHMANN_JSON)
        add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/json EXCLUDE_FROM_ALL)
        set(NLOHMANN_JSON_LIBRARIES nlohmann_json)
    else()
        find_package(nlohmann_json 3.11.0 REQUIRED)
        set(NLOHMANN_JSON_LIBRARIES nlohmann_json::nlohmann_json)
    endif()

    if(NOT USE_LOCAL_SPDLOG)
        add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/spdlog EXCLUDE_FROM_ALL)
        set(SPDLOG_LIBRARIES spdlog::spdlog_header_only)
    else()
        find_package(spdlog REQUIRED)
        set(SPDLOG_LIBRARIES spdlog::spdlog)
    endif()

    if(NOT USE_LOCAL_JTHREAD)
        add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/jthread EXCLUDE_FROM_ALL)
        set(JTHREAD_LIBRARIES jthread)
    else()
        find_path(JOSUTTIS_JTHREAD_INCLUDE_DIRS "condition_variable_any2.hpp")
        include_directories(${JOSUTTIS_JTHREAD_INCLUDE_DIRS})
        add_library(jthread INTERFACE)
        target_include_directories(jthread INTERFACE ${JOSUTTIS_JTHREAD_INCLUDE_DIRS})
        set(JTHREAD_LIBRARIES jthread)
    endif()


    # Note: We will not use the boost.parse_args library for now.
    # if(NOT USE_LOCAL_BOOST)
    # add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/boost ${CMAKE_CURRENT_BINARY_DIR}/boost EXCLUDE_FROM_ALL)
    # set(BOOST_LIBRARIES boost::regex)
    # else()
    # find_package(boost REQUIRED)
    # set(BOOST_LIBRARIES boost::regex)
    # endif()
    if(NOT AMD_APP_DISABLE_STACKTRACE)
        find_package(Backtrace)

        if(${Backtrace_FOUND})
            message(STATUS ">> Backtrace enabled! Header file: ${Backtrace_HEADER}")
            set(BACKTRACE_LIBRARIES ${Backtrace_LIBRARY})
            set(BACKTRACE_INCLUDE_DIRECTORIES ${Backtrace_INCLUDE_DIR})
            add_compile_definitions(BACKTRACE_HEADER=<${Backtrace_HEADER}>)

            if(Backtrace_HEADER STREQUAL "backtrace.h")
                add_compile_definitions(${AMD_TARGET_NAME}_BACKTRACE)
            elseif(Backtrace_HEADER STREQUAL "execinfo.h")
                add_compile_definitions(${AMD_TARGET_NAME}_EXECINFO)
            endif()
        endif()

        # Note: If we have C++23, besides the '<stacktrace>' include, we also need 
        #       to add 'stdc++_libbacktrace' to link the library.

        #       If/in case we set CPP Standard to 23, but the compiler won't support it, 
        #       we will try to use the '<boost::stacktrace>' header.
        set(STACKTRACE_BOOST_TRY_OPTIONAL TRUE)
        if(CMAKE_CXX_STANDARD GREATER_EQUAL 23)
            message(STATUS ">> C++23 is required to use the '<stacktrace>' header ...")
            has_minimum_compiler_version_for_standard(CMAKE_CXX_STANDARD CMAKE_CXX_COMPILER_ID CMAKE_CXX_COMPILER_VERSION HAS_MINIMUM_COMPILER_VERSION)
            check_default_compiler_requirements(WAS_TRY_CLANG_DEFAULT_COMPILER)
            ## We don't need to link the 'stdc++_libbacktrace' library. It is already in libstdc++ for C++23 and later.
            if(WAS_TRY_CLANG_DEFAULT_COMPILER)
                message(STATUS ">> COMPILER_TRY_CLANG=ON: C++ 23 Minimum requirements met. ...")
            elseif(HAS_MINIMUM_COMPILER_VERSION)
                message(WARNING ">> C++23 minimum requirements for 'backtrace' were met. Linking against 'stdc++_libbacktrace' ...")
                set(BACKTRACE_LIBRARIES ${BACKTRACE_LIBRARIES} "stdc++_libbacktrace")
            endif()
            if(WAS_TRY_CLANG_DEFAULT_COMPILER OR HAS_MINIMUM_COMPILER_VERSION)
                set(STACKTRACE_BOOST_TRY_OPTIONAL FALSE)
            endif()
        endif()

        #    If the compiler does not support C++23, we will try to use the '<boost::stacktrace>' header.
        if(STACKTRACE_BOOST_TRY_OPTIONAL)
            message(WARNING ">> C++23 requirements were not met. Std: ${CMAKE_CXX_STANDARD}, Compiler: ${CMAKE_CXX_COMPILER_ID}, v: ${CMAKE_CXX_COMPILER_VERSION}")
            find_package(Boost QUIET COMPONENTS stacktrace)
            if(Boost_FOUND AND TARGET Boost::stacktrace)
                message(WARNING ">> Will try the option: '<boost::stacktrace>' header.")
                set(BACKTRACE_LIBRARIES ${BACKTRACE_LIBRARIES} "Boost::stacktrace")
            endif()
        endif()
    endif()
endmacro()

macro(add_plugin_directories)
    set(PLUGIN_MAIN_DIRECTORY "plugins")
    file(MAKE_DIRECTORY ${PLUGIN_MAIN_DIRECTORY})

    foreach(PLUGIN_NAME IN LISTS PLUGINS)
        message(STATUS ">> Adding plugin set: '${PLUGIN_MAIN_DIRECTORY}/${PLUGIN_NAME}'")
        message(STATUS "  >> plugin set target: '${PLUGIN_INSTALL_PATH}'")
        add_subdirectory("${PLUGIN_MAIN_DIRECTORY}/${PLUGIN_NAME}")

        if(TARGET ${PLUGIN_NAME})
            set_target_properties(${PLUGIN_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${PROJECT_MAIN_OUTPUT_DIRECTORY}/${PLUGIN_MAIN_DIRECTORY}")
            set_target_properties(${PLUGIN_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${PROJECT_MAIN_OUTPUT_DIRECTORY}/${PLUGIN_MAIN_DIRECTORY}")

            install(TARGETS ${PLUGIN_NAME} LIBRARY DESTINATION ${PLUGIN_INSTALL_PATH})
            add_dependencies(${AMD_TARGET_NAME}_all ${PLUGIN_NAME})
        endif()
    endforeach()
endmacro()

macro(setup_distribution_package)
    set_target_properties(${AMD_TARGET_LIBNAME} PROPERTIES SOVERSION ${AMD_TARGET_VERSION})
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/dist/package-info.spec.in ${CMAKE_BINARY_DIR}/dist/control)

    # ###TODO: Do we need any downloads? or symlinks?
    # file(CREATE_LINK $symlink_name ${CMAKE_CURRENT_BINARY_DIR}/original_file SYMBOLIC)
    # file(CREATE_LINK rbt ${CMAKE_CURRENT_BINARY_DIR}/rocm-bandwidth-test/scripts/rbt.sh SYMBOLIC)
    # #set(CMAKE_INSTALL_BINDIR "bin")
    install(TARGETS awb_main RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

    # Get string and replace "_", so from 'rocm_bandwidth_test_2025.03.21_amd64.deb' to 
    # 'rocm-bandwidth-test-2025.03.21_amd64.deb'
    set(AMD_TARGET_BUNDLE_BASE_NAME ${AMD_PROJECT_NAME})
    if(AMD_TARGET_BUNDLE_BASE_NAME STREQUAL "")
        set(AMD_TARGET_BUNDLE_BASE_NAME "rocm-bandwidth-test")
    endif()
    string(REPLACE "_" "-" AMD_TARGET_BUNDLE_BASE_NAME "${AMD_TARGET_BUNDLE_BASE_NAME}")

    ## Standard package directives for all package build types
    string(TIMESTAMP CURRENT_BUILD_YEAR "%Y")
    set(AMD_PROJECT_COPYRIGHT_ORGANIZATION "Advanced Micro Devices, Inc. All rights reserved.")
    set(AMD_PROJECT_COPYRIGHT_NOTE "Copyright (c) ${CURRENT_BUILD_YEAR} ${AMD_PROJECT_COPYRIGHT_ORGANIZATION}")
    ## Copyright © 2024 Advanced Micro Devices, Inc. All rights reserved.
    set(CPACK_PACKAGE_VENDOR ${AMD_PROJECT_AUTHOR_ORGANIZATION})
    set(CPACK_PACKAGE_VERSION_MAJOR ${AMD_PROJECT_VERSION_MAJOR})
    set(CPACK_PACKAGE_VERSION_MINOR ${AMD_PROJECT_VERSION_MINOR})
    set(CPACK_PACKAGE_VERSION_PATCH ${AMD_PROJECT_VERSION_PATCH})
    set(CPACK_PACKAGE_CONTACT ${AMD_PROJECT_AUTHOR_MAINTAINER})
    # Prepare final version for the CPACK use
    set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
    ##string(APPEND AMD_TARGET_BUNDLE_BASE_NAME "-${AMD_TARGET_VERSION}") 
    set(CPACK_PACKAGE_NAME ${AMD_TARGET_BUNDLE_BASE_NAME})

    # Debian package specific variables
    set(CPACK_DEBIAN_PACKAGE_HOMEPAGE ${AMD_PROJECT_GITHUB_REPO})
    set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")
    # RPM package specific variables
    set(CPACK_RPM_FILE_NAME "RPM-DEFAULT")
    set(CPACK_RPM_PACKAGE_LICENSE "MIT")
    set(CPACK_GENERATOR "DEB;RPM")

    ## Set the package types
    if(AMD_APP_STANDALONE_BUILD_PACKAGE)
        ## Standalone build package
        set(AMD_TARGET_POST_BUILD_ENV "${CMAKE_BINARY_DIR}/post_build_utils_env.cmake") 
        file(WRITE ${AMD_TARGET_POST_BUILD_ENV} "" "
            set(AMD_TARGET_PROJECT_BASE \"${CMAKE_CURRENT_SOURCE_DIR}\")
            set(AMD_TARGET_INSTALL_PREFIX \"${CMAKE_INSTALL_PREFIX}\")
            set(AMD_TARGET_INSTALL_FLAG_TYPE \"STANDALONE_BUILD_PACKAGE\")
            set(AMD_TARGET_NAME \"${AMD_TARGET_NAME}\")
            set(AMD_TARGET_INSTALL_TYPE \"TARGET\")
            set(AMD_TARGET_INSTALL TRUE)
            set(AMD_TARGET_INSTALL_DIRECTORY \"\")
            set(AMD_TARGET_INSTALL_PERMISSIONS \"\")
            set(AMD_TARGET_INSTALL_STAGING \"${CMAKE_BINARY_DIR}/staging\")
        ")
        ## Packaging directives (standalone build)
        set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Utility tool for benchmarking device performance")

    elseif(AMD_APP_ENGINEERING_BUILD_PACKAGE)
        ## Engineering build package
        set(AMD_TARGET_POST_BUILD_ENV "${CMAKE_BINARY_DIR}/post_build_utils_env.cmake")
        file(WRITE ${AMD_TARGET_POST_BUILD_ENV} "" "
            set(AMD_TARGET_PROJECT_BASE \"${CMAKE_CURRENT_SOURCE_DIR}\")
            set(AMD_TARGET_INSTALL_PREFIX \"${CMAKE_INSTALL_PREFIX}\")
            set(AMD_TARGET_INSTALL_FLAG_TYPE \"ENGINEERING_BUILD_PACKAGE\")
            set(AMD_TARGET_NAME \"${AMD_TARGET_NAME}\")
            set(AMD_TARGET_INSTALL_TYPE \"TARGET\")
            set(AMD_TARGET_INSTALL TRUE)
            set(AMD_TARGET_INSTALL_DIRECTORY \"engineering_build\")
            set(AMD_TARGET_INSTALL_PERMISSIONS \"\")
            set(AMD_TARGET_INSTALL_STAGING \"${CMAKE_BINARY_DIR}/staging\")
        ")
    elseif(AMD_APP_ROCM_BUILD_PACKAGE)
        ## ROCm build package
        set(AMD_TARGET_POST_BUILD_ENV "${CMAKE_BINARY_DIR}/post_build_utils_env.cmake")
        file(WRITE ${AMD_TARGET_POST_BUILD_ENV} "" "
            set(AMD_TARGET_PROJECT_BASE \"${CMAKE_CURRENT_SOURCE_DIR}\")
            set(AMD_TARGET_INSTALL_PREFIX \"${CMAKE_INSTALL_PREFIX}\")
            set(AMD_TARGET_INSTALL_FLAG_TYPE \"ROCM_BUILD_PACKAGE\")
            set(AMD_TARGET_NAME \"${AMD_TARGET_NAME}\")
            set(AMD_TARGET_INSTALL_TYPE \"TARGET\")
            set(AMD_TARGET_INSTALL TRUE)
            set(AMD_TARGET_INSTALL_DIRECTORY \"\")
            set(AMD_TARGET_INSTALL_PERMISSIONS \"\")
            set(AMD_TARGET_INSTALL_STAGING \"${CMAKE_BINARY_DIR}/staging\")
        ")
        ## Package directives (ROCm build)
        ## Make proper version for appending
        ## Default Value is 99999, setting it first
        set(ROCM_VERSION_FOR_PACKAGE "99999")
        if(DEFINED ENV{ROCM_LIBPATCH_VERSION})
            set(ROCM_VERSION_FOR_PACKAGE $ENV{ROCM_LIBPATCH_VERSION})
        endif()
        set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION}-${ROCM_VERSION_FOR_PACKAGE}")
        set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "ROCm utility tool for benchmarking device performance")

        ## Debian package specific variables
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "libstdc++6, hsa-rocr")
        if (DEFINED ENV{CPACK_DEBIAN_PACKAGE_RELEASE})
            set(CPACK_DEBIAN_PACKAGE_RELEASE $ENV{CPACK_DEBIAN_PACKAGE_RELEASE})
        else()
            set(CPACK_DEBIAN_PACKAGE_RELEASE "local")
        endif()

        #
        ## RPM package specific variables
        set(CPACK_RPM_PACKAGE_REQUIRES "hsa-rocr")
        if(DEFINED CPACK_PACKAGING_INSTALL_PREFIX)
            set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION "${CPACK_PACKAGING_INSTALL_PREFIX} ${CPACK_PACKAGING_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}")
        endif()

        if(DEFINED ENV{CPACK_RPM_PACKAGE_RELEASE})
            set(CPACK_RPM_PACKAGE_RELEASE $ENV{CPACK_RPM_PACKAGE_RELEASE})
        else()
            set(CPACK_RPM_PACKAGE_RELEASE "local")
        endif()
        
        #
        ## Set rpm distro
        if(CPACK_RPM_PACKAGE_RELEASE)
            set(CPACK_RPM_PACKAGE_RELEASE_DIST ON)
        endif()

    else()
        message(FATAL_ERROR ">> No distribution package type was not defined!")
    endif()

    
endmacro()

macro(setup_compiler_init_flags)
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag(-ftrivial-auto-var-init=zero HAS_TRIVIAL_AUTO_VAR_INIT_COMPILER)

    if(NOT COMPILER_INIT_FLAG)
        if(HAS_TRIVIAL_AUTO_VAR_INIT_COMPILER)
            message(STATUS ">> Compiler supports -ftrivial-auto-var-init")
            set(COMPILER_INIT_FLAG "-ftrivial-auto-var-init=zero" CACHE STRING "Using cache trivially-copyable automatic variable initialization.")
        else()
            message(STATUS ">> Compiler does not support -ftrivial-auto-var-init")
            set(COMPILER_INIT_FLAG " " CACHE STRING "Using cache trivially-copyable automatic variable initialization.")
        endif()
    endif()

    ##  Initialize automatic variables with either a pattern or with zeroes to increase program security by preventing
    ##  uninitialized memory disclosure and use. '-ftrivial-auto-var-init=[uninitialized|pattern|zero]' where
    ##  'uninitialized' is the default, 'pattern' initializes variables with a pattern, and 'zero' initializes variables
    ##  with zeroes.
    set(AMD_WORK_BENCH_COMMON_FLAGS "${AMD_WORK_BENCH_COMMON_FLAGS} ${COMPILER_INIT_FLAG}")
endmacro()

macro(setup_compression_flags)
    include(CheckCXXCompilerFlag)
    include(CheckLinkerFlag)
    check_cxx_compiler_flag(-gz=zstd ZSTD_AVAILABLE_COMPILER)
    check_linker_flag(CXX -gz=zstd ZSTD_AVAILABLE_LINKER)
    check_cxx_compiler_flag(-gz COMPRESS_AVAILABLE_COMPILER)
    check_linker_flag(CXX -gz COMPRESS_AVAILABLE_LINKER)

    # From cache
    if(NOT DEBUG_COMPRESSION_FLAG)
        if(ZSTD_AVAILABLE_COMPILER AND ZSTD_AVAILABLE_LINKER)
            message(STATUS ">> Compiler and Linker support ZSTD... using it.")
            set(DEBUG_COMPRESSION_FLAG "-gz=zstd" CACHE STRING "Using cache for debug info compression.")
        elseif(COMPRESS_AVAILABLE_COMPILER AND COMPRESS_AVAILABLE_LINKER)
            message(STATUS ">> Compiler and Linker support default compression... using it.")
            set(DEBUG_COMPRESSION_FLAG "-gz" CACHE STRING "Using cache for debug info compression.")
        endif()
    endif()

    set(AMD_WORK_BENCH_COMMON_FLAGS "${AMD_WORK_BENCH_COMMON_FLAGS} ${DEBUG_COMPRESSION_FLAG}")
endmacro()

macro(setup_compiler_flags target_name)
    # Compiler specific flags
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        if(AMD_APP_TREAT_WARNINGS_AS_ERRORS)
            set(AMD_WORK_BENCH_COMMON_FLAGS "${AMD_WORK_BENCH_COMMON_FLAGS} -Werror -Wextra -Wall -Wpedantic -Wno-unused-variable -Wno-unused-function")
        endif()

        if(CMAKE_SYSTEM_NAME MATCHES "Linux" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU")
            set(AMD_WORK_BENCH_COMMON_FLAGS "${AMD_WORK_BENCH_COMMON_FLAGS} -rdynamic")
        endif()

        ## -fno-omit-frame-pointer -fno-strict-aliasing -fvisibility=hidden -fvisibility-inlines-hidden
        ## -fno-exceptions -fno-rtti -fno-omit-frame-pointer -fno-strict-aliasing -fvisibility=hidden
        ## -fvisibility-inlines-hidden
        set(AMD_WORK_BENCH_C_CXX_FLAGS "-Wno-array-bounds -Wno-deprecated-declarations -Wno-unknown-pragmas")
        set(AMD_WORK_BENCH_CXX_FLAGS "-fexceptions -frtti") 

        if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
            set(AMD_WORK_BENCH_C_CXX_FLAGS "${AMD_WORK_BENCH_C_CXX_FLAGS} -Wno-restrict -Wno-stringop-overread -Wno-stringop-overflow -Wno-dangling-reference") 
        elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            set(AMD_WORK_BENCH_C_CXX_FLAGS "${AMD_WORK_BENCH_C_CXX_FLAGS} -Wno-unknown-warning-option")
        endif()

        if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
            ##  Building with _FORTIFY_SOURCE=3 may impact the size and performance of the code. Since _FORTIFY_SOURCE=2 
            ##  generated only constant sizes, its overhead was negligible. However, _FORTIFY_SOURCE=3 may generate 
            ##  additional code to compute object sizes. These additions may also cause secondary effects, such as register 
            ##  pressure during code generation. Code size tends to increase the size of resultant binaries for the same reason.
            ##
            ##  _FORTIFY_SOURCE=3 has led to significant gains in security mitigation, but it may not be suitable for all
            ##  applications. We need a proper study of performance and code size to understand the magnitude of the impact 
            ##  created by _FORTIFY_SOURCE=3 additional runtime code generation, but the performance, and code size might well 
            ##  be worth the magnitude of the security benefits.
            ##
            set(AMD_WORK_BENCH_COMMON_FLAGS "${AMD_WORK_BENCH_COMMON_FLAGS} -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2")

            ##  Stack canary check for buffer overflow on the stack. 
            ##  Emit extra code to check for buffer overflows, such as stack smashing attacks. This is done by adding a guard 
            ##  variable to functions with vulnerable objects. This includes functions that call alloca, and functions with 
            ##  buffers larger than or equal to 8 bytes.
            ##  Only variables that are actually allocated on the stack are considered, optimized away variables or variables 
            ##  allocated in registers don’t count. 
            ##  'stack-protector-strong' is a stronger version of 'stack-protector', but includes additional functions to be 
            ##  protected — those that have local array definitions, or have references to local frame addresses. Only 
            ##  variables that are actually allocated on the stack are considered, optimized away variables or variables 
            ##  allocated in registers don’t count.
            ##
            set(AMD_WORK_BENCH_COMMON_FLAGS "${AMD_WORK_BENCH_COMMON_FLAGS} -fstack-protector-strong")
        endif()            

        if(AMD_APP_DEBUG_INFO_COMPRESS)
            setup_compression_flags()
        endif()

        ## Compiler initialization flags
        setup_compiler_init_flags()
    endif()

    # CMake specific flags
    set_target_properties(${target_name} PROPERTIES COMPILE_FLAGS "${AMD_WORK_BENCH_COMMON_FLAGS} ${AMD_WORK_BENCH_C_CXX_FLAGS}")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${AMD_WORK_BENCH_COMMON_FLAGS} ${AMD_WORK_BENCH_C_CXX_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${AMD_WORK_BENCH_COMMON_FLAGS} ${AMD_WORK_BENCH_C_CXX_FLAGS} ${AMD_WORK_BENCH_CXX_FLAGS}")
endmacro()

