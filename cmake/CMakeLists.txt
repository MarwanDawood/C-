cmake_minimum_required(VERSION 3.6)
set (CMAKE_CXX_STANDARD 11)

# The project name
project(hello_cmake)

add_subdirectory(thirdparty/catch)
add_subdirectory(src)
add_subdirectory(test)