include_guard(GLOBAL)

set(SKIA_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/skia" CACHE PATH "Path to Skia source checkout (with BUILD.gn)")
set(SKIA_BUILD_DIR "${CMAKE_BINARY_DIR}/skia" CACHE PATH "Directory used for Skia build output")
set(_qtskia_default_skia_build_type "Release")
if(CMAKE_CONFIGURATION_TYPES)
    # Multi-config generator（VS 等）：由 SKIA_BUILD_TYPE 决定要编哪一套；默认给 Release。
elseif(DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "")
    # Single-config generator（Ninja 等）：默认与 CMAKE_BUILD_TYPE 对齐，避免 Debug/Release 混链。
    set(_qtskia_default_skia_build_type "${CMAKE_BUILD_TYPE}")
endif()
set(SKIA_BUILD_TYPE "${_qtskia_default_skia_build_type}" CACHE STRING "Skia build configuration (Debug/Release)")
unset(_qtskia_default_skia_build_type)
option(SKIA_ENABLE_GPU "Enable Skia GPU backend" ON)
option(SKIA_USE_DAWN "Enable Dawn backend (if available)" OFF)
option(SKIA_BUILD_TOOLS "Build Skia tools" OFF)
option(SKIA_BUILD_TESTS "Build Skia tests" OFF)
option(QTSKIA_BUILD_SKIA "Build Skia from source during build (requires gn+ninja)" OFF)
option(QTSKIA_AUTO_BUILD_SKIA "Auto-build Skia when prebuilt library is missing (recommended for IDEs like CLion)" ON)
option(QTSKIA_SYNC_SKIA_BUILD_TYPE "Sync SKIA_BUILD_TYPE with CMAKE_BUILD_TYPE for single-config generators" ON)
option(QTSKIA_USE_SYSTEM_DEPS "Use system third-party deps (zlib/libpng/libjpeg-turbo/libwebp/expat) when building Skia via CMake" OFF)

find_package(Python3 REQUIRED COMPONENTS Interpreter)
find_program(NINJA_EXECUTABLE ninja
    PATHS
        "${CMAKE_SOURCE_DIR}/skiaBuild/buildTool/windows"
        "${CMAKE_SOURCE_DIR}/skiaBuild/buildTool/tools"
)
if(NOT NINJA_EXECUTABLE AND CMAKE_MAKE_PROGRAM)
    # CLion/QtCreator 等 IDE 常用 Ninja 生成器，ninja 路径会落在 CMAKE_MAKE_PROGRAM。
    get_filename_component(_make_prog_name "${CMAKE_MAKE_PROGRAM}" NAME)
    if(_make_prog_name MATCHES "^ninja(\\.exe)?$")
        set(NINJA_EXECUTABLE "${CMAKE_MAKE_PROGRAM}")
    endif()
    unset(_make_prog_name)
endif()

function(_qtskia_find_gn out_var)
    unset(_gn CACHE)
    find_program(_gn gn
        PATHS
            "${SKIA_SOURCE_DIR}/bin"
            "${SKIA_SOURCE_DIR}/buildtools/win"
            "${SKIA_SOURCE_DIR}/buildtools/mac"
            "${SKIA_SOURCE_DIR}/buildtools/linux64"
            "${CMAKE_SOURCE_DIR}/skiaBuild/buildTool/windows"
        NO_DEFAULT_PATH
    )
    if(NOT _gn)
        find_program(_gn gn)
    endif()
    set(${out_var} "${_gn}" PARENT_SCOPE)
endfunction()

function(_qtskia_guess_prebuilt_lib out_lib_var)
    set(_candidates "")
    if(WIN32)
        list(APPEND _candidates
            "${SKIA_SOURCE_DIR}/out/${SKIA_BUILD_TYPE}/skia.lib"
            "${SKIA_SOURCE_DIR}/out/Release/skia.lib"
            "${SKIA_SOURCE_DIR}/out/Debug/skia.lib"
        )
    else()
        list(APPEND _candidates
            "${SKIA_SOURCE_DIR}/out/${SKIA_BUILD_TYPE}/libskia.a"
            "${SKIA_SOURCE_DIR}/out/Release/libskia.a"
            "${SKIA_SOURCE_DIR}/out/Debug/libskia.a"
        )
    endif()

    foreach(_p IN LISTS _candidates)
        if(EXISTS "${_p}")
            set(${out_lib_var} "${_p}" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    set(${out_lib_var} "" PARENT_SCOPE)
endfunction()

function(qtskia_enable_skia)
    if(TARGET Skia::Skia)
        return()
    endif()

    if(NOT EXISTS "${SKIA_SOURCE_DIR}/BUILD.gn")
        message(FATAL_ERROR "Skia source not found at '${SKIA_SOURCE_DIR}'. Expected BUILD.gn. Run sync script or set -DSKIA_SOURCE_DIR=...")
    endif()

    # 统一体验：默认优先使用预编译产物；若不存在且工具链齐全，则自动切换到构建模式（避免 IDE 配置失败）。
    set(_use_build_mode "${QTSKIA_BUILD_SKIA}")
    if(NOT _use_build_mode)
        _qtskia_guess_prebuilt_lib(_skia_lib)
        if(NOT _skia_lib AND QTSKIA_AUTO_BUILD_SKIA)
            _qtskia_find_gn(GN_EXECUTABLE)
            if(NINJA_EXECUTABLE AND GN_EXECUTABLE)
                message(STATUS "QtTinaSkia: Prebuilt Skia not found; auto-building Skia (set -DQTSKIA_AUTO_BUILD_SKIA=OFF to disable).")
                set(_use_build_mode ON)
            elseif(NOT NINJA_EXECUTABLE)
                message(STATUS "QtTinaSkia: Prebuilt Skia not found; auto-build skipped because ninja was not found (set -DQTSKIA_BUILD_SKIA=ON after installing ninja, or provide prebuilt under ${SKIA_SOURCE_DIR}/out/<cfg>).")
            elseif(NOT GN_EXECUTABLE)
                message(STATUS "QtTinaSkia: Prebuilt Skia not found; auto-build skipped because gn was not found (run `${Python3_EXECUTABLE} tools/git-sync-deps` in ${SKIA_SOURCE_DIR}, or provide prebuilt under ${SKIA_SOURCE_DIR}/out/<cfg>).")
            endif()
        endif()
    endif()

    if(_use_build_mode)
        if(QTSKIA_SYNC_SKIA_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES AND DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "")
            if(NOT SKIA_BUILD_TYPE STREQUAL CMAKE_BUILD_TYPE)
                message(STATUS "QtTinaSkia: Sync SKIA_BUILD_TYPE='${SKIA_BUILD_TYPE}' -> '${CMAKE_BUILD_TYPE}' to match current build type (disable via -DQTSKIA_SYNC_SKIA_BUILD_TYPE=OFF).")
                set(SKIA_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING "Skia build configuration (Debug/Release)" FORCE)
            endif()
        endif()

        if(NOT NINJA_EXECUTABLE)
            message(FATAL_ERROR "ninja not found. Install Ninja or set QTSKIA_BUILD_SKIA=OFF and point to a prebuilt Skia library under ${SKIA_SOURCE_DIR}/out/<cfg>.")
        endif()

        _qtskia_find_gn(GN_EXECUTABLE)
        if(NOT GN_EXECUTABLE)
            message(FATAL_ERROR "gn not found. Please run: `${Python3_EXECUTABLE} tools/git-sync-deps` in ${SKIA_SOURCE_DIR}")
        endif()
        message(STATUS "QtTinaSkia: Using gn: ${GN_EXECUTABLE}")
        message(STATUS "QtTinaSkia: Using ninja: ${NINJA_EXECUTABLE}")

        if(SKIA_BUILD_TYPE MATCHES "^[Dd]ebug$")
            set(_skia_is_debug "true")
        else()
            set(_skia_is_debug "false")
        endif()

        if(SKIA_ENABLE_GPU)
            set(_skia_use_gl "true")
            set(_skia_enable_gpu "true")
        else()
            set(_skia_use_gl "false")
            set(_skia_enable_gpu "false")
        endif()

        if(SKIA_USE_DAWN)
            set(_skia_use_dawn "true")
        else()
            set(_skia_use_dawn "false")
        endif()

        if(SKIA_BUILD_TOOLS)
            set(_skia_enable_tools "true")
        else()
            set(_skia_enable_tools "false")
        endif()

        set(SKIA_OUT_DIR "${SKIA_BUILD_DIR}/${SKIA_BUILD_TYPE}")

        set(_gn_args "")
        if(_skia_is_debug STREQUAL "true")
            # Skia：is_debug=true 时不允许 is_official_build=true（BUILDCONFIG.gn 断言）。
            set(_qtskia_is_official_build "false")
        else()
            set(_qtskia_is_official_build "true")
        endif()
        list(APPEND _gn_args "is_official_build=${_qtskia_is_official_build}")
        list(APPEND _gn_args "is_component_build=false")
        list(APPEND _gn_args "is_debug=${_skia_is_debug}")
        unset(_qtskia_is_official_build)

        if(MSVC)
            # Skia的gn在某些环境下无法自动探测VS安装路径，这里从编译器路径反推VC目录。
            file(TO_CMAKE_PATH "${CMAKE_CXX_COMPILER}" _cxx_compiler_path)
            string(REGEX REPLACE "^(.*)/VC/Tools/MSVC/.*$" "\\1/VC" _vs_vc_dir "${_cxx_compiler_path}")
            if(EXISTS "${_vs_vc_dir}")
                list(APPEND _gn_args "win_vc=\"${_vs_vc_dir}\"")
            endif()

            # 与 Qt 保持一致：Debug 用 /MDd，Release 用 /MD，避免 CRT 混链（LNK2038）。
            if(_skia_is_debug STREQUAL "true")
                set(_qtskia_msvc_crt "/MDd")
            else()
                set(_qtskia_msvc_crt "/MD")
            endif()
            list(APPEND _gn_args "extra_cflags=[\"${_qtskia_msvc_crt}\"]")
            list(APPEND _gn_args "extra_cflags_cc=[\"${_qtskia_msvc_crt}\"]")
            unset(_qtskia_msvc_crt)
        endif()

        list(APPEND _gn_args "skia_use_gl=${_skia_use_gl}")
        list(APPEND _gn_args "skia_use_vulkan=false")
        list(APPEND _gn_args "skia_use_dawn=${_skia_use_dawn}")
        if(QTSKIA_USE_SYSTEM_DEPS)
            set(_qtskia_use_system_deps "true")
        else()
            set(_qtskia_use_system_deps "false")
        endif()
        # 默认不依赖系统 third_party：Windows/本地环境通常缺对应头文件/库；且仓库已包含 externals。
        list(APPEND _gn_args "skia_use_system_zlib=${_qtskia_use_system_deps}")
        list(APPEND _gn_args "skia_use_system_libpng=${_qtskia_use_system_deps}")
        list(APPEND _gn_args "skia_use_system_libjpeg_turbo=${_qtskia_use_system_deps}")
        list(APPEND _gn_args "skia_use_system_libwebp=${_qtskia_use_system_deps}")
        list(APPEND _gn_args "skia_use_system_expat=${_qtskia_use_system_deps}")
        unset(_qtskia_use_system_deps)
        list(APPEND _gn_args "skia_enable_tools=${_skia_enable_tools}")
        list(APPEND _gn_args "skia_enable_skottie=false")
        list(APPEND _gn_args "skia_enable_pdf=false")
        list(APPEND _gn_args "skia_enable_svg=false")
        list(APPEND _gn_args "skia_enable_ganesh=true")
        list(APPEND _gn_args "skia_enable_graphite=false")
        list(APPEND _gn_args "skia_enable_fontmgr_empty=false")
        list(APPEND _gn_args "skia_enable_fontmgr_win=true")

        string(REPLACE ";" " " _gn_args_str "${_gn_args}")

        add_custom_command(
            OUTPUT "${SKIA_OUT_DIR}/build.ninja"
            COMMAND "${Python3_EXECUTABLE}" -c "import os; os.makedirs(r'${SKIA_OUT_DIR}', exist_ok=True)"
            COMMAND "${GN_EXECUTABLE}" gen "${SKIA_OUT_DIR}" --args=${_gn_args_str}
            WORKING_DIRECTORY "${SKIA_SOURCE_DIR}"
            COMMENT "Configuring Skia (gn gen)"
            VERBATIM
        )

        if(WIN32)
            set(_skia_lib "${SKIA_OUT_DIR}/skia.lib")
        else()
            set(_skia_lib "${SKIA_OUT_DIR}/libskia.a")
        endif()

        add_custom_command(
            OUTPUT "${_skia_lib}"
            COMMAND "${NINJA_EXECUTABLE}" -C "${SKIA_OUT_DIR}" skia
            DEPENDS "${SKIA_OUT_DIR}/build.ninja"
            WORKING_DIRECTORY "${SKIA_SOURCE_DIR}"
            COMMENT "Building Skia (ninja)"
            VERBATIM
        )

        add_custom_target(qtskia_build_skia DEPENDS "${_skia_lib}")
        add_library(Skia::Skia STATIC IMPORTED GLOBAL)
        add_dependencies(Skia::Skia qtskia_build_skia)
        set_target_properties(Skia::Skia PROPERTIES
            IMPORTED_LOCATION "${_skia_lib}"
            INTERFACE_INCLUDE_DIRECTORIES "${SKIA_SOURCE_DIR}/include;${SKIA_SOURCE_DIR}"
        )
        if(WIN32 AND SKIA_ENABLE_GPU)
            set_property(TARGET Skia::Skia APPEND PROPERTY INTERFACE_LINK_LIBRARIES opengl32)
        endif()
    else()
        if(NOT _skia_lib)
            _qtskia_guess_prebuilt_lib(_skia_lib)
        endif()
        if(NOT _skia_lib)
            message(FATAL_ERROR "Prebuilt Skia library not found. Build Skia under `${SKIA_SOURCE_DIR}/out/<cfg>` (e.g. out/Release) or set QTSKIA_BUILD_SKIA=ON (requires gn+ninja).")
        endif()

        add_library(Skia::Skia STATIC IMPORTED GLOBAL)
        set_target_properties(Skia::Skia PROPERTIES
            IMPORTED_LOCATION "${_skia_lib}"
            INTERFACE_INCLUDE_DIRECTORIES "${SKIA_SOURCE_DIR}/include;${SKIA_SOURCE_DIR}"
        )
        if(WIN32 AND SKIA_ENABLE_GPU)
            set_property(TARGET Skia::Skia APPEND PROPERTY INTERFACE_LINK_LIBRARIES opengl32)
        endif()
    endif()
endfunction()
