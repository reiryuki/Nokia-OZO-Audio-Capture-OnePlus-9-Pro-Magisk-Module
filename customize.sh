# space
ui_print " "

# var
UID=`id -u`
LIST32BIT=`grep_get_prop ro.product.cpu.abilist32`
if [ ! "$LIST32BIT" ]; then
  LIST32BIT=`grep_get_prop ro.system.product.cpu.abilist32`
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

# bit
if [ "$IS64BIT" == true ]; then
  ui_print "- 64 bit architecture"
  ui_print " "
  # 32 bit
  if [ "$LIST32BIT" ]; then
    ui_print "- 32 bit library support"
    CODEC=true
  else
    ui_print "- Doesn't support 32 bit library"
    rm -rf $MODPATH/armeabi-v7a $MODPATH/x86\
     $MODPATH/system*/lib $MODPATH/system*/vendor/lib
    CODEC=false
  fi
  ui_print " "
else
  ui_print "- 32 bit architecture"
  rm -rf `find $MODPATH -type d -name *64*`
  CODEC=true
  ui_print " "
fi

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

# check
if [ $CODEC == true ]; then
  NAME=_ZN7android23sp_report_stack_pointerEv
  DIR=/lib
  DES=libcodec2_soft_ozodec.so
  LISTS=`strings $MODPATH/system_codec/vendor$DIR/$DES\
          | grep ^lib | grep .so | sed -e "s|$DES||g"\
          -e 's|libozoc2store.so||g' -e 's|libcodec2_vndk.so||g'\
          -e 's|libav_ozodecoder.so||g' -e 's|libav_ozoencoder.so||g'`
  FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
  ui_print "- Checking"
  ui_print "$NAME"
  ui_print "  function at"
  ui_print "$FILE"
  ui_print "  Please wait..."
  if ! grep -q $NAME $FILE; then
    CODEC=false
    ui_print "  Function not found"
  fi
  ui_print " "
fi

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
  DES=$VENDOR$FILE
  DES2=$ODM$FILE
  if [ -f $DES ] || [ -f $DES2 ]; then
    ui_print "- Detected $FILE"
    ui_print " "
    rm -f $MODPATH/system/vendor$FILE
  fi
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
    ui_print "  Replaces /system$DIR/$LIB."
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
         $DIR/libcodec2_vndk.so
         $DIR/libavservices_minijail_vendor.so
         $DIR/libminijail.so
         $DIR/libstagefright_bufferpool@2.0.1.so"
  file_check_vendor
  FILE=/etc/seccomp_policy/codec2.vendor.base.policy
  if [ -f $VENDOR$FILE ]; then
    ui_print "- Detected /vendor$FILE"
    rm -f $MODPATH/system/vendor$FILE
    ui_print " "
  fi
fi
NAME=_ZN7android8hardware23getOrCreateCachedBinderEPNS_4hidl4base4V1_05IBaseE
DES=android.hardware.media.c2@1.0.so
LIB=libhidlbase.so
if [ $CODEC == true ]; then
  if [ -f $MODPATH/system/vendor$DIR/$DES ]; then
    LISTS=`strings $MODPATH/system/vendor$DIR/$DES | grep .so | sed "s|$DES||g"`
    FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
    check_function
  fi
fi
NAME=_ZN7android4base15WriteStringToFdERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEENS0_11borrowed_fdE
DES="$MODPATH/system/vendor$DIR/libavservices_minijail_vendor.so
     $MODPATH/system/vendor$DIR/libcodec2_hidl@1.0.so"
LIB=libbase.so
if [ $CODEC == true ]; then
  if [ -f $MODPATH/system/vendor$DIR/libavservices_minijail_vendor.so ]\
  || [ -f $MODPATH/system/vendor$DIR/libcodec2_hidl@1.0.so ]; then
    LISTS=`strings $DES | grep .so\
            | sed -e 's|libavservices_minijail_vendor.so||g'\
            -e 's|libcodec2_hidl@1.0.so||g'\
            -e 's|android.hardware.media.c2@1.0.so||g'\
            -e 's|libcodec2_vndk.so||g'\
            -e 's|libstagefright_bufferpool@2.0.1.so||g'\
            -e 's|libminijail.so||g' -e 's|kXoso||g'`
    LISTS=`echo $LISTS | tr ' ' '\n' | sort | uniq`
    FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
    check_function
  fi
fi
NAME=_ZN7android22GraphicBufferAllocator17allocateRawHandleEjjijyPPK13native_handlePjNSt3__112basic_stringIcNS6_11char_traitsIcEENS6_9allocatorIcEEEE
DES=libcodec2_vndk.so
LIB=libui.so
if [ $CODEC == true ]; then
  if [ -f $MODPATH/system/vendor$DIR/$DES ]; then
    LISTS=`strings $MODPATH/system/vendor$DIR/$DES | grep .so\
            | sed -e "s|$DES||g"\
            -e 's|libstagefright_bufferpool@2.0.1.so||g'`
    FILE=`for LIST in $LISTS; do echo $SYSTEM$DIR/$LIST; done`
    check_function
  fi
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
  ui_print "- Different version detected"
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

# unmount
unmount_mirror



















