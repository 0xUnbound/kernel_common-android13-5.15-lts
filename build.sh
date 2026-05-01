#!/bin/bash
#
# Copyright (C) 2023 ZHANtech™
# Modified By Masood-J 
#

WORK_DIR="${PWD}"
KERNEL_DIR="tapas"
DISTRO=$(source /etc/os-release && echo ${NAME})
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "local")
COMMIT_HEAD=$(git log --oneline -1 2>/dev/null || echo "unknown")
ANYKERNEL3_DIR="${HOME}/kernel/anykernel"
CLANG_VERSION="clang-r547379"
TC_DIR="prebuilts/clang/host/linux-x86"
OUT_DIR="out/android13-5.15/dist"

# Repo URL
ANYKERNEL_REPO="https://github.com/SM6225-Android-Playground/AnyKernel3"
ANYKERNEL_BRANCH="topaz"

# Customize
KERNEL="EcstasyKernel"
RELEASE_VERSION="V1.2"
DEVICE="Topaz-Tapas"
BENGAL_DEVICE="Bengal"
KERNELNAME="${KERNEL}-${RELEASE_VERSION}-${BRANCH}-${DEVICE}-$(TZ=Asia/Jakarta date +%y%m%d)"
BENGAL_KERNELNAME="${KERNEL}-${RELEASE_VERSION}-${BRANCH}-${BENGAL_DEVICE}-$(TZ=Asia/Jakarta date +%y%m%d)"
FINAL_KERNEL_ZIP="${KERNELNAME}.zip"
FINAL_KERNEL_IMG="${BENGAL_KERNELNAME}.img"

function clean() {
    rm -rf "${HOME}/kernel"
    rm -rf "${WORK_DIR}/out"
}

function cloning() {
    if ! [ -d "${TC_DIR}/${CLANG_VERSION}" ]; then
        echo "Clang not found! Cloning to ${TC_DIR}..."
        mkdir -p "${TC_DIR}/${CLANG_VERSION}"
        cd "${TC_DIR}/${CLANG_VERSION}" || exit
        wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/${CLANG_VERSION}.tar.gz
        tar -xf ${CLANG_VERSION}.tar.gz
        rm ${CLANG_VERSION}.tar.gz
        cd "${WORK_DIR}"
    fi
}

function compile_kernel() {
    echo "<b>STARTING KERNEL BUILD</b>"
    echo "OS: ${DISTRO} | Device: ${DEVICE} | Compiler: ${CLANG_VERSION}"
    
    export KBUILD_BUILD_USER="@skeptical_kk"
    export KBUILD_BUILD_HOST="localhost"

    START=$(TZ=Asia/Jakarta date +"%s")
    LTO=thin BUILD_CONFIG=${KERNEL_DIR}/build.config.gki.aarch64 build/build.sh

    # Check If compilation is success
    if ! [ -f "${OUT_DIR}/Image" ]; then
        END=$(TZ=Asia/Jakarta date +"%s")
        DIFF=$(( END - START ))
        echo -e "Kernel compilation failed in $((DIFF / 60)) min $((DIFF % 60)) sec. See buildlog to fix errors."
        exit 1
    fi
}

function ziping() {
    cd "${WORK_DIR}"
    mkdir -p "${HOME}/kernel"
    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "$ANYKERNEL3_DIR"

    echo "**** Copying Image ****"
    cp "${OUT_DIR}/Image" "${ANYKERNEL3_DIR}/Image"
    [ -f "${OUT_DIR}/boot.img" ] && cp "${OUT_DIR}/boot.img" "${HOME}/kernel/${FINAL_KERNEL_IMG}"

    echo "**** Time to zip up! ****"
    cd "${ANYKERNEL3_DIR}" || exit
    zip -r9 "${HOME}/kernel/${FINAL_KERNEL_ZIP}" * -x README "${FINAL_KERNEL_ZIP}"
    
    echo "**** Done, here is your sha1 ****"
    sha1sum "${HOME}/kernel/${FINAL_KERNEL_ZIP}"
}

# eksekusi
echo ".........................."
echo ".     Clean Directory    ."
echo ".........................."
clean
echo ".........................."
echo ".     Cloning            ."
echo ".........................."
cloning
echo ".........................."
echo ".     Building Kernel    ."
echo ".........................."
compile_kernel
echo ".........................."
echo ".     Ziping Kernel      ."
echo ".........................."
ziping
