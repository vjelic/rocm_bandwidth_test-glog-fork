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
 * Description: linux_utils.hpp
 *
 */

#if !defined(AMD_WORK_BENCH_LINUX_UTILS_HPP)
#define AMD_WORK_BENCH_LINUX_UTILS_HPP


#include <awb/typedefs.hpp>

#include <filesystem>
#include <string>
#include <vector>


namespace amd_work_bench::utils::lnx
{

namespace std_fs = std::filesystem;

static const auto kDEFAULT_VAR_PATH = std::string("PATH");
static const auto kDEFAULT_VAR_LD_LIB_PATH = std::string("LD_LIBRARY_PATH");


using WordList_t = std::vector<std::string>;

auto execute_command(const WordList_t& args_list) -> void;
auto is_process_elevated() -> bool;
auto is_file_in_path(const FSPath_t& file_path) -> bool;
auto get_executable_path() -> std::optional<std_fs::path>;
auto native_error_message(const std::string& message) -> void;
auto startup_native() -> void;

auto get_kernel_version() -> std::string;
auto get_distro_version() -> std::string;

}    // namespace amd_work_bench::utils::lnx


// namespace alias
namespace wb_linux = amd_work_bench::utils::lnx;


#endif    //-- AMD_WORK_BENCH_LINUX_UTILS_HPP
