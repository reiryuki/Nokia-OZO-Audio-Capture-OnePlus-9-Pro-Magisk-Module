# space
ui_print " "

# var
UID=`id -u`
[ ! "$UID" ] && UID=0
ABILIST=`grep_get_prop ro.product.cpu.abilist`
if [ ! "$ABILIST" ]; then
  ABILIST=`grep_get_prop ro.system.product.cpu.abilist`
fi
ABILIST32=`grep_get_prop ro.product.cpu.abilist32`
if [ ! "$ABILIST32" ]; then
  ABILIST32=`grep_get_prop ro.system.product.cpu.abilist32`
fi
if [ ! "$ABILIST32" ]; then
  [ -f /system/lib/libandroid.so ] && ABILIST32=true
fi

# log
if [ "$BOOTMODE" != true ]; then
  FILE=/data/media/"$UID"/$MODID\_recovery.log
  ui_print "- Log will be saved at $FILE"
  exec 2>$FILE
  ui_print " "
fi

# optionals
OPTIONALS=/data/media/"$UID"/optionals.prop
if [ ! -f $OPTIONALS ]; then
  touch $OPTIONALS
fi

# debug
if [ "`grep_prop debug.log $OPTIONALS`" == 1 ]; then
  ui_print "- The install log will contain detailed information"
  set -x
  ui_print " "
fi

# recovery
if [ "$BOOTMODE" != true ]; then
  MODPATH_UPDATE=`echo $MODPATH | sed 's|modules/|modules_update/|g'`
  rm -f $MODPATH/update
  rm -rf $MODPATH_UPDATE
fi

# run
. $MODPATH/function.sh

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
if [ "$KSU" == true ]; then
  ui_print " KSUVersion=$KSU_VER"
  ui_print " KSUVersionCode=$KSU_VER_CODE"
  ui_print " KSUKernelVersionCode=$KSU_KERNEL_VER_CODE"
  sed -i 's|#k||g' $MODPATH/post-fs-data.sh
else
  ui_print " MagiskVersion=$MAGISK_VER"
  ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
fi
ui_print " "

# architecture
if [ "$ABILIST" ]; then
  ui_print "- $ABILIST architecture"
  ui_print " "
fi
NAME=arm64-v8a
NAME2=armeabi-v7a
CODEC=true
if ! echo "$ABILIST" | grep -q $NAME; then
  if echo "$ABILIST" | grep -q $NAME2; then
    rm -rf `find $MODPATH/system -type d -name *64*`
  else
    if [ "$BOOTMODE" == true ]; then
      ui_print "! This ROM doesn't support $NAME nor $NAME2 architecture"
    else
      ui_print "! This Recovery doesn't support $NAME nor $NAME2 architecture"
      ui_print "  Try to install via Magisk app instead"
    fi
    abort
  fi
fi
if ! echo "$ABILIST" | grep -q $NAME2; then
  rm -rf $MODPATH/system*/lib\
   $MODPATH/system*/vendor/lib
  CODEC=false
  if [ "$BOOTMODE" != true ]; then
    ui_print "! This Recovery doesn't support $NAME2 architecture"
    ui_print "  Try to install via Magisk app instead"
    ui_print " "
  fi
fi

# sdk
ui_print "- SDK $API"
NUM=30
if [ "$API" -lt $NUM ]; then
  CODEC=false
fi
ui_print " "

# recovery
mount_partitions_in_recovery

# magisk
magisk_setup

# path
SYSTEM=`realpath $MIRROR/system`
VENDOR=`realpath $MIRROR/vendor`
PRODUCT=`realpath $MIRROR/product`
SYSTEM_EXT=`realpath $MIRROR/system_ext`
ODM=`realpath $MIRROR/odm`
MY_PRODUCT=`realpath $MIRROR/my_product`

# codec
if [ $CODEC == true ]; then
  cp -rf $MODPATH/system_codec/* $MODPATH/system
  sed -i 's|#o||g' $MODPATH/service.sh
else
  ui_print "- Using OZO Audio encoder only"
  ui_print "  Does not use OZO Audio decoder"
  ui_print " "
fi

# function
file_check_vendor() {
for FILE in $FILES; do
  DESS="$VENDOR$FILE $ODM$FILE"
  for DES in $DESS; do
    if [ -f $DES ]; then
      ui_print "- Detected"
      ui_print "$DES"
      rm -f $MODPATH/system/vendor$FILE
      ui_print " "
    fi
  done
done
}
check_function() {
if [ -f $MODPATH/system_support$DIR/$LIB ]; then
  ui_print "- Checking"
  ui_print "$NAME"
  ui_print "  function at"
  ui_print "$FILE"
  ui_print "  Please wait..."
  if ! grep -q $NAME $FILE; then
    ui_print "  Function not found."
    ui_print "  Replaces /system$DIR/$LIB systemlessly."
    mv -f $MODPATH/system_support$DIR/$LIB $MODPATH/system$DIR
    [ "$MES" ] && ui_print "$MES"
  fi
  ui_print " "
fi
}
check_function_reverse() {
if [ -f $MODPATH/system_support$DIR/$LIB ]; then
  ui_print "- Checking"
  ui_print "$NAME"
  ui_print "  function at"
  ui_print "$FILE"
  ui_print "  Please wait..."
  if grep -q $NAME $FILE; then
    ui_print "  Unsupported function."
    ui_print "  Replaces /system$DIR/$LIB systemlessly."
    mv -f $MODPATH/system_support$DIR/$LIB $MODPATH/system$DIR
    [ "$MES" ] && ui_print "$MES"
  fi
  ui_print " "
fi
}
find_file() {
for LIB in $LIBS; do
  if [ -f $MODPATH/system_support$DIR/$LIB ]; then
    FILE=`find $SYSTEM$DIR $SYSTEM_EXT$DIR -type f -name $LIB`
    if [ ! "$FILE" ]; then
      ui_print "- Using /system$DIR/$LIB."
      mv -f $MODPATH/system_support$DIR/$LIB $MODPATH/system$DIR
      ui_print " "
    fi
  fi
done
}

# check
DIR=/lib
if [ $CODEC == true ]; then
  FILES="/etc/media_codecs_ozo_audio.xml
         $DIR/android.hardware.media.c2@1.0.so
         $DIR/libcodec2_hidl@1.0.so
         $DIR/libavservices_minijail_vendor.so
         $DIR/libminijail.so
         $DIR/libstagefright_bufferpool@2.0.1.so
         $DIR/android.hardware.media.bufferpool@2.0.so"
#         $DIR/libcodec2_vndk.so
  file_check_vendor
  FILE=/etc/seccomp_policy/codec2.vendor.base.policy
  if [ -f $VENDOR$FILE ]; then
    ui_print "- Detected /vendor$FILE"
    rm -f $MODPATH/system/vendor$FILE
    ui_print " "
  fi
fi
NAME=_ZN7android23sp_report_stack_pointerEv
LIB=libutils.so
DES=libcodec2_soft_ozodec.so
if [ $CODEC == true ]; then
  LISTS=`strings $MODPATH/system_codec/vendor$DIR/$DES\
          | grep ^lib | grep .so | sed -e "s|$DES||g"\
          -e 's|libozoc2store.so||g' -e 's|libcodec2_vndk.so||g'\
          -e 's|libav_ozodecoder.so||g' -e 's|libav_ozoencoder.so||g'`
  FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
  check_function
fi
NAME=_ZN7android8hardware23getOrCreateCachedBinderEPNS_4hidl4base4V1_05IBaseE
LIB=libhidlbase.so
DES="$MODPATH/system/vendor$DIR/android.hardware.media.c2@1.0.so
     $MODPATH/system/vendor$DIR/android.hardware.media.bufferpool@2.0.so"
if [ $CODEC == true ]; then
  if [ -f $MODPATH/system/vendor$DIR/android.hardware.media.c2@1.0.so ]\
  || [ -f $MODPATH/system/vendor$DIR/android.hardware.media.bufferpool@2.0.so ]; then
    LISTS=`strings $DES | grep ^lib | grep .so`
    LISTS=`echo $LISTS | tr ' ' '\n' | sort | uniq`
    FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
    check_function
  fi
fi
NAME=_ZN7android4base15WriteStringToFdERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEENS0_11borrowed_fdE
LIB=libbase.so
DES="$MODPATH/system/vendor$DIR/libavservices_minijail_vendor.so
     $MODPATH/system/vendor$DIR/libcodec2_hidl@1.0.so"
if [ $CODEC == true ]; then
  if [ -f $MODPATH/system/vendor$DIR/libavservices_minijail_vendor.so ]\
  || [ -f $MODPATH/system/vendor$DIR/libcodec2_hidl@1.0.so ]; then
    LISTS=`strings $DES | grep ^lib | grep .so\
            | sed -e 's|libavservices_minijail_vendor.so||g'\
            -e 's|libcodec2_hidl@1.0.so||g'\
            -e 's|libcodec2_vndk.so||g'\
            -e 's|libstagefright_bufferpool@2.0.1.so||g'\
            -e 's|libminijail.so||g'`
    LISTS=`echo $LISTS | tr ' ' '\n' | sort | uniq`
    FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
    check_function
  fi
fi
LIB=libui.so
DES=libcodec2_vndk.so
NAME=_ZN7android22GraphicBufferAllocator17allocateRawHandleEjjijyPPK13native_handlePjNSt3__112basic_stringIcNS6_11char_traitsIcEENS6_9allocatorIcEEEE
if [ $CODEC == true ]; then
  if [ -f $MODPATH/system/vendor$DIR/$DES ]; then
    LISTS=`strings $MODPATH/system/vendor$DIR/$DES | grep ^lib\
            | grep .so | sed -e "s|$DES||g"\
            -e 's|libstagefright_bufferpool@2.0.1.so||g'`
    FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
    check_function
  fi
fi
NAME=_ZN7android19GraphicBufferMapper6unlockEPK13native_handlePNS_4base14unique_fd_implINS4_13DefaultCloserEEE
if [ $CODEC == true ]; then
  if [ -f $MODPATH/system/vendor$DIR/$DES ]; then
    LISTS=`strings $MODPATH/system/vendor$DIR/$DES | grep ^lib\
            | grep .so | sed -e "s|$DES||g"\
            -e 's|libstagefright_bufferpool@2.0.1.so||g'`
    FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
    check_function_reverse
  fi
fi
DES=android.hardware.graphics.common-V1-ndk_platform.so
if [ -f $MODPATH/system$DIR/$LIB ]\
&& [ ! -f $SYSTEM$DIR/$DES ]; then
  mv -f $MODPATH/system_support$DIR/$DES $MODPATH/system$DIR
fi
DES=android.hardware.common-V1-ndk_platform.so
if [ -f $MODPATH/system$DIR/$LIB ]\
&& [ ! -f $SYSTEM$DIR/$DES ]; then
  mv -f $MODPATH/system_support$DIR/$DES $MODPATH/system$DIR
fi
LIBS="libhidltransport.so libhwbinder.so"
find_file

# sepolicy
FILE=$MODPATH/sepolicy.rule
DES=$MODPATH/sepolicy.pfsd
if [ "`grep_prop sepolicy.sh $OPTIONALS`" == 1 ]\
&& [ -f $FILE ]; then
  mv -f $FILE $DES
fi

# .aml.sh
mv -f $MODPATH/aml.sh $MODPATH/.aml.sh

# cleaning
ui_print "- Cleaning..."
rm -rf $MODPATH/system_codec\
 $MODPATH/system_support\
 $MODPATH/unused
remove_sepolicy_rule
ui_print " "

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
}

# cleanup
DIR=/data/adb/modules/$MODID
FILE=$DIR/module.prop
PREVMODNAME=`grep_prop name $FILE`
if [ "`grep_prop data.cleanup $OPTIONALS`" == 1 ]; then
  sed -i 's|^data.cleanup=1|data.cleanup=0|g' $OPTIONALS
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ]\
&& [ "$PREVMODNAME" != "$MODNAME" ]; then
  ui_print "- Different module name is detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# directory
if [ "$API" -le 25 ]; then
  ui_print "- /vendor/lib*/soundfx is not supported in SDK 25 and bellow"
  ui_print "  Using /system/lib*/soundfx instead"
  cp -rf $MODPATH/system/vendor/lib* $MODPATH/system
  rm -rf $MODPATH/system/vendor/lib*
  ui_print " "
fi

# run
. $MODPATH/copy.sh
. $MODPATH/.aml.sh

# function
rename_file() {
if [ -f $FILE ]; then
  ui_print "- Renaming"
  ui_print "$FILE"
  ui_print "  to"
  ui_print "$MODFILE"
  mv -f $FILE $MODFILE
  ui_print " "
fi
}
change_name() {
if grep -q $NAME $FILE; then
  ui_print "- Changing $NAME to $NAME2 at"
  ui_print "$FILE"
  ui_print "  Please wait..."
  sed -i "s|$NAME|$NAME2|g" $FILE
  ui_print " "
fi
}

# mod
NAME=libhidlbase.so
NAME2=libhidlozos.so
FILE=$MODPATH/system/lib/$NAME
MODFILE=$MODPATH/system/vendor/lib/$NAME2
if [ -f $FILE ]; then
  rename_file
  FILE="$MODPATH/system/vendor/lib/$NAME2
$MODPATH/system/vendor/bin/hw/vendor.ozoaudio.media.c2@1.0-service
$MODPATH/system/vendor/lib/android.hardware.media.c2@1.0.so
$MODPATH/system/vendor/lib/android.hardware.media.bufferpool@2.0.so
$MODPATH/system/vendor/lib/libcodec2_hidl@1.0.so
$MODPATH/system/vendor/lib/libcodec2_vndk.so
$MODPATH/system/vendor/lib/libstagefright_bufferpool@2.0.1.so"
  change_name
fi
NAME=libui.so
NAME2=liboz.so
FILE=$MODPATH/system/lib/$NAME
MODFILE=$MODPATH/system/vendor/lib/$NAME2
if [ -f $FILE ]; then
  rename_file
  FILE="$MODPATH/system/vendor/lib/$NAME2
$MODPATH/system/vendor/lib/libcodec2_hidl@1.0.so
$MODPATH/system/vendor/lib/libcodec2_vndk.so"
  change_name
  NAME=android.hardware.graphics.common-V1-ndk_platform.so
  mv -f $MODPATH/system/lib/$NAME $MODPATH/system/vendor/lib
  NAME=android.hardware.common-V1-ndk_platform.so
  mv -f $MODPATH/system/lib/$NAME $MODPATH/system/vendor/lib
fi
NAME=libcodec2_vndk.so
NAME2=libozo_c2_vndk.so
FILE=$MODPATH/system/vendor/lib/$NAME
MODFILE=$MODPATH/system/vendor/lib/$NAME2
if [ -f $FILE ]; then
  rename_file
  FILE="$MODPATH/system/vendor/lib/$NAME2
$MODPATH/system/vendor/lib/libcodec2_hidl@1.0.so
$MODPATH/system/vendor/lib/libozoc2store.so
$MODPATH/system/vendor/lib/libcodec2_soft_ozoenc.so
$MODPATH/system/vendor/lib/libcodec2_soft_ozodec.so"
  change_name
fi

unused() {
NAME=libbase.so
NAME2=libozos.so
FILE=$MODPATH/system/lib/$NAME
MODFILE=$MODPATH/system/vendor/lib/$NAME2
if [ -f $FILE ]; then
  rename_file
  FILE="$MODPATH/system/vendor/lib/$NAME2
$MODPATH/system/vendor/lib/libcodec2_soft_ozodec.so
$MODPATH/system/vendor/lib/libcodec2_soft_ozoenc.so
$MODPATH/system/vendor/lib/libozoc2store.so
$MODPATH/system/vendor/lib/libavservices_minijail_vendor.so
$MODPATH/system/vendor/lib/libcodec2_hidl@1.0.so
$MODPATH/system/vendor/lib/libcodec2_vndk.so"
  change_name
fi
}

# unmount
unmount_mirror



















