#!/bin/bash 

#Copyright © 2015, Qualcomm Innovation Center, Inc. All rights reserved.  Confidential and proprietary. 
BUILD_MACHINE="8"
ITCVER="5.1.1_Lollipop_P2"
WORKDIR=`pwd`
BUILDROOT="$WORKDIR/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_$ITCVER"
PATCH_DIR="$WORKDIR/PATCH_8x16_129905_410c_LA.BR.1.2.4-01810-8x16.0"
VAR_PATCH_DIR="$WORKDIR/Variscite"

function SD410_SOURCE_CODE() {
# Do repo sanity test
if [ $? -eq 0 ]
then
	echo "Downloading code please wait.."
	repo init -u git@github.com:SciAps/DART-SD410-manifest.git --repo-url=git://codeaurora.org/tools/repo.git
	repo sync -j$BUILD_MACHINE
	repo forall -c "git checkout -b master"
	repo forall -c "git checkout -b LA.BR.1.2.4-01810-8x16"
else
	echo "repo tool problem, make sure you have setup your build environment"
	echo "1) http://source.android.com/source/initializing.html"
	echo "2) http://source.android.com/source/downloading.html (Installing Repo Section Only)"
	exit -1
fi
}

# Function to autoapply patches to CAF code
Apply_android_patches()
{	cd $WORKDIR
	wget https://www.codeaurora.org/patches/quic/la/PATCH_8x16_129905_410c_LA.BR.1.2.4-01810-8x16.0.tar.gz
	tar -xvzf PATCH_8x16_129905_410c_LA.BR.1.2.4-01810-8x16.0.tar.gz
	rm -rf PATCH_8x16_129905_410c_LA.BR.1.2.4-01810-8x16.0/kernel
	cd $BUILDROOT
	echo "Applying patches ..."
	if [ ! -e $PATCH_DIR ]
	then
		echo -e "$PATCH_DIR : Not Found "
	fi
	cd $PATCH_DIR
	patch_root_dir="$PATCH_DIR"
	android_patch_list=$(find . -type f -name "*.patch" | sort) &&
	for android_patch in $android_patch_list; do
		android_project=$(dirname $android_patch)
		echo -e "applying patches on $android_project ... "
		cd $BUILDROOT/$android_project 
		if [ $? -ne 0 ]; then
			echo -e "$android_project does not exist in BUILDROOT:$BUILDROOT "
			exit 1
		fi
		git am --abort
		git am $patch_root_dir/$android_patch	
	done
}

# Function to autoapply Variscite patches to CAF code
Apply_variscite_patches()
{
	cd $WORKDIR
	git clone https://github.com/SciAps/DART-SD410-repo-patch Variscite
	git checkout LA.BR.1.2.4-01810-8x16
	cd $BUILDROOT
	echo "Applying variscite patches ..."
	if [ ! -e $VAR_PATCH_DIR ]
	then
		echo -e "$VAR_PATCH_DIR : Not Found "
	fi
	cd $VAR_PATCH_DIR
	patch_root_dir="$VAR_PATCH_DIR"
	android_patch_list=$(find . -type f -name "*.patch" | sort) &&
	for android_patch in $android_patch_list; do
		android_project=$(dirname $android_patch)
		echo -e "applying patches on $android_project ... "
		cd $BUILDROOT/$android_project 
		if [ $? -ne 0 ]; then
			echo -e "$android_project does not exist in BUILDROOT:$BUILDROOT "
			exit 1
		fi
		git am --abort
		git am $patch_root_dir/$android_patch	
	done
}

#  Function to check whether host utilities exists
check_program() {
for cmd in "$@"
do
	which ${cmd} > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo
		echo -e "Cannot find command \"${cmd}\" "
		echo
		exit 1
	fi
done
}

#Main Script starts here
#Note: Check necessary program for installation
echo
echo -e "$Variscite_DART-SD410 Release Version : $ITCVER "
echo -e "$Variscite_DART-SD410 Workdir                   : $WORKDIR "
echo -e "$Variscite_DART-SD410 Build Root                : $BUILDROOT "
echo -e "$Variscite_DART-SD410 Patch Dir                 : $PATCH_DIR "
echo -n "Checking necessary program for installation......"
echo
check_program tar repo git patch
if [ -e $BUILDROOT ]
then
	cd $BUILDROOT
else 
	mkdir $BUILDROOT
	cd $BUILDROOT
fi

#1 Download code
SD410_SOURCE_CODE
cd $BUILDROOT
#2 Apply APQ8016 410C Snapdragon Dragonboard patches
Apply_android_patches
#3 Binaries
cd $BUILDROOT
pwd
echo -e "   Extracting proprietary binary package to $BUILDROOT ... "
tar -xzvf ../proprietary_LA.BR.1.2.4_01810_8x16.0_410C_Nov.tgz -C vendor/qcom/
mv vendor/qcom/proprietary/WCNSS_qcom_wlan_nv.bin device/qcom/msm8916_64/
#4 Apply Variscite SD410 patches
Apply_variscite_patches
cp $VAR_PATCH_DIR/device/qcom/msm8916_64/bootanimation.zip $BUILDROOT/device/qcom/msm8916_64/
cd $BUILDROOT
#5 Build
source build/envsetup.sh 
lunch full_chem200-eng

make -j$BUILD_MACHINE WITH_DEXPREOPT=true WITH_DEXPREOPT_PIC=true DEX_PREOPT_DEFAULT=nostripping | tee log.txt
