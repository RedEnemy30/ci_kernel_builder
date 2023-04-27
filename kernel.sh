#!/bin/bash

# Changing directory to a folder
cd /tmp/rom

# Replace with your kernel link and branch
KT_LINK=https://github.com/popoA3M/android_kernel_10or_E #your_kernel_link
KT_BRANCH=13 #your_branch

# Cloning kernel
git clone $KT_LINK -b $KT_BRANCH --depth=1 --single-branch

#tg
tg(){
	curl -s "https://api.telegram.org/bot5257990735:AAFy_Paa75GL8qsGTXCWMM4ImX8eY9H0icE/sendmessage" --data "text=$msg&chat_id=5140615328&parse_mode=html"
}
id=5140615328 
tg $id "kernel compile status: triggered!"

cd *

# Beginning compilation
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 10G
ccache -o compression=true
ccache -z

SECONDS=0 # builtin bash timer
ZIPNAME="Aura-$(date '+%Y%m%d-%H%M').zip" #your_kernel_name
TC_DIR="$HOME/tc/proton-clang"
DEFCONFIG="holland1_defconfig" #your_defconfig
export KBUILD_BUILD_USER=popoASM #your_name
export KBUILD_BUILD_HOST=Cirrus-CI
export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
	echo "Proton clang not found! Cloning to $TC_DIR..."
	if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang "$TC_DIR"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	exit 1
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j"$(nproc --all)" O=out ARCH=arm64 CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if ! git clone -q https://github.com/popoASM-World/AnyKernel3 -b aura; then #your_anykernel3_fork
		echo -e "\nCloning AnyKernel3 repo failed! Aborting..."
		exit 1
	fi
	cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
        #cp out/arch/arm64/boot/dtbo.img AnyKernel3 #edit_it_if_you_want_to_add_dtbo_in_your_kernel
	rm -f ./*zip
	cd AnyKernel3 || exit
	rm -rf out/arch/arm64/boot
	zip -r9 "../$ZIPNAME" ./* -x '*.git*' README.md ./*placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	curl -F document=@"$ZIPNAME" "https://api.telegram.org/bot5257990735:AAFy_Paa75GL8qsGTXCWMM4ImX8eY9H0icE/sendDocument" -F chat_id="5140615328" -F "parse_mode=Markdown" -F caption="*✅ Build finished after $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)*"
	echo
        curl -sL https://git.io/file-transfer | sh
        ./transfer anon $ZIPNAME
else
	echo -e "\nCompilation failed!"
fi
