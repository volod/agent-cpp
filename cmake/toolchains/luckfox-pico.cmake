# Luckfox Pico family: Rockchip RV1103 / RV1106, Cortex-A7, ARMv7-A, NEON, hard float.
# Compiler: Ubuntu package g++-arm-linux-gnueabihf (the vendor SDK's GCC 8 is below the C++20
# floor). Binaries are linked statically, so they run on the board's uclibc Buildroot image as
# well as on its Ubuntu image. Tests: qemu-arm from package qemu-user.
set(AGENT_CROSS_TRIPLE arm-linux-gnueabihf)
set(AGENT_CROSS_PROCESSOR armv7l)
set(AGENT_CROSS_QEMU qemu-arm)
set(AGENT_CROSS_CPU_FLAGS "-mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard -mthumb")
include("${CMAKE_CURRENT_LIST_DIR}/linux-gnu-cross.cmake")
