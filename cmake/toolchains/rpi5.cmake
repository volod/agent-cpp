# Raspberry Pi 5: BCM2712, 4x Cortex-A76, AArch64. Runs on 64-bit Raspberry Pi OS and Ubuntu.
# Compiler: Ubuntu package g++-aarch64-linux-gnu. Tests: qemu-aarch64 from package qemu-user.
set(AGENT_CROSS_TRIPLE aarch64-linux-gnu)
set(AGENT_CROSS_PROCESSOR aarch64)
set(AGENT_CROSS_QEMU qemu-aarch64)
set(AGENT_CROSS_CPU_FLAGS "-mcpu=cortex-a76")
include("${CMAKE_CURRENT_LIST_DIR}/linux-gnu-cross.cmake")
