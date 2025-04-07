# AMD-Work-Bench (AWB) Plugin Template
# =====================================

# This is the official CMake Template file for AWB custom plugins.
# Just copy this file to the new plugin directory and modify it according to its specific needs.
# It is a CMake project, with some extra functionalities provided by the AWB SDK.

# [CMAKE FUNCTIONS]
# add_amd_work_bench_plugin():  Registers a new plugin
#   NAME:                       The plugin name
#   AMD_WORK_BENCH_VERSION:     The AWB version for compatibility with this plugin.
#                               If not set, the plugin is supposed to be compatible with all versions.
#   SOURCES:                    List of plugin source files
#   INCLUDES:                   List of includes for the plugin
#   LIBRARIES:                  List of libraries for the plugin to link against
#   FEATURES:                   Features are 'optional' and can be enabled or disabled
#   LIBRARY_PLUGIN:             For library plugin. A library plugin can be linked against by other plugins
#                               If set, turns this plugin into a library plugin
#
# enable_plugin_feature(feature_name):  Enables a specific plugin feature. It is an optional part of the plugin, and depends on build settings.
#                                       When enabled, 'AMD_WORK_BENCH_FEATURE_ENABLED(feature_name)' will be defined as 'true', and 'false' otherwise.
#                                       Use it in the main plugin file, in order to have 'feature names' defined and listed as part of the plugin list.
#

cmake_minimum_required(VERSION 3.20)
project(AWBPluginName)

#
# NOTE(s):
#   - NON-C++ PLUGINS
#       Even though this was though as a C++ plugin, we can write plugins in other languages as well and have the new plugin to link statically against
#       the code. The only requirement is a '.cpp source file' with an AMD_WORK_BENCH_PLUGIN_SETUP() instantiation, so the plugin can be set up and
#       registered with AWB.
#
#   - AMD-Work-Bench SDK include
#       The AMD-Work-Bench SDK is included in the project, so you can use the provided functions and classes to interact with the AMD-Work-Bench.
#       The only requirement is to set set the 'AMD_WORK_BENCH_SDK_PATH' environment variable to the path of the AMD-Work-Bench SDK, which should be
#       '/usr/shared/amd-work-bench/sdk' on Linux, by default.
#

if (NOT EXISTS $ENV{AMD_WORK_BENCH_SDK_PATH})
    message(FATAL_ERROR "The AMD_WORK_BENCH_SDK_PATH environment variable is not set")
endif()
add_subdirectory($ENV{AMD_WORK_BENCH_SDK_PATH} rocm_bandwidth_testSDK)

#
# NOTE(s):
#   - Plugin registration
#       It is where the plugin is registered with the AMD-Work-Bench, and required for the custom plugin to be loaded and used.
#       Modify it according to its specific needs, and define the proper plugin name, source files, includes, and libraries.
#
#       In this case, we are defining a plugin called 'sample_plugin' with two source files 'sample_plugin1.cpp' and 'sample_plugin2.cpp',
#       located in the 'src' directory, and includes files/headers located in the 'include' directory. The plugin is linked against the 'jthread' library,
#       which is part of the C++20 standard, and required for the plugin to work.
#       By default the plugin has access to the 'libamd_work_bench.so' library, which provides the necessary functions to interact with the AMD-Work-Bench, 
#       as well as 'json', 'spdlog', which are not part of the C++20 standard, but it can be linked against any other library.
#
add_amd_work_bench_plugin(
    NAME
        sample_plugin

    SOURCES
        src/sample_plugin1.cpp
        src/sample_plugin2.cpp

    INCLUDES
        include

    LIBRARIES
        ${JTHREAD_LIBRARIES}
)


## End of CMakeLists.txt
