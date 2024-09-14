#=========================================================
# Copyright (C) 2024 Thomas Oliver - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the GPL license distributed with this code.
#=========================================================

#=========================================================
# PRIVATE MEMBERS
#=========================================================

set(_T_BUILD_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})

set(_T_BUILD_GEN_SCRIPT_TEMPLATE_PATH "${_T_BUILD_ROOT_DIR}/gen-hdr.cmake.in")
set(_T_BUILD_HDR_TEMPLATE_PATH "${_T_BUILD_ROOT_DIR}/build-info.h.in")

add_custom_command(
    OUTPUT _t_build_always_rebuild
    COMMAND cmake -E echo
    COMMENT ""
)

function(_t_build_gen_dir OUTPUT_VAR TARGET)
    set(${OUTPUT_VAR} "${CMAKE_CURRENT_BINARY_DIR}/build/${TARGET}" PARENT_SCOPE)
endfunction()

function(_t_build_target_get_version TARGET)
    # Targets Version property...
    get_target_property(TARGET_VERSION ${TARGET} VERSION)

    # Top-level CMake projects Version...
    string(FIND ${TARGET_VERSION} "-NOTFOUND" HAS_VERSION)
    if(NOT HAS_VERSION EQUAL -1)
        set(TARGET_VERSION ${CMAKE_PROJECT_VERSION})
    endif()

    # Default version...
    if(NOT TARGET_VERSION OR TARGET_VERSION STREQUAL "")
        set(TARGET_VERSION "1.0.0")
    endif()

    message(DEBUG "Build Version: ${TARGET_VERSION}")

    # Turn Version string into a list
    string(REPLACE "." ";" TARGET_VERSION ${TARGET_VERSION})    

    # Truncate version list
    list(SUBLIST TARGET_VERSION 0 3 TARGET_VERSION)

    # Pad to major;minor;patch as needed
    list(LENGTH TARGET_VERSION PADDING_NEEDED)
    math(EXPR PADDING_NEEDED "3 - ${PADDING_NEEDED}")
    if(PADDING_NEEDED GREATER 0)
        math(EXPR PADDING_NEEDED "${PADDING_NEEDED} - 1")
        foreach(X RANGE ${PADDING_NEEDED})
            list(APPEND TARGET_VERSION 0)
        endforeach()
    endif()

    # Promote to parent scope
    set(TARGET_VERSION ${TARGET_VERSION} PARENT_SCOPE)
endfunction()

function(_t_build_create_gen_script SCRIPT_PATH INC_DIR HDR_INC_PATH TARGET_VERSION)
    set(OPTIONS)
    set(ONE_VAL_ARGS VER_MAJOR VER_MINOR VER_PATCH)
    set(MULIT_VAL_ARGS)
    cmake_parse_arguments(PARSE_ARGV 1
                          BH
                          OPTIONS ONE_VAL_ARGS MULIT_VAL_ARGS)

    get_filename_component(BASE_DIR ${SCRIPT_PATH} DIRECTORY)

    list(GET TARGET_VERSION 0 VERSION_MAJOR)
    list(GET TARGET_VERSION 1 VERSION_MINOR)
    list(GET TARGET_VERSION 2 VERSION_PATCH)

    string(TIMESTAMP CONFIG_TIMESTAMP "%s" UTC)
    set(GIT_HDR_TEMPLATE_PATH ${_T_BUILD_HDR_TEMPLATE_PATH})
    set(OUTPUT_PATH "${INC_DIR}/${HDR_INC_PATH}")

    set(INCLUDE_GAURD_DEF ${HDR_INC_PATH})
    string(REPLACE "/" "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(REPLACE "\\" "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(REPLACE "." "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(TOUPPER ${INCLUDE_GAURD_DEF} INCLUDE_GAURD_DEF)
    string(PREPEND INCLUDE_GAURD_DEF "BUILD_")
    string(APPEND INCLUDE_GAURD_DEF "_INCLUDED")

    configure_file(${_T_BUILD_GEN_SCRIPT_TEMPLATE_PATH} ${SCRIPT_PATH}
        @ONLY
    )
endfunction()


#=========================================================
# PUBLIC MEMBERS
#=========================================================

function(t_build_target_add_header TARGET HDR_INC_PATH)
    set(OPTIONS)
    set(ONE_VAL_ARGS WORKDIR)
    set(MULIT_VAL_ARGS)
    cmake_parse_arguments(PARSE_ARGV 1
                        GH
                        OPTIONS ONE_VAL_ARGS MULIT_VAL_ARGS)

    message(CHECK_START "Adding \"${HDR_INC_PATH}\"")
    list(APPEND CMAKE_MESSAGE_INDENT "  ")

    _t_build_gen_dir(BASE_DIR ${TARGET})
    set(SCRIPT_DIR "${BASE_DIR}/scripts")
    set(INC_DIR "${BASE_DIR}/inc")
    set(HDR_PATH "${INC_DIR}/${HDR_INC_PATH}")

    message(DEBUG "Base Dir : ${BASE_DIR}")
    message(DEBUG "Inc Dir  : ${INC_DIR}")
    message(DEBUG "Hdr Path : ${HDR_PATH}")

    _t_build_target_get_version(${TARGET})

    _t_build_create_gen_script("${SCRIPT_DIR}/hdr-gen.cmake" ${INC_DIR} ${HDR_INC_PATH} "${TARGET_VERSION}")

    add_custom_command(
        OUTPUT ${HDR_PATH}
        COMMAND ${CMAKE_COMMAND} "-P" "${SCRIPT_DIR}/hdr-gen.cmake"
        COMMENT "Generating ${HDR_INC_PATH}"
        DEPENDS
            _t_build_always_rebuild
    )

    target_include_directories(${TARGET}
        PRIVATE ${INC_DIR}
    )

    target_sources(${TARGET}
        PRIVATE ${HDR_PATH}
    )

    list(POP_BACK CMAKE_MESSAGE_INDENT)
    message(CHECK_PASS "success")
endfunction()