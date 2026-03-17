cmake_minimum_required(VERSION 3.10.2)
project("sapling_fix")

add_library(sapling_fix SHARED sapling_fix.cpp)
target_link_libraries(sapling_fix dl log)

# Align ELF load segments to 16 KB so the .so is compatible with both 4 KB
# and 16 KB memory page sizes (required for Android 15+ / large-page devices).
target_link_options(sapling_fix PRIVATE "-Wl,-z,max-page-size=16384")
