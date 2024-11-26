cmake_minimum_required(VERSION 3.20)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/..")

project(example
        VERSION 1.2.3
        LANGUAGES C
)

include(build-info)

add_executable(example
    "./main.c"
)

set_target_properties(example PROPERTIES
    VERSION 4.7
)

t_build_target_define_header(example "cmake/build.h"
    PREFIX "EXPL_"
)

target_link_libraries(example
    PRIVATE example::buildinfo
)
