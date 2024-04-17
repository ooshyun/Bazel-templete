#!/bin/bash
# Reference. https://ltekieli.com/cross-compiling-with-bazel/
# build for default host
# bazel build //:hello

# run
# bazel run //:hello 
# ./bazel-bin/hello

# # build cross-compile
# bazel build @aarch64-rpi3-linux-gnu//:toolchain
# bazel build @aarch64-rpi3-linux-gnu-sysroot//:sysroot

### Legacy cross-compile approach (e.g. crosstool_top)

# pushd -
# cd /workspace/project/bazel-test-build/bazel/toolchain/aarch64-rpi3-linux-gnu/wrappers/
# ls -al
# ln -s wrapper aarch64-rpi3-linux-gnu-ar
# ln -s wrapper aarch64-rpi3-linux-gnu-cpp
# ln -s wrapper aarch64-rpi3-linux-gnu-gcc
# ln -s wrapper aarch64-rpi3-linux-gnu-gcov
# ln -s wrapper aarch64-rpi3-linux-gnu-ld
# ln -s wrapper aarch64-rpi3-linux-gnu-nm
# ln -s wrapper aarch64-rpi3-linux-gnu-objdump
# ln -s wrapper aarch64-rpi3-linux-gnu-strip
# ls -al
# popd
bazel build --crosstool_top=//bazel/toolchain/aarch64-rpi3-linux-gnu:gcc_toolchain --cpu=aarch64 //:hello
