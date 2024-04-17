def register_all_toolchains():
    native.register_toolchains(
        "//bazel/toolchain/aarch64-rpi3-linux-gnu:aarch64_linux_toolchain",
    )
