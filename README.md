# OZO Audio Capture OnePlus 9 Pro Magisk Module

## DISCLAIMER
- OZO Audio Capture blobs are owned by Nokia™.
- The MIT license specified here is for the Magisk Module only, not for OZO Audio Capture blobs.

## Descriptions
- Audio quality enhancement for audio/video recordings ported from OnePlus 9 Pro (oneplus9pro) and integrated as a Magisk Module for all supported and rooted devices with Magisk
- Pre process type sound effect
- There is no user interface

## Sources
https://dumps.tadiphone.dev/dumps/oneplus/oneplus9pro qssi-user-11-RKQ1.201105.002-2111112053-release-keys

## Changelog

v1.6
- Support NoMount metamodule
- Resets module folders/files permissions at post-fs-data
- Move _uninstall.log to /data/adb/logs/

v1.5
- Fix wrong target in latest KernelSU

v1.4
- Remove useless c2 codec service
- Tidy up aml.sh
- Exclude \*audio\*effects\*haptic\*.xml
- Fix wrong file permissions in some ROMs
- Change module name

v1.3
- Improve /odm and /my_product support detection

v1.2
- Fix architecture detection in some weird ROMs
- Fix bug in uninstall.sh

v1.1
- Allow installation in Android Emulator

v1.0
- Fix "Cannot link executable" in some ROMs

v0.9
- Fix OZO Audio service in Android 14

v0.8
- Does not use media_codecs_ozo_audio.xml if it's already exist

v0.7
- Improve \*audio\*effects\*.xml patch detection

## Screenshots
https://t.me/androidryukimodsdiscussions/116460

## Requirements
- arm64-v8a or armeabi-v7a architecture
- HIDL audio service
- Magisk or Kitsune Mask or KernelSU or Apatch installed

## Installation Guide & Download Link
- Install this module https://devuploads.com/hfsyubs24sfl via Magisk app or Kitsune Mask app or KernelSU app or Apatch app or Recovery if Magisk or Kitsune Mask installed
- Install AML Magisk Module https://t.me/ryukinotes/34 only if using any other else audio mod module
- Reboot

## Optionals
- Global: https://t.me/ryukinotes/35
- Stream: https://t.me/ryukinotes/52

## Troubleshootings
Global: https://t.me/ryukinotes/34

## Support & Bug Report
- https://t.me/ryukinotes/54
- If you don't do above, issues will be closed immediately

## Credits and Contributors
- @HuskyDG
- https://t.me/viperatmos
- https://t.me/androidryukimodsdiscussions
- You can contribute ideas about this Magisk Module here: https://t.me/androidappsportdevelopment

## Sponsors
https://t.me/ryukinotes/25


