#!/bin/bash

# 需要的环境变量
# $TARGET_ARCH
# $TARGET_API_LEVEL
# $OUTPUT_DIR
# $NDK_HOME

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# TODO 在 Gradle 的配置文件中定义这两个库的位置
LIBWEBP_SRC_DIR=$SCRIPT_DIR/modules/libwebp
LIBWEBP_OUTPUT_DIR=$OUTPUT_DIR/libwebp/$TARGET_ARCH\_$TARGET_API_LEVEL

LIBAV_SRC_DIR=$SCRIPT_DIR/modules/libav
LIBAV_OUTPUT_DIR=$OUTPUT_DIR/libav/$TARGET_ARCH\_$TARGET_API_LEVEL
toolchain_target=""
cross_arch=""

if [ ! -f $LIBWEBP_SRC_DIR/autogen.sh ] || [ ! -f $LIBAV_SRC_DIR/configure ]; then
  echo Unable to find libwebp source or ffmpeg source.
  exit 1
fi


export PATH=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:/usr/bin:/bin

# 检测能否创建/使用该文件夹
check_dir_available() {
  if [ -e $1 ] && [ -f $1 ]; then
    echo "Unable to create directory \"$1\"."
    exit 1
  fi
}

check_dir_available $OUTPUT_DIR/libs
mkdir -p $OUTPUT_DIR/libs
rm -rf $OUTPUT_DIR/libs/*

if [ "$TARGET_ARCH" = "arm64" ]; then
  cross_arch="aarch64"
elif [ "$TARGET_ARCH" = "arm" ]; then
  cross_arch="armv7a"
elif [ "$TARGET_ARCH" = "x86" ]; then
  cross_arch="i686"
elif [ "$TARGET_ARCH" = "x86_64" ]; then
  cross_arch="x86_64"
fi

toolchain_target=$cross_arch-linux-android$TARGET_API_LEVEL

cd $LIBWEBP_SRC_DIR
if [ ! -e "configure" ]; then
  ./autogen.sh
fi
if [ -d "configure" ]; then
  echo "Unable to generate configure for libwebp"
  exit 1
fi

# 构建 libwebp
check_dir_available "$LIBWEBP_OUTPUT_DIR/build"
mkdir -p "$LIBWEBP_OUTPUT_DIR/build" && cd "$LIBWEBP_OUTPUT_DIR/build"
$LIBWEBP_SRC_DIR/configure --prefix="$LIBWEBP_OUTPUT_DIR/install" --enable-static=no \
  --disable-libwebpdemux --disable-avx2 --disable-sse4.1 --disable-sse2 --disable-neon --disable-neon-rtcd --disable-threading --disable-gl --disable-sdl \
  --disable-png --disable-jpeg --disable-tiff --disable-gif --disable-wic --enable-swap-16bit-csp \
  --host=$toolchain_target --with-sysroot=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
  CC="clang -target $toolchain_target" LD=ld LDFLAGS="-Wl,-z,max-page-size=16384" \
  STRIP=llvm-strip AR=llvm-ar NM=llvm-nm LINK=llvm-link OBJDUMP=llvm-objdump DLLTOOL=llvm-dlltool RANLIB=llvm-ranlib
make && make install
if [ $? -ne 0 ]; then
  echo Failed to build libwebp.
  exit 1
fi
cd "$LIBWEBP_OUTPUT_DIR/install/lib" && llvm-strip *.so && cp libsharpyuv.so libwebp.so libwebpmux.so $OUTPUT_DIR/libs

# 构建 libav
check_dir_available "$LIBAV_OUTPUT_DIR/build"
mkdir -p "$LIBAV_OUTPUT_DIR/build" && cd "$LIBAV_OUTPUT_DIR/build"
$LIBAV_SRC_DIR/configure --prefix=$LIBAV_OUTPUT_DIR/install \
  --enable-cross-compile --target-os=android --arch=$cross_arch --sysroot=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
  --cc="clang -target $toolchain_target" --cxx="clang++ -target $toolchain_target" \
  --extra-cflags="-I$LIBWEBP_OUTPUT_DIR/install/include" --extra-cxxflags="-I$LIBWEBP_OUTPUT_DIR/install/include" --extra-ldflags="-L$OUTPUT_DIR/libs -Wl,-z,max-page-size=16384" --extra-libs="-lsharpyuv -lwebpmux -lwebp" \
  --nm=llvm-nm --ar=llvm-ar --pkg-config=pkg-config --strip=llvm-strip \
  --enable-shared --disable-static --enable-small --disable-programs --disable-doc --disable-avdevice --disable-swresample --disable-avfilter --disable-pthreads --disable-network \
  --disable-everything --enable-encoder=libwebp_anim --enable-decoder=mjpeg --enable-muxer=image2  --enable-demuxer=concat --enable-demuxer=image2 --enable-protocol=file \
  --enable-libwebp --disable-amf --disable-audiotoolbox --disable-cuda-llvm --disable-cuvid --disable-d3d11va --disable-d3d12va --disable-dxva2 --disable-ffnvcodec \
  --disable-libdrm --disable-nvdec --disable-nvenc --disable-v4l2-m2m --disable-vaapi --disable-vdpau --disable-videotoolbox --disable-vulkan \
  --disable-asm --disable-altivec --disable-vsx --disable-power8 --disable-amd3dnow --disable-amd3dnowext --disable-mmx --disable-mmxext \
  --disable-sse --disable-sse2 --disable-sse3 --disable-ssse3 --disable-sse4 --disable-sse42 --disable-avx --disable-xop --disable-fma3 --disable-fma4 --disable-avx2 --disable-avx512 --disable-avx512icl \
  --disable-aesni --disable-armv5te --disable-armv6 --disable-armv6t2 --disable-vfp --disable-neon --disable-dotprod --disable-i8mm \
  --disable-inline-asm --disable-x86asm --disable-mipsdsp --disable-mipsdspr2 --disable-msa --disable-mipsfpu --disable-mmi --disable-lsx --disable-lasx --disable-rvv
make && make install
if [ $? -ne 0 ]; then
  echo Failed to build libwebp.
  exit 1
fi
cd "$LIBAV_OUTPUT_DIR/install/lib" && cp *.so $OUTPUT_DIR/libs