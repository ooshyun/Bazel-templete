# Cross compile by using Bazel build system
This repository is code example for [this link](https://ltekieli.com/cross-compiling-with-bazel/). The details is check the link.

## 0. Bazel?
- Other build systems 
  - Shell, Make, CMake, Maven, Ninja

- Property
  - Open-source build system developed by Google
  - Designed for large, complex software projects
  - Scalable, deterministic, and supports multiple languages
  - Uses Starlark build language
  - Wide range of programming languages and platforms supported
  - Built-in caching and distributed builds for faster and efficient builds

- Target
- Actions
- Workspaces
- Package
- Labels
  - Labels are unique identifiers for targets. A label in bazel follows the following structure:
    ```@workspace_name//package_name:target_name```
  - @ is the current workspace, but it's often times omitted.
- BUILD files
- Rules
```python
def _hello_world_impl(ctx):
  output_file = ctx.outputs.out
  ctx.actions.write(output_file, "Hello World!\n")
  
hello_world = rule(
  implementation = _hello_world_impl,
  attrs = {},
  outputs = {"out": "%{name}.txt"},
)
```
- Macros
```python
def cc_lib_and_binary(name, **kwargs):
  lib_name = "%s.lib" % name
  cc_library(
    name = lib_name,
    **kwargs,
  )
  deps = kwargs.pop("deps", []) + [lib_name]
  cc_binary(
    name = name,
    deps = deps,
    **kwargs
  )
```
- Bazel flags and .bazelrc


- Bazel Ops
  - --config / -c
  - --repo_env
    - add environment variables (e.g. LD_LIBRARY_PATH, PATH)
  - --define
  - if_true, if_false
  - select
  - if_oss

## 1. Bazel Basic

### file tree
bazel/
  toolchain/
    BUILD           # Empty or containing relevant targets
    toolchain.bzl   # Contains your toolchain definitions
WORKSPACE

### name
- third_party/toolchains/*.BUILD
```BUILD
package(default_visibility = ['//visibility:public'])

filegroup(
  name = 'toolchain',
  srcs = glob([
    '**',
  ]),
)
```
- the name will be used for srcs in the BUILD file
- e.g. BUILD file: bazel/toolchain/aarch64-rpi3-linux-gnu/BUILD
```BUILD
filegroup(
  name = 'all_files',
  srcs = [
    '@aarch64-rpi3-linux-gnu-sysroot//:sysroot',
    '@aarch64-rpi3-linux-gnu//:toolchain',
    ':wrappers',
  ],
)
```

### @ and :
- @ is the current workspace, but it's often times omitted. Refer to Label in 0. Bazel?
```BUILD
filegroup(
  name = 'wrappers',
  srcs = glob([
    'wrappers/**',
  ]),
)

filegroup(
  name = 'all_files',
  srcs = [
    '@aarch64-rpi3-linux-gnu-sysroot//:sysroot',
    '@aarch64-rpi3-linux-gnu//:toolchain',
    ':wrappers',
  ],
)
```
### Installation
```bash
$ wget https://github.com/bazelbuild/bazelisk/releases/download/v1.6.1/bazelisk-linux-amd64
$ sudo mv bazelisk-linux-amd64 /usr/local/bin/bazel
$ sudo chmod +x /usr/local/bin/bazel
```

## 2. Bazel Build "Hello World"
```bash
$ tree
.
├── BUILD
├── main.cpp
└── WORKSPACE

$ cat BUILD 
cc_binary(
    name = "hello",
    srcs = ["main.cpp"],
)

$ cat main.cpp 
#include <iostream>

int main() {
    std::cout << "Hello World!" << std::endl;
}
```
- run
```bash

$ bazel run //:hello 
...
Hello World!

$ ./bazel-bin/hello
Hello World!
```

## [Legacy] 3. Bazel Cross-compile using --crosstool_top --cpu 

### 3.1 Download Dependencies
```bash
$ tree
.
├── BUILD
├── main.cpp
├── third_party
│   ├── BUILD
│   ├── deps.bzl
│   └── toolchains
│       ├── aarch64-rpi3-linux-gnu-sysroot.BUILD
│       ├── aarch64-rpi3-linux-gnu.BUILD
│       ├── arm-cortex_a8-linux-gnueabihf-sysroot.BUILD
│       ├── arm-cortex_a8-linux-gnueabihf.BUILD
│       ├── BUILD
│       └── toolchains.bzl
└── WORKSPACE
```
- WORKSPACE
- third_party/deps.bzl
- third_party/toolchains/toolchains.bzl 
- third_party/toolchains/aarch64-rpi3-linux-gnu.BUILD 
- bazel build @aarch64-rpi3-linux-gnu//:toolchain

- How to find package?    
```bash
bazel query 'deps(//:hello)' --nohost_deps --noimplicit_deps
bazel query //:hello --output=build
# bazel query //some/package/... --output location
bazel query //:hello --output location
bazel query @aarch64-rpi3-linux-gnu-sysroot//:sysroot --output location
```

### 3.2 Set Custom toolchains
- bazel/toolchain/aarch64-rpi3-linux-gnu/BUILD 
- bazel/toolchain/aarch64-rpi3-linux-gnu/wrappers
  - linker compile package to wrapper
  - bazel/toolchain/aarch64-rpi3-linux-gnu/wrappers/wrapper 
- bazel/toolchain/aarch64-rpi3-linux-gnu/cc_toolchain_config.bzl   
- bazel build
```bash
$ bazel build --crosstool_top=//bazel/toolchain/aarch64-rpi3-linux-gnu:gcc_toolchain --cpu=aarch64 //:hello 
INFO: Build options --cpu and --crosstool_top have changed, discarding analysis cache.
INFO: Analyzed target //:hello (0 packages loaded, 7129 targets configured).
INFO: Found 1 target...
Target //:hello up-to-date:
  bazel-bin/hello
INFO: Elapsed time: 0.970s, Critical Path: 0.03s
INFO: 0 processes.
INFO: Build completed successfully, 1 total action

$ file bazel-bin/hello
bazel-bin/hello: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 5.5.5, not stripped
```

## 4. Bazel Cross-compile using --platforms
- bazel/platforms/BUILD 
- bazel/toolchain/aarch64-rpi3-linux-gnu/BUILD 
- bazel/toolchain/toolchain.bzl 
- WORKSPACE
- bazel build
```bash
$ bazel build \
    --incompatible_enable_cc_toolchain_resolution \
    --platforms=//bazel/platforms:rpi \
    //:hello 
Starting local Bazel server and connecting to it...
INFO: Analyzed target //:hello (19 packages loaded, 7123 targets configured).
INFO: Found 1 target...
Target //:hello up-to-date:
  bazel-bin/hello
INFO: Elapsed time: 25.510s, Critical Path: 1.41s
INFO: 2 processes: 2 linux-sandbox.
INFO: Build completed successfully, 6 total actions

$ file bazel-bin/hello
bazel-bin/hello: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 5.5.5, not stripped
```

- Clean
  - bazel clean
  - bazel clean --async
  - clear the bazel cache: bazel clean --expunge

## 5. Convenience way Bazel Cross-compile 

```bash
$ cat .bazelrc 
build:rpi --crosstool_top=//bazel/toolchain/aarch64-rpi3-linux-gnu:gcc_toolchain --cpu=aarch64
build:bbb --crosstool_top=//bazel/toolchain/arm-cortex_a8-linux-gnueabihf:gcc_toolchain --cpu=armv7

build:platform_build --incompatible_enable_cc_toolchain_resolution
build:rpi-platform --config=platform_build --platforms=//bazel/platforms:rpi
build:bbb-platform --config=platform_build --platforms=//bazel/platforms:bbb

$ bazel build --config=rpi //:hello
$ bazel build --config=rpi-platform //:hello
```

## 6. Bazel platforms types
- In this case,
```BUILD
toolchain(
    name = "aarch64_linux_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
    toolchain = ":aarch64_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
```

### Reference
- [Bazel?] https://www.youtube.com/watch?v=sW8b-cgqicc
- [Bazel?] https://opensource.siemens.io/events/2023/slides/Antonio_Di_Stefano_%20What%27s_Bazel_Why_should_you_care.pdf
- https://ltekieli.com/cross-compiling-with-bazel/
- [Bazel-platform-types] https://github.com/bazelbuild/platforms?tab=readme-ov-file