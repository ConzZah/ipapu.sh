#!/usr/bin/env sh

### /// ipapu.sh // ConzZah // 2026-09-24 02:32 ///

## DESCRIPTION:
## push .ipa files to your android device via adb for use with touchhle.

ipa=""
device=""
touchhle=""
touchhle_apps="/sdcard/Android/data/org.touchhle.android/files/touchHLE_apps/"
touchhle_launch="am start org.touchhle.android/org.touchhle.android.MainActivity"
touchhle_kill="am force-stop org.touchhle.android"

## depcheck
deps="tr adb sed cut rev grep curl unzip"
missing_deps=""
for dep in $deps; do
! command -v "$dep" >/dev/null && missing_deps="$dep $missing_deps"
done

## if we have any $missing_deps, tell the user which are missing & exit.
[ -n "$missing_deps" ] && printf '\n%s\n\n%s\n\n' "--> DEPENDENCIES MISSING:" "$missing_deps" && exit 1

## logo
## (generated with: https://patorjk.com/software/taag/)
## (font: babyface leet)
printf '%s\n' '
   ________  ________  ________  ________  ________  ________  ________ 
  ╱        ╲╱        ╲╱        ╲╱        ╲╱    ╱   ╲╱        ╲╱    ╱   ╲
 _╱       ╱╱         ╱         ╱         ╱         ╱        _╱         ╱
╱         ╱       __╱         ╱       __╱         ╱-        ╱         ╱ 
╲________╱╲______╱  ╲___╱____╱╲______╱  ╲________╱╲________╱╲___╱____╱ 

             === /// ipapu.sh // ConzZah \\ 2026 \\\ ==='

## check if any input was provided
[ -z "$1" ] && printf '\n%s\n\n' "--> ERROR: PLEASE PROVIDE A .IPA FILE" && exit 1

## check if the provided input is a .ipa file, and exit if it's not.
[ -n "$1" ] && [ -f "$1" ] && [ "ipa" = "$(printf '%s\n' "$1"| rev| cut -d '.' -f 1| rev)" ] && ipa="$1"
[ -z "$ipa" ] && printf '\n%s\n\n' "--> ERROR: INPUT PROVIDED IS NOT A .IPA FILE" && exit 1

## ensure adb is running
adb start-server

## tell the user we're waiting for a device to connect.
device="$(adb devices| sed '1d'| grep 'device'| head -n 1 |cut -f 1)"
[ -z "$device" ] && printf '\n%s\n' "--> WAITING FOR ANDROID DEVICE TO CONNECT.."

adb wait-for-device && {
printf '\n%s\n' "--> ANDROID DEVICE CONNECTED!"

## check if we have touchhle installed, and install it, if it couldn't be found.
touchhle="$(adb shell pm list packages -3| grep -o 'org.touchhle.android')"

[ "org.touchhle.android" != "$touchhle" ] && \
printf '\n%s\n\n%s\n\n' "--> ERROR: TOUCHHLE DOESN'T SEEM TO BE INSTALLED ON YOUR ANDROID DEVICE." "--> DOWNLOADING LATEST.." && \
{

## find out what the $latest version is
latest="$(curl -sLI 'https://github.com/touchHLE/touchHLE/releases/latest'| grep 'location'| rev| cut -d '/' -f 1| rev| tr -d '\r')"

## create tmpdir
mkdir -p '/tmp/touchhle'
cd '/tmp/touchhle' || exit 1

## download the latest version
curl -#Lo "touchhle_latest.zip" "https://github.com/touchHLE/touchHLE/releases/download/${latest}/touchHLE_${latest}_Android_AArch64.zip" || exit 1

## unzip and delete the archive
unzip -o 'touchhle_latest.zip' 'touchHLE.apk' || exit 1
rm -f 'touchhle_latest.zip'

## install the apk (exit if unsuccessful)
! adb install -r 'touchHLE.apk' && exit 1
rm -f 'touchHLE.apk'
cd - >/dev/null || exit 1
}

## check if the touchHLE_apps dir exists.
## if it doesn't, then the app hasn't been started yet.
## start the app to let it create the touchHLE_apps dir, and kill it after 1 second
! adb shell "ls $touchhle_apps" >/dev/null 2>&1 && {
printf '\n%s\n' "--> PERFORMING FIRST-RUN.."
adb shell "$touchhle_launch" >/dev/null
sleep 1
adb shell "$touchhle_kill" >/dev/null
}

## push the .ipa file to the device.
printf '\n%s\n\n'  "--> PUSHING: '$ipa'"
adb push "$ipa" "$touchhle_apps" && \
printf '\n%s\n\n' "--> SUCCESS" && exit 0 || \
printf '\n%s\n\n' "--> FAILURE" && exit 1
}
