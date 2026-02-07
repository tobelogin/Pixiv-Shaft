# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html.
# For more examples on how to use CMake, see https://github.com/android/ndk-samples.

# Sets the minimum CMake version required for this project.
cmake_minimum_required(VERSION 3.22.1)

# Declares the project name. The project name can be accessed via ${ PROJECT_NAME},
# Since this is the top level CMakeLists.txt, the project name is also accessible
# with ${CMAKE_PROJECT_NAME} (both CMake variables are in-sync within the top level
# build script scope).
project("native_libs")

set(SHELL_OUTPUT_DIR "/tmp/shaft_build")

# 工作目录好像是由 Gradle 指定的，默认是模块根目录
execute_process(
        COMMAND bash -c "TARGET_ARCH=${CMAKE_ANDROID_ARCH} TARGET_API_LEVEL=${CMAKE_ANDROID_API_MIN} OUTPUT_DIR=${SHELL_OUTPUT_DIR} NDK_HOME=${CMAKE_ANDROID_NDK} ./src/main/cpp/build_modules.sh"
        OUTPUT_FILE /tmp/shell_${CMAKE_ANDROID_ARCH_ABI}.log
        RESULT_VARIABLE LIBWEBP_BUILD_RESULT
)

if (NOT (LIBWEBP_BUILD_RESULT EQUAL 0))
    message(FATAL_ERROR "Unable to build libwebp.")
endif ()


add_library(webp SHARED IMPORTED GLOBAL)
set_target_properties(
        webp
        PROPERTIES IMPORTED_LOCATION "${SHELL_OUTPUT_DIR}/libs/libwebp.so"
)

add_library(webpmux SHARED IMPORTED GLOBAL)
set_target_properties(
        webpmux
        PROPERTIES IMPORTED_LOCATION "${SHELL_OUTPUT_DIR}/libs/libwebpmux.so"
)

add_library(sharpyuv SHARED IMPORTED GLOBAL)
set_target_properties(
        sharpyuv
        PROPERTIES IMPORTED_LOCATION "${SHELL_OUTPUT_DIR}/libs/libsharpyuv.so"
)

add_library(avformat SHARED IMPORTED GLOBAL)
set_target_properties(
        avformat
        PROPERTIES IMPORTED_LOCATION "${SHELL_OUTPUT_DIR}/libs/libavformat.so"
)

add_library(avcodec SHARED IMPORTED GLOBAL)
set_target_properties(
        avcodec
        PROPERTIES IMPORTED_LOCATION "${SHELL_OUTPUT_DIR}/libs/libavcodec.so"
)

add_library(avutil SHARED IMPORTED GLOBAL)
set_target_properties(
        avutil
        PROPERTIES IMPORTED_LOCATION "${SHELL_OUTPUT_DIR}/libs/libavutil.so"
)

add_library(swscale SHARED IMPORTED GLOBAL)
set_target_properties(
        swscale
        PROPERTIES IMPORTED_LOCATION "${SHELL_OUTPUT_DIR}/libs/libswscale.so"
)
# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.
#
# In this top level CMakeLists.txt, ${CMAKE_PROJECT_NAME} is used to define
# the target library name; in the sub-module's CMakeLists.txt, ${PROJECT_NAME}
# is preferred for the same purpose.
#
# In order to load a library into your app from Java/Kotlin, you must call
# System.loadLibrary() and pass the name of the library defined here;
# for GameActivity/NativeActivity derived applications, the same library name must be
# used in the AndroidManifest.xml file.
add_library(${CMAKE_PROJECT_NAME} SHARED
        # List C/C++ source files with relative paths to this CMakeLists.txt.
        av-helper.c)

link_directories(${LIBRARY_SEARCH_PATH})

# Specifies libraries CMake should link to your target library. You
# can link libraries from various origins, such as libraries defined in this
# build script, prebuilt third-party libraries, or Android system libraries.
target_link_libraries(${CMAKE_PROJECT_NAME}
        # List libraries link to the target library
        android
        log
        sharpyuv
        webp
        webpmux
        avformat
        avcodec
        avutil
        swscale
)

