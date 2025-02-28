# AMD Work Bench (RBT-Next Generation)
[![AMD](https://img.shields.io/badge/AMD-%23000000.svg?style=for-the-badge&logo=amd&logoColor=white)](https://www.amd.com)
[![Language](https://img.shields.io/badge/Language-C++-blue.svg)](https://isocpp.org/) 
[![Standard](https://img.shields.io/badge/C%2B%2B-23-blue.svg)](https://en.wikipedia.org/wiki/C%2B%2B#Standardization) 
[![Standard](https://img.shields.io/badge/C-23-purple.svg)](https://en.wikipedia.org/wiki/C23_(C_standard_revision))
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) 
<!--- 
[![Build](https://github.amd.com/LSTT/amd-work-bench/actions/workflows/unit-test.yml/badge.svg)](https://github.amd.com/LSTT/amd-work-bench/actions/workflows/unit-test.yml)
-->

**AMD Work Bench** is the next generation of the ROCm Bandwidth Test, designed to measure the bandwidth between CPU and GPU devices on AMD platforms. This version has been completely rewritten with a focus on modularity and extensibility through a plugin-based architecture.

>[!NOTE]
>This project is a successor to [RBT](https://rocm.docs.amd.com/projects/rocm_bandwidth_test/en/latest/index.html)
>and [TB](https://rocm.docs.amd.com/projects/TransferBench/en/latest/index.html).

## Overview

AMD Work Bench leverages [TransferBench (TB)](https://github.com/ROCm/TransferBench) as its core engine for benchmarking data transfers. This approach allows for more flexible and efficient testing scenarios.

- **Plugin Architecture:** Easily extend the functionality of AMD Work Bench with custom plugins.
- **Modular Design:** Separate concerns for better maintenance and development.
- **Enhanced Performance:** Improved algorithms and integration with TransferBench for precise measurements.

See the [full library and API documentation](https://rocm.docs.amd.com/en/latest/deploy/linux/index.html)


## Features

- **CPU to GPU Bandwidth Testing:** Measure data transfer rates in various scenarios.
- **GPU to GPU Bandwidth Testing:** For systems with multiple GPUs.
- **Multi-Threaded Testing:** Simulate real-world applications with concurrent data transfers.
- **Extensibility:** Add new test scenarios through plugins.

## Installation

### Prerequisites

- ROCm compatible hardware
- ROCm stack installed ([Installation Guide](https://rocm.docs.amd.com/en/latest/deploy/linux/index.html))
- GCC compiler

### Build from Source

See [Build from Source](#Build_from_Source)

```bash
git clone https://github.amd.com/LSTT/amd-work-bench.git
cd amd-work-bench
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug|Release
make
```

## Usage

AMD Work Bench can be run with various options to customize the test:
```bash
./amd_work_bench [-h|--help] [-v|--version] 
./amd_work_bench plugin [--help] 
```

- --help: Displays help information.
- --version: Shows the application version.
- --plugin: Loads a specific plugin for extended functionality.

### Example

```bash
./amd_work_bench --plugin -r my_custom_plugin

``` 

## Plugins

Plugins are the heart of AMD Work Bench's extensibility. Here's how you can create or use them:

- Creating Plugins: Follow the `Plugin Development Guide`.
- Using Existing Plugins: Check the `plugins` directory for available options.


## Documentation 

- [Official RBT Documentation](https://rocm.docs.amd.com/projects/rocm_bandwidth_test/en/latest/index.html)
- [TransferBench Documentation](https://rocm.docs.amd.com/projects/TransferBench/en/latest/index.html)


## Contributing & support

We welcome contributions! Please read our [CONTRIBUTING](./CONTRIBUTING.md) for details on how to get started.

Join the community by reporting issues or asking questions via [GitHub issues](https://github.amd.com/LSTT/amd-work-bench.git/issues). All feedback and proposals are welcome.

Please review our [SECURITY](./SECURITY.md) policy for information on reporting security issues.


## License

This project is licensed under the MIT Software License. See accompanying file [LICENSE](./LICENSE.md) file or copy [here](https://opensource.org/licenses/MIT) for legal details.
See [AUTHORS](./AUTHORS.md) file for details about the current maintainers.


## Acknowledgments

- Thanks to AMD ROCm team for providing the foundational work with RBT and TB.
- AMD MLSE Linux team
- Contributors to this project.
- Other projects who inspired this one: 
  - 
  - 

## DISCLAIMER

<p align="justify"> 
The information contained herein is for informational purposes only, and is subject to change without notice. In
addition, any stated support is planned and is also subject to change. While every precaution has been taken in 
the preparation of this document, it may contain technical inaccuracies, omissions and typographical errors, and 
AMD is under no obligation to update or otherwise correct this information. Advanced Micro Devices, Inc. makes no
representations or warranties with respect to the accuracy or completeness of the contents of this document, and 
assumes no liability of any kind, including the implied warranties of noninfringement, merchantability or fitness 
for particular purposes, with respect to the operation or use of AMD hardware, software or other products 
described herein.
</p>

© 2023-2025 Advanced Micro Devices, Inc. All Rights Reserved.
