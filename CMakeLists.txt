cmake_minimum_required(VERSION 3.21)

project(QtTinaSkia
    VERSION 2.0.0
    DESCRIPTION "Qt6 integration with Skia graphics library"
    LANGUAGES CXX
)

if(WIN32 AND MSVC)
    # 某些 IDE/Ninja 环境下不会自动带上 Windows SDK 的 /LIBPATH，
    # 导致链接阶段找不到 mpr.lib / userenv.lib 等系统库（LNK1104）。
    find_library(_qtskia_mpr_lib NAMES mpr.lib mpr)
    find_library(_qtskia_msvcprtd_lib NAMES msvcprtd.lib msvcprtd)

    if(CMAKE_CXX_COMPILER)
        # 补齐 MSVC 工具集的库目录（msvcprt/msvcprtd 等）。
        file(TO_CMAKE_PATH "${CMAKE_CXX_COMPILER}" _qtskia_cxx_compiler_path)
        # .../VC/Tools/MSVC/<ver>/bin/Hostx64/x64/cl.exe -> .../VC/Tools/MSVC/<ver>
        string(REGEX REPLACE "^(.*)/bin/Host[^/]+/[^/]+/cl\\.exe$" "\\1" _qtskia_msvc_root "${_qtskia_cxx_compiler_path}")
        # 某些 IDE/终端环境下不会初始化环境变量 INCLUDE，导致找不到 <type_traits> 等标准头文件；
        # 这里在 INCLUDE 为空时，显式补齐 MSVC 标准库头文件目录。
        if(NOT DEFINED ENV{INCLUDE} OR "$ENV{INCLUDE}" STREQUAL "")
            set(_qtskia_msvc_include "${_qtskia_msvc_root}/include")
            if(EXISTS "${_qtskia_msvc_include}")
                # 用 compile option 强制注入，避免目录属性在某些生成器/子目录下不生效。
                add_compile_options("$<$<COMPILE_LANGUAGE:CXX>:/I${_qtskia_msvc_include}>")
            endif()
            unset(_qtskia_msvc_include)
        endif()

        if(NOT _qtskia_msvcprtd_lib)
            set(_qtskia_msvc_lib "${_qtskia_msvc_root}/lib/x64")
            set(_qtskia_msvc_lib_onecore "${_qtskia_msvc_root}/lib/onecore/x64")
            if(EXISTS "${_qtskia_msvc_lib}")
                link_directories("${_qtskia_msvc_lib}")
            endif()
            if(EXISTS "${_qtskia_msvc_lib_onecore}")
                link_directories("${_qtskia_msvc_lib_onecore}")
            endif()
            unset(_qtskia_msvc_lib)
            unset(_qtskia_msvc_lib_onecore)
        endif()
        unset(_qtskia_cxx_compiler_path)
        unset(_qtskia_msvc_root)
    endif()

    if(CMAKE_RC_COMPILER)
        get_filename_component(_qtskia_rc_dir "${CMAKE_RC_COMPILER}" DIRECTORY)          # .../bin/<ver>/x64
        get_filename_component(_qtskia_rc_ver_dir "${_qtskia_rc_dir}" DIRECTORY)        # .../bin/<ver>
        get_filename_component(_qtskia_winsdk_ver "${_qtskia_rc_ver_dir}" NAME)         # <ver>
        get_filename_component(_qtskia_winkits_bin "${_qtskia_rc_ver_dir}" DIRECTORY)   # .../bin
        get_filename_component(_qtskia_winkits_root "${_qtskia_winkits_bin}" DIRECTORY) # .../Windows Kits/10

        if(NOT _qtskia_mpr_lib)
            set(_qtskia_winsdk_um "${_qtskia_winkits_root}/Lib/${_qtskia_winsdk_ver}/um/x64")
            set(_qtskia_winsdk_ucrt "${_qtskia_winkits_root}/Lib/${_qtskia_winsdk_ver}/ucrt/x64")
            if(EXISTS "${_qtskia_winsdk_um}")
                link_directories("${_qtskia_winsdk_um}")
            endif()
            if(EXISTS "${_qtskia_winsdk_ucrt}")
                link_directories("${_qtskia_winsdk_ucrt}")
            endif()
            unset(_qtskia_winsdk_um)
            unset(_qtskia_winsdk_ucrt)
        endif()

        # 同时补齐 Windows SDK 头文件目录（不依赖 mpr.lib 是否已可找到），避免 INCLUDE 未初始化时找不到 <stddef.h> 等。
        if(NOT DEFINED ENV{INCLUDE} OR "$ENV{INCLUDE}" STREQUAL "")
            set(_qtskia_winsdk_inc_root "${_qtskia_winkits_root}/Include/${_qtskia_winsdk_ver}")
            foreach(_qtskia_winsdk_inc_sub ucrt um shared winrt)
                set(_qtskia_winsdk_inc "${_qtskia_winsdk_inc_root}/${_qtskia_winsdk_inc_sub}")
                if(EXISTS "${_qtskia_winsdk_inc}")
                    add_compile_options("$<$<COMPILE_LANGUAGE:CXX>:/I${_qtskia_winsdk_inc}>")
                endif()
                unset(_qtskia_winsdk_inc)
            endforeach()
            unset(_qtskia_winsdk_inc_root)
        endif()

        unset(_qtskia_rc_dir)
        unset(_qtskia_rc_ver_dir)
        unset(_qtskia_winsdk_ver)
        unset(_qtskia_winkits_bin)
        unset(_qtskia_winkits_root)
    endif()
    unset(_qtskia_mpr_lib)
    unset(_qtskia_msvcprtd_lib)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

option(BUILD_EXAMPLES "Build example applications" ON)
option(BUILD_TESTS "Build tests" OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick OpenGL OpenGLWidgets)

include(CompilerWarnings)
include(SkiaConfig)

add_subdirectory(QtSkia)

if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
