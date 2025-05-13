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
        elseif(DEFINED ENV{ROCM_INSTALL_PATH})
            message(STATUS "  >> ROCM_INSTALL_PATH is set. ROCm build package enabled and using: '$ENV{ROCM_INSTALL_PATH}'")
            set(ROCM_PATH "$ENV{ROCM_INSTALL_PATH}" CACHE STRING "ROCm install directory")
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
    enable_language(CXX C)
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

    ## Dynamically passed variable (argument), explicitly deref the variable for clarity
    if (${compiler_version} VERSION_LESS ${COMPILER_MINIMUM_VERSION_FOR_FULL_SUPPORT})
        set(${result} FALSE PARENT_SCOPE)
    else()
        set(${result} TRUE PARENT_SCOPE)
    endif()
endfunction()

function(try_clang_default_compiler_requirements compiler_requirement_result)
    ##  Check if we are able to use Lightning (Clang++) as default compiler
    ##  Note:   If this condition is met, we used rocm_clang_toolchain.cmake and the toolchain was already
    ##          checked and set up.
    if(IS_LIGHTNING_CLANG_DEFAULT_COMPILER AND ROCM_CLANG_TOOLCHAIN_USED)
        message(STATUS ">> ROCm 'Lightning Clang++' Toolchain: was already set externally (rocm_clang_toolchain.cmake) ...")
        set(${compiler_requirement_result} TRUE PARENT_SCOPE)
        return()
    endif()

    ##
    set(HAS_DEFAULT_COMPILER_REQUIREMENTS FALSE)
    if(AMD_APP_COMPILER_TRY_CLANG)
        set(CLANG_COMPILER_MAJOR_VERSION_REQUIRED "19")
        set(CLANG_COMPILER_MINOR_VERSION_REQUIRED "0")
        set(CLANG_COMPILER_REVISION_VERSION_REQUIRED "0")
        set(CLANG_COMPILER_MINIMUM_VERSION_REQUIRED "${CLANG_COMPILER_MAJOR_VERSION_REQUIRED}.${CLANG_COMPILER_MINOR_VERSION_REQUIRED}.${CLANG_COMPILER_REVISION_VERSION_REQUIRED}")

        if(DEFINED ENV{ROCM_INSTALL_PATH})
            set(ROCM_INSTALL_LLVM_BIN_PATH "$ENV{ROCM_INSTALL_PATH}/lib/llvm/bin/")
        endif()
        set(ROCM_LLVM_BIN_PATH  "/opt/rocm/lib/llvm/bin/")
        message(WARNING ">> Trying to setup 'Lightning Clang++' as default compiler (COMPILER_TRY_CLANG=ON)")
        message(STATUS "  >> Minimum version required for setting: 'v${CLANG_COMPILER_MINIMUM_VERSION_REQUIRED}'")
        find_program(CLANG_COMPILER_CXX NAMES clang++ clang HINTS ${ROCM_INSTALL_LLVM_BIN_PATH} ${ROCM_LLVM_BIN_PATH} ${CMAKE_CXX_COMPILER_PATH} ${CMAKE_CXX_COMPILER})
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
                set(CLANG_COMPILER_FULL_VERSION "${CLANG_COMPILER_VERSION_MAJOR}.${CLANG_COMPILER_VERSION_MINOR}.${CLANG_COMPILER_VERSION_REVISION}")
                ## 
                if(CLANG_COMPILER_VERSION_MAJOR GREATER_EQUAL ${CLANG_COMPILER_MAJOR_VERSION_REQUIRED} AND 
                   CLANG_COMPILER_VERSION_MINOR GREATER_EQUAL ${CLANG_COMPILER_MINOR_VERSION_REQUIRED})
                    set(CLANG_COMPILER_VERSION_RESULT TRUE)
                else()
                    set(CLANG_COMPILER_VERSION_RESULT FALSE)
                endif()
            endif()
            
            if(NOT CLANG_COMPILER_VERSION_RESULT)
                message(WARNING ">> 'Clang++' compiler v'${CLANG_COMPILER_VERSION}' is not set as default compiler! Minimum version required: 'v${CLANG_COMPILER_MINIMUM_VERSION_REQUIRED}'")
                message(STATUS  "  >> falling back default compiler 'g++' and requirements...")
            else()
                set(HAS_DEFAULT_COMPILER_REQUIREMENTS TRUE)
                get_filename_component(DEFAULT_COMPILER_DIRECTORY_NAME "${CLANG_COMPILER_CXX}" DIRECTORY)
                set(CLANG_COMPILER_C "${DEFAULT_COMPILER_DIRECTORY_NAME}/clang")
                set(CMAKE_CXX_COMPILER "${CLANG_COMPILER_CXX}")
                set(CMAKE_CXX_COMPILER "${CLANG_COMPILER_CXX}" CACHE PATH "C++ Compiler" FORCE PARENT_SCOPE)
                set(CMAKE_C_COMPILER "${CLANG_COMPILER_C}")
                set(CMAKE_C_COMPILER "${CLANG_COMPILER_C}" CACHE PATH "C Compiler" FORCE PARENT_SCOPE)
                message(STATUS "  >> Setting compiler to: '${CLANG_COMPILER_FULL_VERSION}")
            endif()

        else()
            message(FATAL_ERROR ">> 'Clang++' compiler not found (COMPILER_TRY_CLANG=ON)!")
        endif()

        if (HAS_DEFAULT_COMPILER_REQUIREMENTS)
            set(${compiler_requirement_result} TRUE PARENT_SCOPE)
        else()
            set(${compiler_requirement_result} FALSE PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(check_compiler_requirements component_name)
    ##  We need to make sure we have C++ enabled, or we get errors like:
    ##  'check_compiler_flag: CXX: needs to be enabled before use'
    get_property(project_enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
    if(NOT project_enabled_languages OR NOT "CXX" IN_LIST project_enabled_languages)
        enable_language(CXX)
    endif()

    ##  Check if we are able to use Lightning (Clang19++) as default compiler
    if(NOT DEFINED IS_LIGHTNING_CLANG_DEFAULT_COMPILER)
        try_clang_default_compiler_requirements(IS_TRY_CLANG_DEFAULT_COMPILER)
        if(IS_TRY_CLANG_DEFAULT_COMPILER)
            set(IS_LIGHTNING_CLANG_DEFAULT_COMPILER BOOL TRUE)
            set(IS_LIGHTNING_CLANG_DEFAULT_COMPILER BOOL TRUE PARENT_SCOPE)
            message(STATUS ">> COMPILER_TRY_CLANG=ON: Default compiler already set to 'Lightning Clang++' ...")
        else()
        set(IS_LIGHTNING_CLANG_DEFAULT_COMPILER BOOL FALSE)
            set(IS_LIGHTNING_CLANG_DEFAULT_COMPILER BOOL FALSE PARENT_SCOPE)
        endif()
    endif()

    ##  Check if the compiler is compatible with the C++ standard.
    ##  Note:   Minimum required is ${CMAKE_CXX_STANDARD} = 20, but we check for 23, 20, and 17.
    if(NOT DEFINED IS_COMPILER_SUPPORTS_CXX23_STANDARD OR NOT DEFINED IS_COMPILER_SUPPORTS_CXX20_STANDARD OR NOT DEFINED IS_COMPILER_SUPPORTS_CXX17_STANDARD)
        include(CheckCXXCompilerFlag)
        message(STATUS ">> Checking Compiler: '${CMAKE_CXX_COMPILER}' for C++ standard ...")

        ## Just to have independent checks/variables
        set(CHECK_CMAKE_CXX_STANDARD 23)
        if(NOT DEFINED IS_COMPILER_SUPPORTS_CXX23_STANDARD)
            set(IS_COMPILER_SUPPORTS_CHECK "IS_COMPILER_SUPPORTS_CXX${CHECK_CMAKE_CXX_STANDARD}_STANDARD")
            check_cxx_compiler_flag("-std=c++${CHECK_CMAKE_CXX_STANDARD}" COMPILER_SUPPORTS_CXX23_STANDARD)
            if(COMPILER_SUPPORTS_CXX23_STANDARD)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL TRUE)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL TRUE PARENT_SCOPE)
                developer_status_message("DEVEL" " >> Compiler: ${CMAKE_CXX_COMPILER} supports CXX Standard '${CHECK_CMAKE_CXX_STANDARD}' ...")
            else()
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL FALSE)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL FALSE PARENT_SCOPE)
            endif()
        endif()

        set(CHECK_CMAKE_CXX_STANDARD 20)
        if(NOT DEFINED IS_COMPILER_SUPPORTS_CXX20_STANDARD)
            set(IS_COMPILER_SUPPORTS_CHECK "IS_COMPILER_SUPPORTS_CXX${CHECK_CMAKE_CXX_STANDARD}_STANDARD")
            check_cxx_compiler_flag("-std=c++${CHECK_CMAKE_CXX_STANDARD}" COMPILER_SUPPORTS_CXX20_STANDARD)
            if(COMPILER_SUPPORTS_CXX20_STANDARD)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL TRUE)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL TRUE PARENT_SCOPE)
                developer_status_message("DEVEL" "  >> Compiler: ${CMAKE_CXX_COMPILER} supports CXX Standard '${CHECK_CMAKE_CXX_STANDARD}' ...")
            else()
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL FALSE)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL FALSE PARENT_SCOPE)
            endif()
        endif()

        set(CHECK_CMAKE_CXX_STANDARD 17)
        if(NOT DEFINED IS_COMPILER_SUPPORTS_CXX17_STANDARD)
            set(IS_COMPILER_SUPPORTS_CHECK "IS_COMPILER_SUPPORTS_CXX${CHECK_CMAKE_CXX_STANDARD}_STANDARD")
            check_cxx_compiler_flag("-std=c++${CHECK_CMAKE_CXX_STANDARD}" COMPILER_SUPPORTS_CXX17_STANDARD)
            if(COMPILER_SUPPORTS_CXX17_STANDARD)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL TRUE)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL TRUE PARENT_SCOPE)
                developer_status_message("DEVEL" "  >> Compiler: ${CMAKE_CXX_COMPILER} supports CXX Standard '${CHECK_CMAKE_CXX_STANDARD}' ...")
            else()
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL FALSE)
                set(${IS_COMPILER_SUPPORTS_CHECK} BOOL FALSE PARENT_SCOPE)
            endif()
        endif()
    endif()

    ## Does it support the project C++ standard, ${CMAKE_CXX_STANDARD} = 20?
    set(IS_COMPILER_SUPPORTS_MIN_STANDARD "${IS_COMPILER_SUPPORTS_CXX${CMAKE_CXX_STANDARD}_STANDARD}")
    if(NOT IS_COMPILER_SUPPORTS_MIN_STANDARD)
        message(FATAL_ERROR ">> Compiler: '${CMAKE_CXX_COMPILER}' v'${CMAKE_CXX_COMPILER_VERSION}' doesn't support CXX Standard '${CMAKE_CXX_STANDARD}'! \n"
                             "  >> Project: '${${component_name}}' can't be built ...")
    else()
        message(STATUS ">> Compiler: '${CMAKE_CXX_COMPILER}' v'${CMAKE_CXX_COMPILER_VERSION}' supports the required CXX Standard '${CMAKE_CXX_STANDARD}' ...")
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

    if(NOT USE_LOCAL_BOOST)
        install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/3rd_party/boost DESTINATION "${SDK_INSTALL_PATH}/deps/3rd_party")
    endif()

    #if(NOT USE_LOCAL_BOOST_STACKTRACE)
    #    install(DIRECTORY ${CMAKE_SOURCE_DIR}/deps/3rd_party/boost/libs/stacktrace DESTINATION "${SDK_INSTALL_PATH}/deps/3rd_party")
    #endif()

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

function(verify_dependency_support module_name module_path commit_hash)
    message(STATUS ">> Verifying submodule state: '${module_name}' ...")
    set(MODULE_ABSOLUTE_PATH "")
    if(IS_ABSOLUTE "${module_path}")
        set(MODULE_ABSOLUTE_PATH "${module_path}")
    else()
        set(MODULE_ABSOLUTE_PATH "${CMAKE_SOURCE_DIR}/${module_path}")
    endif()

    message(STATUS ">> Submodule path: [${module_path}] '${MODULE_ABSOLUTE_PATH}' ...")
    if(NOT EXISTS "${MODULE_ABSOLUTE_PATH}/.git")
        message(FATAL_ERROR ">> Submodule directory seems invalid; Missing '.git' directory. : '${module_name}' at: '${MODULE_ABSOLUTE_PATH}' ...")
    elseif(NOT EXISTS "${MODULE_ABSOLUTE_PATH}/CMakeLists.txt")
        message(FATAL_ERROR ">> Submodule directory '${module_name}' found at: '${MODULE_ABSOLUTE_PATH}', without a 'CMakeLists.txt' ...")
    else()
        message(STATUS ">> Submodule directory '${module_name}' and 'CMakeLists.txt' found at: ${MODULE_ABSOLUTE_PATH}")
        message(STATUS "  >> Verifying commit/tag against required reference: '${module_name}' : '${commit_hash}' ...")

        ##  Get the commit hash even for tags
        ##  Run from top-level where .gitmodules file exists
        execute_process(
          COMMAND ${CMAKE_GIT_EXECUTABLE} rev-parse "${commit_hash}^{commit}"
          WORKING_DIRECTORY "${MODULE_ABSOLUTE_PATH}"
          OUTPUT_VARIABLE OUTPUT_EXPECTED_HASH
          OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_QUIET
          RESULT_VARIABLE RESULT_GIT_RESOLVE
        )
        if(NOT RESULT_GIT_RESOLVE EQUAL 0)
            message(FATAL_ERROR ">> Could not resolve required Git reference: '${module_name}' : '${commit_hash}' ...")
        endif()
        message(STATUS ">> Required Git reference: '${module_name}' : '${commit_hash}' resolves to commit: '${OUTPUT_EXPECTED_HASH}'")

        ##  Get the current commit hash in the submodule directory
        execute_process(
          COMMAND ${CMAKE_GIT_EXECUTABLE} rev-parse HEAD
          WORKING_DIRECTORY "${MODULE_ABSOLUTE_PATH}"
          OUTPUT_VARIABLE OUTPUT_CURRENT_HASH
          OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_QUIET
          RESULT_VARIABLE RESULT_GIT_CURRENT
        )
        if(NOT RESULT_GIT_CURRENT EQUAL 0)
            message(FATAL_ERROR ">> Could not determine current Git commit hash in submodule directory: '${module_name}' at: '${MODULE_ABSOLUTE_PATH}'.")
        endif()
        message(STATUS "Submodule '${module_name}' is currently at commit: ${OUTPUT_CURRENT_HASH}")

        ##  Compare the hashes
        if(NOT "${OUTPUT_CURRENT_HASH}" STREQUAL "${OUTPUT_EXPECTED_HASH}")
            ##  Hashes DO NOT MATCH
            set(MSG_PREFIX ">> Submodule '${module_name}' at '${MODULE_ABSOLUTE_PATH}' is at the wrong commit: ('${OUTPUT_CURRENT_HASH}'). \n")
            #   NOTE:   'attempt auto checkout'
            if(AMD_APP_SUBMODULES_TRY_CHECKOUT)
                message(STATUS ">> Trying to 'checkout' the submodule '${module_name}' reference: '${OUTPUT_EXPECTED_HASH}' at: '${MODULE_ABSOLUTE_PATH}' ...")

                execute_process(
                  COMMAND ${CMAKE_GIT_EXECUTABLE} checkout "${commit_hash}"
                  WORKING_DIRECTORY "${MODULE_ABSOLUTE_PATH}"
                  RESULT_VARIABLE RESULT_GIT_CHECKOUT
                  ERROR_VARIABLE ERROR_GIT_CHECKOUT
                  OUTPUT_QUIET
                  ERROR_STRIP_TRAILING_WHITESPACE
                )
                if(NOT RESULT_GIT_CHECKOUT EQUAL 0)
                    message(FATAL_ERROR ">> Could not 'checkout' the submodule '${module_name}' reference: '${commit_hash}'. Error: '${ERROR_GIT_CHECKOUT}'")
                else()
                    ##  Note:   Most repos won't have a submodules, but if they do, we need to update the submodules
                    ##          so they all match with the parent commit hash
                    ##  Get the current commit hash in the submodule directory
                    execute_process(
                        COMMAND ${CMAKE_GIT_EXECUTABLE} submodule update --force --init --recursive
                        WORKING_DIRECTORY "${MODULE_ABSOLUTE_PATH}"
                        RESULT_VARIABLE RESULT_GIT_SUBMODULE_UPDATE
                        ERROR_VARIABLE ERROR_GIT_SUBMODULE_UPDATE
                        OUTPUT_QUIET
                        ERROR_STRIP_TRAILING_WHITESPACE
                    )
                    message(STATUS ">> Submodule '${module_name}' reference '${commit_hash}' successfully checked out. \n")

                    ##  Re-run the script to verify the commit hash, just in case
                    ##  Get the current commit hash in the submodule directory
                    execute_process(
                        COMMAND ${CMAKE_GIT_EXECUTABLE} rev-parse HEAD
                        WORKING_DIRECTORY "${MODULE_ABSOLUTE_PATH}"
                        OUTPUT_VARIABLE OUTPUT_NEW_CHECKED_HASH
                        OUTPUT_STRIP_TRAILING_WHITESPACE
                        ERROR_QUIET
                        RESULT_VARIABLE RESULT_GIT_NEW_CHECKOUT
                    )
                    if(NOT RESULT_GIT_NEW_CHECKOUT EQUAL 0 OR NOT "${OUTPUT_NEW_CHECKED_HASH}" STREQUAL "${OUTPUT_EXPECTED_HASH}")
                        message(FATAL_ERROR ">> Submodule '${module_name}' still not at required commit '${OUTPUT_EXPECTED_HASH}' after rechecking it. \n"
                                            "  >> Current commit is: '${OUTPUT_NEW_CHECKED_HASH}' ...")
                    endif()
                    message(STATUS ">> Submodule '${module_name}' is now at the required commit: '${OUTPUT_NEW_CHECKED_HASH}' [auto-checked out] ...")
                endif()
            else()
                message(FATAL_ERROR "${MSG_PREFIX} \n"
                                    "  >> The required reference is: '${commit_hash}', and it needs to be 'checkout' manually. \n")
            endif()
        else()
            #   Hashes MATCH
            message(STATUS ">> Submodule '${module_name}' commit matches required reference: '${commit_hash}' ...")
        endif()

        ##  Checks/add module subdirectory if all checks pass
        ##  Create a unique binary dir based on module name to avoid conflicts using a sanitized name
        #string(MAKE_C_IDENTIFIER "${module_name}" MODULE_NAME_C_ID)
        #set(SUBMODULE_BINARY_DIR "${CMAKE_BINARY_DIR}/${MODULE_NAME_C_ID}_external")
        #add_subdirectory("${MODULE_ABSOLUTE_PATH}" "${SUBMODULE_BINARY_DIR}")
        set(${module_name}_MODULE_ADDED TRUE PARENT_SCOPE)
        message(STATUS ">> Adding submodule subdirectory: '${module_name}' at: '${MODULE_ABSOLUTE_PATH}' ...")
        message(STATUS ">> Submodule '${module_name}' successfully added ...")
    endif()
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

    # Check if the compiler is compatible with the C++ standard.
    if(NOT DEFINED IS_LIGHTNING_CLANG_DEFAULT_COMPILER)
        check_compiler_requirements(${target_name})
    endif()

    #
    find_program(CCACHE_PATH ccache)
    find_program(NINJA_PATH ninja)
    find_program(LD_LLD_PATH ld.lld)
    find_program(LD_MOLD_PATH ld.mold)

    if(NOT AMD_APP_COMPILER_TRY_CLANG AND NOT IS_LIGHTNING_CLANG_DEFAULT_COMPILER)
        if(CCACHE_PATH)
            set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_PATH})
            set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PATH})
        else()
            message(WARNING ">> CCache was not found!")
        endif()

    #   If we are using 'Lightning Clang', we want to use its standard library,
    #   instead of the default 'gcc' ('-stdlib=libstdc++')
    #   Note:   Likely libraries using 'pthread' will fail with:
    #           CMAKE_HAVE_LIBC_PTHREAD - Failed
    #           Check if compiler accepts -pthread - no
    #           Could NOT find Threads
    #elseif(IS_LIGHTNING_CLANG_DEFAULT_COMPILER AND ROCM_CLANG_TOOLCHAIN_USED)
    #    set(AMD_WORK_BENCH_CXX_FLAGS "-stdlib=libc++")
    #    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${AMD_WORK_BENCH_CXX_FLAGS}")
    #    message(STATUS ">> Using compiler: ${CMAKE_CXX_COMPILER} with option: ${AMD_WORK_BENCH_CXX_FLAGS}")
    endif()

    if(NINJA_PATH)
        set(CMAKE_GENERATOR Ninja)
    else()
        message(WARNING ">> Ninja was not found! Using default generator.")
    endif()

    # Lets give priority to MOLD linker
    set(AMD_WORK_BENCH_LINKER_OPTION "")
    if(LD_MOLD_PATH AND AMD_APP_LINKER_TRY_MOLD)
        set(CMAKE_LINKER ${LD_MOLD_PATH} CACHE STRING "Linker to use: ${LD_MOLD_PATH}")
        set(AMD_WORK_BENCH_LINKER_OPTION "-fuse-ld=mold")
    # Then LLD linker
    elseif(LD_LLD_PATH)
        set(CMAKE_LINKER ${LD_LLD_PATH} CACHE STRING "Linker to use: ${LD_LLD_PATH}")
        set(AMD_WORK_BENCH_LINKER_OPTION "-fuse-ld=lld")
    else()
        message(WARNING ">> LLD linker was not found! Using default 'Gold' linker.")
    endif()

    if(LD_MOLD_PATH OR LD_LLD_PATH AND AMD_WORK_BENCH_LINKER_OPTION)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${AMD_WORK_BENCH_LINKER_OPTION}")
        #set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} ${AMD_WORK_BENCH_LINKER_OPTION})
        #set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} ${AMD_WORK_BENCH_LINKER_OPTION})
        message(STATUS ">> Using linker: '${CMAKE_LINKER}' with options: '${AMD_WORK_BENCH_LINKER_OPTION}'")
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
    #
    ##  Note:   Try to use the local (system) dependencies by default
    ##          If local (system) is not set, we use the bundled libraries
    if (NOT DEFINED USE_LOCAL_FMT_LIB)
        set(USE_LOCAL_FMT_LIB OFF CACHE BOOL "Use local fmt library" FORCE)
    endif()

    if (NOT DEFINED USE_LOCAL_NLOHMANN_JSON)
        set(USE_LOCAL_NLOHMANN_JSON OFF CACHE BOOL "Use local json library" FORCE)
    endif()

    if (NOT DEFINED USE_LOCAL_SPDLOG)
        set(USE_LOCAL_SPDLOG OFF CACHE BOOL "Use local spdlog library" FORCE)
    endif()

    if (NOT DEFINED USE_LOCAL_JTHREAD)
        set(USE_LOCAL_JTHREAD OFF CACHE BOOL "Use local jthread library" FORCE)
    endif()

    #   Note:   USE_LOCAL_BOOST goes along with USE_LOCAL_BOOST_STACKTRACE and all USE_LOCAL_BOOST_* options
    if (NOT DEFINED USE_LOCAL_BOOST)
        set(USE_LOCAL_BOOST OFF CACHE BOOL "Use local Boost library" FORCE)
        set(USE_LOCAL_BOOST_STACKTRACE OFF CACHE BOOL "Use local Boost::stacktrace library" FORCE)
        set(USE_LOCAL_BOOST_STACKTRACE_TEST ON CACHE BOOL "Use local Boost::stacktrace library test" FORCE)
    endif()
    if (NOT DEFINED USE_LOCAL_BOOST_STACKTRACE)
        set(USE_LOCAL_BOOST_STACKTRACE OFF CACHE BOOL "Use local Boost::stacktrace library" FORCE)
    endif()

    if (NOT DEFINED USE_LOCAL_CLI11)
        set(USE_LOCAL_CLI11 OFF CACHE BOOL "Use local CLI11 library" FORCE)
    endif()

    ##  Note: If we have C++23, use '<stacktrace>', otherwise '<boost::stacktrace>'
    set(STD_STACKTRACE_CXX_REQUIRED 23)

    ##
    set(EXTERNAL_LIBRARIES_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/external")
    set(3RD_PARTY_LIBRARIES_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/3rd_party")
    set(3RD_PARTY_DEPENDENCY_BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/3rd_party")
    set(3RD_PARTY_DEPENDENCY_BOOST_BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/3rd_party/boost")
    set(3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps/3rd_party/boost/libs")
    set(BUILD_SHARED_LIBS OFF)

    # add_subdirectory(${EXTERNAL_LIBRARIES_DIRECTORY}/dynamic_lib_mgmt EXCLUDE_FROM_ALL)
    # add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/Catch2 EXCLUDE_FROM_ALL)
    # FindPackageHandleStandardArgs name mismatched
    set(FPHSA_NAME_MISMATCHED ON CACHE BOOL "")

    #   Note:   We can check the compiler, and for some libraries we can use the 'stdlibrary'
    #           if they are already avaiable.
    #           IS_LIGHTNING_CLANG_DEFAULT_COMPILER and IS_COMPILER_SUPPORTS_CXX{20}_STANDARD are
    #           is set in the function check_compiler_requirements

    ## (Ubuntu 22.04: 7.81.0)
    find_package(CURL REQUIRED)

    # --- System installed packages don't align with latest versions available in the repo ---
    #   So, we use the latest version we see available in the Linux Distro repo, and the latest
    #   version available in the GitHub repo.
    #
    #   For example (as of 2025-04-23), Ubuntu 22.04:
    #       - libfmt-dev: [std::format is part of C++20]
    #           - pkg version;  9.1.0       : https://github.com/fmtlib/fmt/commit/a33701196adfad74917046096bf5a2aa0ab0bb50
    #           - git version; 11.1.4       : https://github.com/fmtlib/fmt/commit/123913715afeb8a437e6388b4473fcc4753e1c9a
    #       - libcli11-dev:
    #           - pkg version; v2.1.2       : https://github.com/CLIUtils/CLI11/commit/70f8072f9dd2292fd0b9f9e5f58e279f60483ed3
    #           - git version; v2.5.0       : https://github.com/CLIUtils/CLI11/commit/4160d259d961cd393fd8d67590a8c7d210207348
    #       - catch2:
    #           - pkg version; v2.13.8      : https://github.com/catchorg/Catch2/commit/216713a4066b79d9803d374f261ccb30c0fb451f
    #           - git version; v3.8.10      : https://github.com/catchorg/Catch2/commit/2b60af89e23d28eefc081bc930831ee9d45ea58b
    #       - nlohmann-json3-dev:
    #           - pkg version; v3.10.5      : https://github.com/nlohmann/json/commit/4f8fba14066156b73f1189a2b8bd568bde5284c5
    #           - git version; v3.12.0      : https://github.com/nlohmann/json/commit/55f93686c01528224f448c19128836e7df245f72
    #       - jthread: [std::jthread is part of C++20]
    #           - git version; v0.0.0       : https://github.com/josuttis/jthread/commit/0fa8d394254886c555d6faccd0a3de819b7d47f8
    #       - libspdlog-dev:
    #           - pkg version; v1.9.2       : https://github.com/gabime/spdlog/commit/eb3220622e73a4889eee355ffa37972b3cac3df5
    #           - git version; v1.15.2      : https://github.com/gabime/spdlog/commit/48bcf39a661a13be22666ac64db8a7f886f2637e
    #
    #       - libboost-all-dev:
    #           - pkg version; 1.74.0       : https://github.com/boostorg/boost/commit/a7090e8ce184501cfc9e80afa6cafb5bfd3b371c
    #           - git version; boost-1.88.0 : https://github.com/boostorg/boost/commit/199ef13d6034c85232431130142159af3adfce22
    #       - libboost-stacktrace-dev: [std::stacktrace is part of C++23]
    #           - pkg version; v1.74.0      : https://github.com/boostorg/boost/commit/a7090e8ce184501cfc9e80afa6cafb5bfd3b371c
    #           - git version; v1.88.0      : https://github.com/boostorg/stacktrace/tree/d6499f26d471158b6e6f65eea7425200f842b547
    #

    #   Note:   C++20+ we can use the std::format library.
    #           As a few other dependencies (such as spdlog) use fmtlib, we will force/use of it for now.
    #if (NOT IS_COMPILER_SUPPORTS_CXX20_STANDARD)
    set(FMT_PACKAGE_NAME "fmt")
    set(FMT_LIBRARY_NAME "fmt")
    set(FMT_REPO_URL "https://github.com/fmtlib/fmt.git")
    set(FMT_PKG_MINIMUM_REQUIRED_VERSION "9.1.0")
    set(FMT_REPO_COMMIT "123913715afeb8a437e6388b4473fcc4753e1c9a")
    set(FMT_SOURCE_DIR "${3RD_PARTY_LIBRARIES_DIRECTORY}/${FMT_LIBRARY_NAME}")
    if(NOT USE_LOCAL_FMT_LIB)
        verify_dependency_support(${FMT_LIBRARY_NAME} ${FMT_SOURCE_DIR} ${FMT_REPO_COMMIT})
        add_subdirectory(${FMT_SOURCE_DIR} EXCLUDE_FROM_ALL)
        set(FMT_LIBRARIES fmt::fmt-header-only)
    else()
        find_package(${FMT_PACKAGE_NAME} REQUIRED ${FMT_PKG_MINIMUM_REQUIRED_VERSION})
        set(FMT_LIBRARIES fmt::fmt)
    endif()
    #endif()
    #endif()

    #   Note:   C++23+ we can use std::stacktrace for the traces.
    #           Some older compilers/systems will not allow that. We will force/use boost::stacktrace for now.
    #           Check for 'Boost'
    set(BOOST_PACKAGE_NAME "boost")
    set(BOOST_LIBRARY_NAME "boost")
    set(BOOST_REPO_URL "https://github.com/boostorg/boost.git")
    set(BOOST_PKG_MINIMUM_REQUIRED_VERSION "1.74.0")
    set(BOOST_REPO_VERSION "boost-1.88.0")
    set(BOOST_REPO_COMMIT "199ef13d6034c85232431130142159af3adfce22")
    set(BOOST_SOURCE_DIR "${3RD_PARTY_DEPENDENCY_BOOST_BASE_DIRECTORY}")
    if(NOT USE_LOCAL_BOOST)
        set(BOOST_ROOT "${3RD_PARTY_DEPENDENCY_BOOST_BASE_DIRECTORY}" CACHE PATH "Boost library root directory")
        set(Boost_NO_SYSTEM_PATHS TRUE)
        set(Boost_NO_BOOST_CMAKE TRUE)
        #   Note:   Boost::stacktrace requires:
        #           - Boost::Config:
        #               - https://github.com/boostorg/config
        #           - Boost::Core:
        #               - https://github.com/boostorg/core
        verify_dependency_support(${BOOST_LIBRARY_NAME} ${BOOST_SOURCE_DIR} ${BOOST_REPO_VERSION})
        if (${BOOST_LIBRARY_NAME}_MODULE_ADDED)
            ## Check for the additional required Boost modules (used by stacktrace)
            #   Note:   'Boost::stacktrace' is a 'Boost' project submodule'
            set(BOOST_STACKTRACE_PACKAGE_NAME "libboost-stacktrace")
            set(BOOST_STACKTRACE_LIBRARY_NAME "stacktrace")
            set(BOOST_STACKTRACE_REPO_URL "https://github.com/boostorg/stacktrace.git")
            set(BOOST_STACKTRACE_PKG_MINIMUM_REQUIRED_VERSION ${BOOST_REPO_VERSION})
            set(BOOST_STACKTRACE_REPO_COMMIT "d6499f26d471158b6e6f65eea7425200f842b547")
            set(BOOST_STACKTRACE_SOURCE_DIR "${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/${BOOST_STACKTRACE_LIBRARY_NAME}")
            if(NOT USE_LOCAL_BOOST_STACKTRACE)
                # Boost::stacktrace is checked here
                ## verify_dependency_support(${BOOST_STACKTRACE_LIBRARY_NAME} ${BOOST_STACKTRACE_SOURCE_DIR} ${BOOST_STACKTRACE_REPO_COMMIT})
                ## if (${BOOST_STACKTRACE_LIBRARY_NAME}_MODULE_ADDED)
                ## Check for the additional required Boost modules (used by stacktrace)
                set(BOOST_STACKTRACE_DEPENDENCY_LIST config core assert container_hash predef array static_assert type_traits describe throw_exception mp11 winapi)
                foreach(module_name ${BOOST_STACKTRACE_DEPENDENCY_LIST})
                    if(NOT EXISTS "${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/${module_name}")
                        message(FATAL_ERROR ">> Required dependency: '${module_name}' library was not found at: ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/${module_name}")
                    endif()
                endforeach()

                ##  Note:   Add all the additional Boost dependencies for 'stacktrace'
                ##          We are using the 'EXCLUDE_FROM_ALL' option to avoid building all the libraries
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/config EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/assert EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/static_assert EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/type_traits EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/predef EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/array EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/container_hash EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/core EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/describe EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/throw_exception EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/mp11 EXCLUDE_FROM_ALL)
                add_subdirectory(${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/winapi EXCLUDE_FROM_ALL)
                add_subdirectory(${BOOST_STACKTRACE_SOURCE_DIR} EXCLUDE_FROM_ALL)

                set(BOOST_STACKTRACE_INCLUDE_DIRECTORIES ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/config/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/assert/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/static_assert/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/type_traits/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/predef/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/array/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/container_hash/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/core/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/describe/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/throw_exception/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/mp11/include
                    ${3RD_PARTY_DEPENDENCY_BOOST_LIBS_DIRECTORY}/winapi/include
                    ${BOOST_STACKTRACE_SOURCE_DIR}/include)

                set(BOOST_STACKTRACE_LIBRARIES Boost::stacktrace_basic)
                ## endif()
            endif()
        endif()
    else()
        find_package(${BOOST_PACKAGE_NAME} ${BOOST_PKG_MINIMUM_REQUIRED_VERSION} REQUIRED CONFIG COMPONENTS stacktrace_basic)
        set(BOOST_STACKTRACE_LIBRARIES Boost::stacktrace_basic)
    endif()

    set(JSON_PACKAGE_NAME "nlohmann_json")
    set(JSON_LIBRARY_NAME "json")
    set(JSON_REPO_URL "https://github.com/nlohmann/json.git")
    set(JSON_PKG_MINIMUM_REQUIRED_VERSION "3.10.5")
    set(JSON_REPO_COMMIT "55f93686c01528224f448c19128836e7df245f72")
    set(JSON_SOURCE_DIR "${3RD_PARTY_LIBRARIES_DIRECTORY}/${JSON_LIBRARY_NAME}")
    if(NOT USE_LOCAL_NLOHMANN_JSON)
        verify_dependency_support(${JSON_LIBRARY_NAME} ${JSON_SOURCE_DIR} ${JSON_REPO_COMMIT})
        if (${JSON_LIBRARY_NAME}_MODULE_ADDED)
            add_subdirectory(${JSON_SOURCE_DIR} EXCLUDE_FROM_ALL)
            set(NLOHMANN_JSON_LIBRARIES nlohmann_json)
        endif()
    else()
        set(Boost_NO_SYSTEM_PATHS TRUE)
        find_package(${JSON_PACKAGE_NAME} ${JSON_PKG_MINIMUM_REQUIRED_VERSION} REQUIRED)
        set(NLOHMANN_JSON_LIBRARIES nlohmann_json::nlohmann_json)
    endif()

    #if(IS_COMPILER_SUPPORTS_CXX20_STANDARD)
    #    set(SPDLOG_USE_STD_FORMAT ON CACHE BOOL "Use std::format" FORCE)
    #endif()
    set(SPDLOG_PACKAGE_NAME "spdlog")
    set(SPDLOG_LIBRARY_NAME "spdlog")
    set(SPDLOG_REPO_URL "https://github.com/gabime/spdlog.git")
    set(SPDLOG_PKG_MINIMUM_REQUIRED_VERSION "1.9.2")
    set(SPDLOG_REPO_COMMIT "48bcf39a661a13be22666ac64db8a7f886f2637e")
    set(SPDLOG_SOURCE_DIR "${3RD_PARTY_LIBRARIES_DIRECTORY}/${SPDLOG_LIBRARY_NAME}")
    if(NOT USE_LOCAL_SPDLOG)
        verify_dependency_support(${SPDLOG_LIBRARY_NAME} ${SPDLOG_SOURCE_DIR} ${SPDLOG_REPO_COMMIT})
        add_subdirectory(${SPDLOG_SOURCE_DIR} EXCLUDE_FROM_ALL)
        set(SPDLOG_LIBRARIES spdlog::spdlog_header_only)
    else()
        find_package(${SPDLOG_PACKAGE_NAME} REQUIRED ${SPDLOG_PKG_MINIMUM_REQUIRED_VERSION})
        set(SPDLOG_LIBRARIES spdlog::spdlog)
    endif()

    #   Note:   C++20+ we can use the std::jthread library
    if (NOT IS_COMPILER_SUPPORTS_CXX23_STANDARD OR NOT IS_COMPILER_SUPPORTS_CXX20_STANDARD)
        set(JTHREAD_LIBRARY_NAME "jthread")
        set(JTREAD_REPO_URL "https://github.com/josuttis/jthread.git")
        set(JTHREAD_PKG_MINIMUM_REQUIRED_VERSION "0.0.0")
        set(JTHREAD_REPO_COMMIT "0fa8d394254886c555d6faccd0a3de819b7d47f8")
        set(JTHREAD_SOURCE_DIR "${3RD_PARTY_LIBRARIES_DIRECTORY}/${JTHREAD_LIBRARY_NAME}")
        if(NOT USE_LOCAL_JTHREAD)
            verify_dependency_support(${JTHREAD_LIBRARY_NAME} ${JTHREAD_SOURCE_DIR} ${JTHREAD_REPO_COMMIT})
            add_subdirectory(${JTHREAD_SOURCE_DIR} EXCLUDE_FROM_ALL)
            set(JTHREAD_LIBRARIES jthread)
        else()
            find_path(JOSUTTIS_JTHREAD_INCLUDE_DIRS "condition_variable_any2.hpp")
            include_directories(${JOSUTTIS_JTHREAD_INCLUDE_DIRS})
            add_library(jthread INTERFACE)
            target_include_directories(jthread INTERFACE ${JOSUTTIS_JTHREAD_INCLUDE_DIRS})
            set(JTHREAD_LIBRARIES jthread)
        endif()
    endif()

    # Note: We will not use the boost.parse_args library for now.
    #if(NOT USE_LOCAL_BOOST)
    #    add_subdirectory(${3RD_PARTY_LIBRARIES_DIRECTORY}/boost ${CMAKE_CURRENT_BINARY_DIR}/boost EXCLUDE_FROM_ALL)
    #    set(BOOST_LIBRARIES boost::boost)
    #else()
    #    find_package(Boost 1.74 REQUIRED COMPONENTS stacktrace_basic)
    #    set(BOOST_LIBRARIES boost::boost)
    #endif()
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
        if(NOT DEFINED USE_LOCAL_BOOST_STACKTRACE)
            set(STACKTRACE_BOOST_TRY_OPTIONAL TRUE)
            if(CMAKE_CXX_STANDARD GREATER_EQUAL STD_STACKTRACE_CXX_REQUIRED)
                include(CheckIncludeFileCXX)
                message(STATUS ">> Checking Header: C++${CMAKE_CXX_STANDARD} '<stacktrace>' is required ...")

                ##  We don't need to link the 'stdc++_libbacktrace' library. It is already in libstdc++ for C++23 and later.
                ##  set(BACKTRACE_LIBRARIES ${BACKTRACE_LIBRARIES} "stdc++_libbacktrace")
                check_include_file_cxx(stacktrace HAS_STD_STACKTRACE)
                if(HAS_STD_STACKTRACE)
                    message(STATUS "  >> C++${CMAKE_CXX_STANDARD} '<stacktrace>' header found. ")
                    set(STACKTRACE_BOOST_TRY_OPTIONAL FALSE)
                endif()
            endif()

            #   If the compiler does not support C++23, we will try to use the '<boost::stacktrace>' header.
            if(STACKTRACE_BOOST_TRY_OPTIONAL)
                message(WARNING ">> C++${STD_STACKTRACE_CXX_REQUIRED} '<stacktrace>' requirements were not met. Using '<boost::stacktrace>' ...")
                find_package(Boost 1.74 QUIET COMPONENTS stacktrace)
                if(Boost_FOUND AND TARGET Boost::stacktrace)
                    message(WARNING ">> Will try the option: '<boost::stacktrace>' header.")
                    set(BACKTRACE_LIBRARIES ${BACKTRACE_LIBRARIES} "Boost::stacktrace")
                endif()
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
            set(AMD_WORK_BENCH_COMMON_LINKER_FLAGS "${AMD_WORK_BENCH_COMMON_LINKER_FLAGS} -rdynamic")
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
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${AMD_WORK_BENCH_COMMON_LINKER_FLAGS}")
endmacro()

macro(developer_status_message message_mode message)
    if(AMD_APP_DEBUG_BUILD_INFO OR (DEFINED ENV{AMD_APP_DEBUG_BUILD_INFO} AND ("$ENV{AMD_APP_DEBUG_BUILD_INFO}" STREQUAL "ON")))
        if(NOT "${message_mode}" MATCHES "^(STATUS|WARNING|ERROR|DEBUG|FATAL_ERROR|DEVEL)$")
            message(WARNING "[DEVELOPER]: The '${message_mode}' message mode is not supported for message: '${message}' .")
        else()
            #   ${message_mode} doesn't work here. CMake interpreter sees it as a string; "STATUS", "WARNING"...
            if("${message_mode}" STREQUAL "STATUS")
                message(STATUS "[DEVELOPER]: ${message}")
            elseif("${message_mode}" STREQUAL "WARNING")
                message(WARNING "[DEVELOPER]: ${message}")
            elseif("${message_mode}" STREQUAL "ERROR")
                message(ERROR "[DEVELOPER]: ${message}")
            elseif("${message_mode}" STREQUAL "DEBUG")
                message(DEBUG "[DEVELOPER]: ${message}")
            elseif("${message_mode}" STREQUAL "FATAL_ERROR")
                message(FATAL_ERROR "[DEVELOPER]: ${message}")
            elseif("${message_mode}" STREQUAL "DEVEL")
                message(STATUS "[DEVELOPER]: ${message}")
            else()
                message(WARNING "[DEVELOPER]: ${message}, with invalid message mode: '${message_mode}'")
            endif()
        endif()
    endif()
endmacro()
