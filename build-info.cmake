#=========================================================
# Copyright (C) 2024 Thomas Oliver - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the license distributed with this code.
#=========================================================
# SPDX-License-Identifier: MIT
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

function(_t_build_version_str_to_list OUT_VAR VERSION)
    # Turn Version string into a list
    string(REPLACE "." ";" VERSION ${VERSION})

    # Truncate version list
    list(SUBLIST VERSION 0 4 VERSION)

    # Pad to major;minor;patch;tweak as needed
    list(LENGTH VERSION PADDING_NEEDED)
    math(EXPR PADDING_NEEDED "4 - ${PADDING_NEEDED}")
    if(PADDING_NEEDED GREATER 0)
        math(EXPR PADDING_NEEDED "${PADDING_NEEDED} - 1")
        foreach(X RANGE ${PADDING_NEEDED})
            list(APPEND VERSION 0)
        endforeach()
    endif()

    # Promote to parent scope
    set(${OUT_VAR} ${VERSION} PARENT_SCOPE)
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

    _t_build_version_str_to_list(TARGET_VERSION ${TARGET_VERSION})

    # Promote to parent scope
    set(TARGET_VERSION ${TARGET_VERSION} PARENT_SCOPE)
endfunction()

function(_t_build_get_main_lang OUT_VAR)
    # Get enabled languages.
    get_property(ENABLED_LANGS GLOBAL PROPERTY ENABLED_LANGUAGES)

    # If C++ enabled, use that as default.
    list(FIND ENABLED_LANGS "CXX" CXX_FOUND)
    if(NOT CXX_FOUND EQUAL -1)
        set(MAIN_LANG "CXX")
    endif()

    # C compiler if not.
    list(FIND ENABLED_LANGS "C" C_FOUND)
    if(NOT MAIN_LANG AND NOT C_FOUND EQUAL -1)
        set(MAIN_LANG "C")
    endif()

    # Promote to parent scope
    set(${OUT_VAR} ${MAIN_LANG} PARENT_SCOPE)
endfunction()

function(_t_build_get_compiler_info TARGET)
    get_property(ENABLED_LANGS GLOBAL PROPERTY ENABLED_LANGUAGES)

    _t_build_get_main_lang(MAIN_LANG)
    if(MAIN_LANG)
        set(COMPILER_VERSION ${CMAKE_${MAIN_LANG}_COMPILER_VERSION})
        set(COMPILER_NAME ${CMAKE_${MAIN_LANG}_COMPILER_ID})
    else()
        set(COMPILER_VERSION "0.0.0")
        set(COMPILER_NAME "unknown")
    endif()

    _t_build_version_str_to_list(COMPILER_VERSION ${COMPILER_VERSION})

    # Promote to parent scope
    set(COMPILER_NAME ${COMPILER_NAME} PARENT_SCOPE)
    set(COMPILER_VERSION ${COMPILER_VERSION} PARENT_SCOPE)
endfunction()

function(_t_build_create_gen_script SCRIPT_PATH INC_DIR HDR_INC_PATH)
    set(OPTIONS)
    set(ONE_VAL_ARGS TARGET_VERSION COMPILER_NAME COMPILER_VERSION)
    set(MULIT_VAL_ARGS)
    cmake_parse_arguments(PARSE_ARGV 3
                          arg
                          "${OPTIONS}" "${ONE_VAL_ARGS}" "${MULIT_VAL_ARGS}")

    get_filename_component(BASE_DIR ${SCRIPT_PATH} DIRECTORY)

    message(DEBUG "Target Ver.   : ${arg_TARGET_VERSION}")
    message(DEBUG "Compiler      : ${arg_COMPILER_NAME}")
    message(DEBUG "Compiler Ver. : ${arg_COMPILER_VERSION}")

    set(cfg_TARGET_VERSION "${arg_TARGET_VERSION}")
    set(cfg_COMPILER_NAME "${arg_COMPILER_NAME}")
    set(cfg_COMPILER_VERSION "${arg_COMPILER_VERSION}")

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

function(t_build_target_define_header TARGET HDR_INC_PATH)
    set(OPTIONS)
    set(ONE_VAL_ARGS WORKDIR)
    set(MULIT_VAL_ARGS)
    cmake_parse_arguments(PARSE_ARGV 2
                          arg
                          "${OPTIONS}" "${ONE_VAL_ARGS}" "${MULIT_VAL_ARGS}")

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
    _t_build_get_compiler_info(${TARGET})

    _t_build_create_gen_script("${SCRIPT_DIR}/hdr-gen.cmake" ${INC_DIR} ${HDR_INC_PATH}
        TARGET_VERSION "${TARGET_VERSION}"
        COMPILER_NAME "${COMPILER_NAME}"
        COMPILER_VERSION "${COMPILER_VERSION}"
    )

    add_custom_command(
        OUTPUT ${HDR_PATH}
        COMMAND ${CMAKE_COMMAND} "-P" "${SCRIPT_DIR}/hdr-gen.cmake"
        COMMENT "Generating ${HDR_INC_PATH}"
        DEPENDS
            _t_build_always_rebuild
    )

    set(TARGET_LIB _${TARGET}_buildinfo)

    add_library(${TARGET_LIB} INTERFACE)

    target_sources(${TARGET_LIB} INTERFACE
        ${HDR_PATH}
    )

    target_include_directories(${TARGET_LIB} INTERFACE
        ${INC_DIR}
    )

    add_library(${TARGET}::buildinfo ALIAS ${TARGET_LIB})

    list(POP_BACK CMAKE_MESSAGE_INDENT)
    message(CHECK_PASS "success")
endfunction()