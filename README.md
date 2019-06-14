# Configuring Ubuntu 14.04 LTS Dev Environment

### Additional Resources
1. https://source.android.com/source/requirements
2. http://variwiki.com/index.php?title=DART-SD410

### Download Ubuntu 14.04 iso
https://s3.us-east-2.amazonaws.com/sciaps-ubuntu/ubuntu-14.04.5-desktop-amd64.iso

### Preliminary steps for macOS Parallels users only
1. Open the Parallels Control Center and click on the *+* symbol in the top-right corner
2. Select the "Install Windows or another OS from DVD or image file" and click *Continue*
3. Drag an ubuntu 14.04 LTS iso into the "Installation Assistant" window and click *Continue*
4. Type in a password and click *Continue*
5. Check the "Customize settings before installation" checkbox and click *Create*
6. In the "Configuration" window, click on the *Hardware* tab
7. Bump up the memory to 4096MB at a minimum if you can
8. Bump up the graphics memory to 512 MB
9. Under "Hard Disk", open the "Advanced Settings" and click on *Properties*
10. Drag the slider to 256 GB and click *Apply*
11. Under "Mouse & Keyboard", make sure *Don't optimize for games* is selected
12. Close the "Configuration" window and click *Continue*
13. Once Ubuntu is up and running, install Parallels Tools by clicking on the yellow icon in the top-right corner of the Ubuntu VM window
14. IMPORTANT - After installation is complete, you will be on kernel 4.4.0-31-generic -- DO NOT UPGRADE, 4.4.0-143 is not supported by Parallels Tools yet!

### Download Packages
```bash
sudo add-apt-repository ppa:openjdk-r/ppa
```
```bash
sudo add-apt-repository ppa:nilarimogard/webupd8
```
```bash
sudo apt-get update
```
```bash
sudo apt-get -y install build-essential libc6:i386 libncurses5:i386 libstdc++6:i386 libbz2-1.0:i386 git-core gnupg zip zlib1g-dev gcc-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev xsltproc unzip libswitch-perl default-jre u-boot-tools mtd-utils lzop xorg-dev libopenal-dev libglew-dev libalut-dev xclip python ruby-dev openvpn minicom curl gperf bison android-tools-adb android-tools-fastboot android-tools-fsutils git g++-multilib lib32z1 libxml2-utils openjdk-7-jdk flex mkisofs bc
```

### Download Variscite Resources
```bash
cd ~/Downloads \
&& wget -m --user=dart-sd410 --password=varSD410 ftp://ftp.variscite.com \
&& mv ~/Downloads/ftp.variscite.com ~/dart-sd410
```

### Download Google Repo Tool
```bash
mkdir -p ~/bin \
&& export PATH=~/bin:$PATH \
&& curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo \
&& chmod a+x ~/bin/repo
```

### Make sure you are authorized for SciAps repositories
[more on this here](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux)

Before running this command, define FULL_NAME and EMAIL accordingly:
```bash
FULL_NAME="Stephen Gowen" \
&& EMAIL="dev.sgowen@gmail.com" \
&& git config --global user.name "$FULL_NAME" \
&& git config --global user.email "$EMAIL" \
&& ssh-keygen -t rsa -N "" -b 4096 -C "$EMAIL" -f ~/.ssh/id_rsa \
&& eval "$(ssh-agent -s)" \
&& ssh-add ~/.ssh/id_rsa \
&& xclip -sel clip < ~/.ssh/id_rsa.pub \
&& xdg-open https://github.com/settings/ssh/new
```

1. Log in to GitHub, and then paste your clipboard into the Key box
2. Type Ubuntu AOSP into the Title box
3. Click *Add SSH key*

### Download and Install Android Studio
1. https://developer.android.com/studio/index.html
2. Click the big download button and accept the license
3. When prompted, click "Open with Archive Manager", extract to Home folder and then run:
```bash
~/android-studio/bin/studio.sh &
```
4. In the Android Studio Setup Wizard, click Custom
5. Use Defaults, keep clicking Next
6. On the Welcome to Android Studio screen, click the Configure option at the bottom and open the SDK Manager
7. Inside the "SDK Platforms" tab, uncheck all boxes except for API level *22* under "SDK Platforms"; hit apply
8. Switch to the "SDK Tools" tab and check the boxes for *CMake* and uncheck all Android SDK Build-Tools versions except *24.0.3* (check Show Package Details to see all the options); hit apply (do NOT install NDK here, that comes next)

### Download Android NDK r12b
```bash
rm -rf ~/Android/Sdk/ndk-bundle/ \
&& cd ~/Downloads/ \
&& curl -o android-ndk.zip -L https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip \
&& sudo unzip android-ndk.zip -d ~/Android/Sdk/ \
&& mv ~/Android/Sdk/android-ndk-r12b ~/Android/Sdk/ndk-bundle \
&& rm android-ndk.zip \
&& sudo chmod -R 777 ~/Android/Sdk/ndk-bundle/* \
&& sudo chmod -R 777 ~/Android/Sdk/ndk-bundle
```

### Configure Environment Variables
```bash
sudo sh -c 'echo "ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk-bundle/" >> /etc/environment'
```

### Unless you have 16G of Ram, you will need swap memory
[more on this here](https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04)
```bash
sudo fallocate -l 16G /swapfile \
&& sudo chmod 600 /swapfile \
&& sudo mkswap /swapfile \
&& sudo swapon /swapfile
```

Make the Swap File Permanent:
```bash
sudo nano /etc/fstab
```

At the bottom of the file, you need to add a line that will tell the operating system to automatically use the file you created:
/swapfile   none    swap    sw    0   0

Hit CTRL+X and then Y to save and exit, and your swap is good to go.

### Download projects via repo sync
```bash
AOSP_ROOT=~/dart-sd410/source \
&& mkdir -p $AOSP_ROOT \
&& cd $AOSP_ROOT \
&& repo init -u git@github.com:SciAps/DART-SD410-manifest.git --repo-url=git://codeaurora.org/tools/repo.git \
&& repo sync -j8 \
&& repo forall -c "git checkout -b master" \
&& repo forall -c "git checkout -b LA.BR.1.2.4-01810-8x16"
```

Enter **yes** 2 times when prompted, then hit **[ENTER]** at the Your Name/Email prompts, then enter **y** 2 times to continue

If you are building for the *ngx*, you will need to switch your kernel branch to **LA.BR.1.2.4-01810-8x16_NGX** until we figure out how to get Kconfig and dtsi files to play nicely with one another.

Also, feel free to run repo sync whenever you want to pull the latest!

### Building (define TARGET as *chem200* or *ngx*, and NUM_THREADS as your number of CPU cores times 2)
```bash
NUM_THREADS=8 \
&& TARGET=ngx \
&& cd ~/dart-sd410/source/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_5.1.1_Lollipop_P2 \
&& . build/envsetup.sh \
&& lunch $TARGET-eng \
&& make update-api \
&& m -j$NUM_THREADS WITH_DEXPREOPT=true WITH_DEXPREOPT_PIC=true DEX_PREOPT_DEFAULT=nostripping | tee log.txt
```

The above command may fail on a linker step. If so, just re-run the command on a single thread (below).

### Rebuilding (same as the previous command, but on a single thread | define TARGET as *chem200* or *ngx*)
```bash
TARGET=ngx \
&& cd ~/dart-sd410/source/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_5.1.1_Lollipop_P2 \
&& . build/envsetup.sh \
&& lunch $TARGET-eng \
&& m WITH_DEXPREOPT=true WITH_DEXPREOPT_PIC=true DEX_PREOPT_DEFAULT=nostripping | tee log.txt
```

### System Notes
If you see *Insufficient Permissions* when using adb, just run:
```bash
adb kill-server && sudo adb start-server
```
If you see *Read only file system* when attempting to push files onto the device, just run:
```bash
adb -d shell mount -o rw,remount / && adb -d shell mount -o rw,remount /system
```

### Flashing (define TARGET as *chem200* or *ngx*)
Reboot the device into the bootloader:
```bash
adb wait-for-device && adb reboot bootloader
```
Flash the System and Boot!
```bash
TARGET=ngx \
&& RESCUE_IMAGES_ROOT=~/dart-sd410/Software/Android/Android_5/RescueImages \
&& AOSP_ROOT=~/dart-sd410/source/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_5.1.1_Lollipop_P2 \
&& BUILT_IMAGES_DIR=$AOSP_ROOT/out/target/product/$TARGET \
&& sudo fastboot erase DDR \
&& sudo fastboot erase aboot \
&& sudo fastboot erase abootbak \
&& sudo fastboot erase boot \
&& sudo fastboot format cache \
&& sudo fastboot erase config \
&& sudo fastboot erase devinfo \
&& sudo fastboot erase fsc \
&& sudo fastboot erase fsg \
&& sudo fastboot erase hyp \
&& sudo fastboot erase hypbak \
&& sudo fastboot erase keystore \
&& sudo fastboot erase misc \
&& sudo fastboot erase modem \
&& sudo fastboot erase modemst1 \
&& sudo fastboot erase modemst2 \
&& sudo fastboot erase oem \
&& sudo fastboot erase persist \
&& sudo fastboot erase recovery \
&& sudo fastboot erase rpm \
&& sudo fastboot erase rpmbak \
&& sudo fastboot erase sbl1 \
&& sudo fastboot erase sbl1bak \
&& sudo fastboot erase sec \
&& sudo fastboot erase ssd \
&& sudo fastboot format system \
&& sudo fastboot erase tz \
&& sudo fastboot erase tzbak \
&& sudo fastboot format userdata \
&& cd $RESCUE_IMAGES_ROOT \
&& sudo fastboot flash partition gpt_both0.bin \
&& sudo fastboot flash hyp hyp.mbn \
&& sudo fastboot flash hypbak hyp.mbn \
&& sudo fastboot flash modem NON-HLOS.bin \
&& sudo fastboot flash rpm rpm.mbn \
&& sudo fastboot flash rpmbak rpm.mbn \
&& sudo fastboot flash sbl1 sbl1.mbn \
&& sudo fastboot flash sbl1bak sbl1.mbn \
&& sudo fastboot flash sec sec.dat \
&& sudo fastboot flash tz tz.mbn \
&& sudo fastboot flash tzbak tz.mbn \
&& cd $BUILT_IMAGES_DIR \
&& sudo fastboot flash boot boot.img \
&& sudo fastboot flash cache cache.img \
&& sudo fastboot flash aboot emmc_appsboot.mbn \
&& sudo fastboot flash abootbak emmc_appsboot.mbn \
&& sudo fastboot flash persist persist.img \
&& sudo fastboot flash recovery recovery.img \
&& sudo fastboot flash system system.img \
&& sudo fastboot flash userdata userdata.img \
&& sudo fastboot reboot
```
