#!/usr/bin/env bash
echo "Cloning dependencies"
git clone https://github.com/flaahokiller/flasho_Ysl -b  MaD
cd flasho_Ysl
git clone --depth=1 https://github.com/flaahokiller/toolchain-4.9 $gccDir gcc
git clone https://github.com/mvaisakh/gcc-arm64 $gcc64Dir gcc
git clone https://github.com/mvaisakh/gcc-arm $gcc32Dir gcc32
git clone https://github.com/flaahokiller/Anykernel3 AnyKernel
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%Y-%m-%d")
TGL=$(date +"%m%d")
START=$(date +"%s")
COMMIT=$(git log --pretty=format:'%h' -1)
FOR="YSL"
COMPILE=CLANG
KERNELNAME="flasho"
KERNEL_DIR=$(pwd)
VERSI=(""4.9.$(cat "$(pwd)/Makefile" | grep "SUBLEVEL =" | sed 's/SUBLEVEL = *//g')$(cat "$(pwd)/Makefile" | grep "EXTRAVERSION =" | sed 's/EXTRAVERSION = *//g')"")
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}" 
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')" 
export ARCH=arm64
export KERNELNAME=flasho-kernel
export KBUILD_BUILD_USER="mohit"
export KBUILD_BUILD_HOST=localhost-LA.UM.8.2.r2-04400-sdm625.0
export TOOLCHAIN=clang
export DEVICES=Ysl
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgUAAxkBAAE9e_hf4ni0FG6dpiFsRitnZaxzsKgpUwAC7QUAAvjGxQqGelaM9skzox4E" \
        -d chat_id=$chat_id
}        
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• flasho_ysl Kernel •</b>%0ABuild started on <code>Circle CI</code>%0AFor device <b>Zenfone Max Pro M2</b> (ASUS_X01BD)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#STABLE"
}         
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Zenfone Max Pro M2 (ASUS_X01BD)</b> | <b>$(${CLANG}clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
    make O=out ARCH=arm64 ysl-perf_defconfig
    make -j$(nproc --all) O=out \
                    ARCH=arm64 \
                    SUBARCH=arm64 \
                    CC=clang \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                    AR=llvm-ar \
                    NM=llvm-nm \
                    OBJCOPY=llvm-objcopy \
                    OBJDUMP=llvm-objdump \
                    STRIP=llvm-strip \
                    CLANG_TRIPLE=aarch64-linux-gnu-
                    
    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [$FOR]${VERSI}-${KERNELNAME}.zip *
    cd ..
}
sticker
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
