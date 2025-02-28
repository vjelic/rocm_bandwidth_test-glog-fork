/*
 * MIT License
 *
 * Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
 *
 *  Developed by:
 *
 *                  AMD ML Software Engineering
 *
 *                  Advanced Micro Devices, Inc.
 *
 *                  www.amd.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 *  - Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimers.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimers in
 *    the documentation and/or other materials provided with the distribution.
 *  - Neither the names of Advanced Micro Devices, Inc,
 *    nor the names of its contributors may be used to endorse or promote
 *    products derived from this Software without specific prior written
 *    permission.
 *
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Author(s):   Daniel Oliveira <daniel.oliveira@amd.com>
 *
 *
 * Description: default_sets.cpp
 *
 */


#include <awb/default_sets.hpp>
#include <awb/filesystem_ops.hpp>
#include <awb/logger.hpp>

#include <algorithm>
#include <filesystem>
#include <functional>
#include <vector>


namespace amd_work_bench::paths
{

/*
 *  TODO: These need to be rechecked.
 */
auto get_config_paths() -> FSPathList_t
{
    return {{amd_work_bench::xdg::current_work_directory()}, {amd_work_bench::xdg::home_directory() / "amd_work_bench"}};
}


auto get_data_paths() -> FSPathList_t
{
    return {{amd_work_bench::xdg::current_work_directory()}, {amd_work_bench::xdg::home_directory() / "amd_work_bench"}};
}


auto get_plugin_paths() -> FSPathList_t
{
    auto path_list = FSPathList_t{};

    // clang-format off
    #if defined(SYSTEM_DEFAULT_PLUGIN_INSTALL_PATH)
        path_list.emplace_back(SYSTEM_DEFAULT_PLUGIN_INSTALL_PATH);
    #endif
    // clang-format on
    path_list.emplace_back(amd_work_bench::xdg::current_work_directory());
    path_list.emplace_back(amd_work_bench::xdg::home_directory() / "amd_work_bench");

    return path_list;
    // return { {amd_work_bench::xdg::current_work_directory()},
    //          {amd_work_bench::xdg::home_directory() / "amd_work_bench"}
    //        };
}


static auto append_path(FSPathList_t paths, FSPath_t path) -> FSPathList_t
{
    path.make_preferred();
    for (auto& p : paths) {
        p = (p / path);
    }

    return paths;
}


namespace details
{

auto ConfigPath_t::all() const -> FSPathList_t
{
    return append_path(get_config_paths(), m_config_path);
}

auto DefaultPath_t::read() const -> FSPathList_t
{
    wb_logger::loginfo(LogLevel::LOGGER_WARN, "Path: {} ", __PRETTY_FUNCTION__);
    auto paths = all();

    //  TODO:   This is temporary for debbugging only
    for (const auto& path : paths) {
        wb_logger::loginfo(LogLevel::LOGGER_WARN, "    Paths: {} ", path.string());
    }

    std::erase_if(paths, [](const auto& entry) {
        return (!fs::is_directory(entry));
    });

    return paths;
}


auto DefaultPath_t::write() const -> FSPathList_t
{
    auto paths = read();
    std::erase_if(paths, [](const auto& entry) {
        return (!fs::is_path_writeable(entry));
    });

    return paths;
}


auto DataPath_t::all() const -> FSPathList_t
{
    return append_path(get_data_paths(), m_data_path);
}


auto DataPath_t::write() const -> FSPathList_t
{
    auto paths = append_path(get_data_paths(), m_data_path);
    std::erase_if(paths, [](const auto& entry) {
        return (!fs::is_path_writeable(entry));
    });

    return paths;
}


auto PluginPath_t::all() const -> FSPathList_t
{
    return append_path(get_plugin_paths(), m_plugin_path);
}

}    // namespace details


}    // namespace amd_work_bench::paths
