cmake_minimum_required(VERSION 3.10.2)
project("sapling_fix")

add_library(sapling_fix SHARED sapling_fix.cpp)
target_link_libraries(sapling_fix dl log)
