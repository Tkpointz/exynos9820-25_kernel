#! /bin/bash

DATE=$(TZ=GMT-8 date +"%Y%m%d-%H%M")

MODEL="Samsung galaxy Note 10 plus"

DEVICE="d2s"

NAME="sploitpay-v1"

CHATID="-1001555864767"

TOKEN=$1

KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

PROCS=$(nproc --all)

BOT_MSG_URL="https://api.telegram.org/bot$TOKEN/sendMessage"
BOT_BUILD_URL="https://api.telegram.org/bot$TOKEN/sendDocument"

tg_post_msg() {
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$1"

}

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

build_kernel() {
tg_post_msg "<b>Build Triggered</b>%0A<b>OS: </b><code>Ubuntu</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=GMT-8 date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler used: </b><code>Clang</code>%0A<b>Top Commit : </b><code>$COMMIT_HEAD</code>"
chmod +x build.py
./build.py build model=N975F name="$NAME" toolchain=system-clang

if [ -f arch/arm64/boot/Image-N975F ]
then
	echo "Kernel Successfully Compiled"
else
	echo "Kernel Compilation Failed!"
	tg_post_msg "<code>Kernel Compilation Failed</code>"
	exit

fi

}

build_image_dtbo() {
wget -q https://android.googlesource.com/platform/system/tools/mkbootimg/+archive/refs/heads/master.tar.gz -O - | tar xzf - mkbootimg.py
./mkbootimg.py --header_version=1 --os_version=11.0.0 --os_patch_level=2021-09 --board=SRPSC14B006KU --pagesize=2048 --cmdline=androidboot.selinux=permissive --base=0x10000000 --kernel_offset=0x00008000 --ramdisk_offset=0x00000000 --second_offset=0x00000000 --tags_offset=0x00000100 --kernel=arch/arm64/boot/Image-N975F -o arch/arm64/boot/N975F.img

#wget -q https://android.googlesource.com/platform/system/libufdt/+archive/refs/heads/master.tar.gz -O - | tar --strip-components 2 -xzf - utils/src/mkdtboimg.py
#./mkdtboimg.py cfg_create --dtb-dir=arch/arm64/boot/dts/samsung  arch/arm64/boot/dtbo-N975F.img cruel/dtbo.N975F

}

generate_zip() {
# cloning anykernel

git clone https://github.com/Tkpointz/AnyKernel3.git -b exynos9820

# cloning flashable module zip

git clone https://github.com/Tkpointz/sploitpay_kernel_modules.git modules

#moving output files to flashable zip

mv arch/arm64/boot/N975F.img AnyKernel3/
mv drivers/staging/rtl8812au/88XXau.ko modules/system/lib/modules
mv drivers/staging/rtl8814au/8814au.ko modules/system/lib/modules
mv drivers/staging/rtl8188eus/8188eu.ko modules/system/lib/modules
mv drivers/staging/rtl8821CU/8821cu.ko modules/system/lib/modules

#mv arch/arm64/boot/dtbo-N975F.img AnyKernel3/

cd AnyKernel3

zip -r Sploitpay-d2s-"$DATE" . -x ".git*" -x "README.md" -x "*.zip" -x "*.jar"

ZIP_FINAL="Sploitpay-d2s-$DATE"

}

zip_post() {
# post kernel zip file
tg_post_build "$ZIP_FINAL.zip" "$Date"

# generating modules zip
cd ..
cd modules/
zip -r Sploitpay-d2s-Modules-"$DATE" . -x ".git*" -x "README.md" -x "*.zip" -x "*.jar"
ZIP_MODULES="Sploitpay-d2s-Modules-$DATE"

#post modules zip file
tg_post_build "$ZIP_MODULES.zip"

}

build_kernel
build_image_dtbo
generate_zip
zip_post
