# Configuring Ubuntu 16.04 LTS Dev Environment

### Additional Resources
1. https://source.android.com/source/requirements
2. http://variwiki.com/index.php?title=DART-SD410

### Download Ubuntu 16.04 iso
https://www.ubuntu.com/download/alternative-downloads

### Preliminary steps for macOS Parallels users only
1. Open the Parallels Control Center and click on the *+* symbol in the top-right corner
2. Select the "Install Windows or another OS from DVD or image file" and click *Continue*
3. Drag an ubuntu 16.04 LTS iso into the "Installation Assistant" window and click *Continue*
4. Type in a password and click *Continue*
5. Check the "Customize settings before installation" checkbox and click *Create*
6. In the "Configuration" window, click on the *Hardware* tab
7. Bump up the memory to 4096MB at the minimum if you can
8. Bump up the graphics memory to 512 MB if you can
9. Under "Hard Disk", open the "Advanced Settings" and click on *Properties*
10. Drag the slider to 512 GB if you can and click *Apply*
11. Under "Mouse & Keyboard", make sure *Don't optimize for games* is selected
12. Close the "Configuration" window and click *Continue*
13. Once Ubuntu is up and running, install Parallels Tools by clicking on the yellow icon in the top-right corner of the Ubuntu VM window

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
cd ~/Downloads/ \
&& wget -m --user=dart-sd410 --password=varSD410 ftp://ftp.variscite.com \
&& mv ~/Downloads/ftp.variscite.com ~/dart-sd410
```

### Download Google Repo Tool
```bash
mkdir ~/bin \
&& export PATH=~/bin:$PATH \
&& curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo \
&& chmod a+x ~/bin/repo
```

### Download and Install Android Studio
1. https://developer.android.com/studio/index.html
2. Click the big download button and accept the license
3. When prompted, click "Open with Archive Manager", extract to Downloads folder and then run:
```bash
sudo mv ~/Downloads/android-studio ~/android-studio/
```
4. Run Android Studio:
```bash
~/android-studio/bin/studio.sh &
```
5. In the Android Studio Setup Wizard, click Custom
6. Use Defaults, keep clicking Next
7. On the Welcome to Android Studio screen, click the Configure option at the bottom and open the SDK Manager
8. Inside the "SDK Platforms" tab, uncheck all boxes except for API level *22* under "SDK Platforms"; hit apply
9. Switch to the "SDK Tools" tab and check the boxes for *CMake* and uncheck all Android SDK Build-Tools versions except *24.0.3* (check Show Package Details to see all the options); hit apply (do NOT install NDK here, that comes next)

### Download Android NDK r16b
```bash
rm -rf ~/Android/Sdk/ndk-bundle/ \
&& cd ~/Downloads/ \
&& curl -o android-ndk.zip -L https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip \
&& sudo unzip android-ndk.zip -d ~/Android/Sdk/ \
&& mv ~/Android/Sdk/android-ndk-r16b ~/Android/Sdk/ndk-bundle \
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

### Make sure you are authorized for SciAps repositories
[more on this here](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux)

Before running this command, change "Stephen Gowen" and "dev.sgowen@gmail.com" accordingly:
```bash
git config --global user.name "Stephen Gowen" \
&& git config --global user.email "dev.sgowen@gmail.com" \
&& ssh-keygen -t rsa -N "" -b 4096 -C "dev.sgowen@gmail.com" -f ~/.ssh/id_rsa \
&& eval "$(ssh-agent -s)" \
&& ssh-add ~/.ssh/id_rsa \
&& xclip -sel clip < ~/.ssh/id_rsa.pub \
&& xdg-open https://github.com/settings/ssh/new
```

1. Log in to GitHub, and then paste your clipboard into the Key box
2. Type Ubuntu AOSP into the Title box
3. Click *Add SSH key*
4. Restart your Ubuntu VM
5. Wait at least a full minute before proceeding

### Initialize and repo sync the SciAps fork of the Android 5.1.1 Firmware
```bash
cd ~/dart-sd410 \
&& unzip ~/dart-sd410/Software/Android/Android_5/LL.1.2.4-01810-8x16.0-3/variscite_bsp_vla.br_.1.2.4-01810-8x16.0-3.zip \
&& curl https://raw.githubusercontent.com/SciAps/DART-SD410-manifest/master/SD410c_build.sh?token=ADwDDSTgbl43iQmd-72CLYMFq39YsaRkks5cN5G3wA%3D%3D > ~/dart-sd410/source/SD410c_build.sh \
&& cd source/ \
&& chmod +x SD410c_build.sh \
&& ./SD410c_build.sh
```

### Rebuilding Everything
```bash
cd ~/dart-sd410/source/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_5.1.1_Lollipop_P2 \
&& . build/envsetup.sh \
&& lunch full_chem200-eng \
&& m -j14 WITH_DEXPREOPT=true WITH_DEXPREOPT_PIC=true DEX_PREOPT_DEFAULT=nostripping | tee log.txt
```

### Rebuilding the Kernel
```bash
cd ~/dart-sd410/source/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_5.1.1_Lollipop_P2 \
&& . build/envsetup.sh \
&& lunch full_chem200-eng \
&& m kernel
```

### Build Notes
If you encounter this error:
"You have tried to change the API from what has been previously approved"
just run:
```bash
make update-api
```
as specified in the message.

If you encounter this error:
"error: unsupported reloc 43"
just run:
```bash
cp /usr/bin/ld.gold prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6/x86_64-linux/bin/ld
```

### System Notes
If you see "Insufficient Permissions" when using adb, just run:
```bash
adb kill-server && sudo adb start-server
```

If you see "Read only file system" when attempting to push files onto the device, just adb shell in and then run:
```bash
mount -o rw,remount / \
&& mount -o rw,remount /system \
&& exit
```

### Flashing
First, reboot the device into the bootloader:
```bash
adb reboot bootloader
```
Wait for fastboot, run this command until you see a device displayed:
```bash
sudo fastboot devices
```
Flash and Boot the Entire System!
```bash
RESCUE_IMAGES_ROOT=~/dart-sd410/Software/Android/Android_5/RescueImages \
&& cd $RESCUE_IMAGES_ROOT \
&& sudo fastboot flash partition gpt_both0.bin \
&& sudo fastboot flash hyp hyp.mbn \
&& sudo fastboot flash modem NON-HLOS.bin \
&& sudo fastboot flash rpm rpm.mbn \
&& sudo fastboot flash sbl1 sbl1.mbn \
&& sudo fastboot flash sec sec.dat \
&& sudo fastboot flash tz tz.mbn \
&& sudo fastboot flash sbl1bak sbl1.mbn \
&& sudo fastboot flash hypbak hyp.mbn \
&& sudo fastboot flash rpmbak rpm.mbn \
&& sudo fastboot flash tzbak tz.mbn \
&& sudo fastboot erase cache \
&& sudo fastboot erase devinfo \
&& AOSP_ROOT=~/dart-sd410/source/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_5.1.1_Lollipop_P2 \
&& cd $AOSP_ROOT/out/target/product/chem200/ \
&& sudo fastboot flash aboot emmc_appsboot.mbn \
&& sudo fastboot flash abootbak emmc_appsboot.mbn \
&& sudo fastboot flash persist persist.img \
&& sudo fastboot flash userdata userdata.img \
&& sudo fastboot flash system system.img \
&& sudo fastboot flash recovery recovery.img \
&& sudo fastboot flash boot boot.img \
&& sudo fastboot reboot
```

Flash just the Linux Kernel and Boot!
```bash
AOSP_ROOT=~/dart-sd410/source/APQ8016_410C_LA.BR.1.2.4-01810-8x16.0_5.1.1_Lollipop_P2 \
&& cd $AOSP_ROOT/out/target/product/chem200/ \
&& sudo fastboot flash boot boot.img \
&& sudo fastboot reboot
```
