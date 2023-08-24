# space
ui_print " "

# log
if [ "$BOOTMODE" != true ]; then
  FILE=/sdcard/$MODID\_recovery.log
  ui_print "- Log will be saved at $FILE"
  exec 2>$FILE
  ui_print " "
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
  ui_print "- 64 bit"
else
  ui_print "- 32 bit"
  rm -rf `find $MODPATH -type d -name *64*`
fi
ui_print " "

# recovery
mount_partitions_in_recovery

# magisk
magisk_setup

# path
SYSTEM=`realpath $MIRROR/system`
if [ "$BOOTMODE" == true ]; then
  if [ ! -d $MIRROR/vendor ]; then
    mount_vendor_to_mirror
  fi
  if [ ! -d $MIRROR/product ]; then
    mount_product_to_mirror
  fi
  if [ ! -d $MIRROR/system_ext ]; then
    mount_system_ext_to_mirror
  fi
  if [ ! -d $MIRROR/odm ]; then
    mount_odm_to_mirror
  fi
  if [ ! -d $MIRROR/my_product ]; then
    mount_my_product_to_mirror
  fi
fi
VENDOR=`realpath $MIRROR/vendor`
PRODUCT=`realpath $MIRROR/product`
SYSTEM_EXT=`realpath $MIRROR/system_ext`
ODM=`realpath $MIRROR/odm`
MY_PRODUCT=`realpath $MIRROR/my_product`

# optionals
OPTIONALS=/sdcard/optionals.prop
if [ ! -f $OPTIONALS ]; then
  touch $OPTIONALS
fi

# function
check_function() {
ui_print "- Checking"
ui_print "$NAME"
ui_print "  function at"
ui_print "$FILE"
ui_print "  Please wait..."
if ! grep -q $NAME $FILE; then
  ui_print "  ! Function not found."
  ui_print "    Unsupported ROM."
  if [ "$BOOTMODE" == true ] && [ ! "$MAGISKPATH" ]; then
    unmount_mirror
  fi
  abort
fi
ui_print " "
}

# check
NAME=_ZN7android23sp_report_stack_pointerEv
FILE=$VENDOR/lib/hw/*audio*.so
check_function
if [ "$IS64BIT" == true ]; then
  FILE=$VENDOR/lib64/hw/*audio*.so
  check_function
fi

# check
NAME=_ZN7android8hardware23getOrCreateCachedBinderEPNS_4hidl4base4V1_05IBaseE
DES=android.hardware.media.c2@1.0.so
LIB=libhidlbase.so
if [ "$IS64BIT" == true ]; then
  LISTS=`strings $MODPATH/system/vendor/lib64/$DES | grep .so | sed "s|$DES||g"`
  FILE=`for LIST in $LISTS; do echo $SYSTEM/lib64/$LIST; done`
  ui_print "- Checking"
  ui_print "$NAME"
  ui_print "  function at"
  ui_print "$FILE"
  ui_print "  Please wait..."
  if ! grep -q $NAME $FILE; then
    ui_print "  Using new $LIB 64"
    mv -f $MODPATH/system_support/lib64/$LIB $MODPATH/system/lib64
  fi
  ui_print " "
fi
LISTS=`strings $MODPATH/system/vendor/lib/$DES | grep .so | sed "s|$DES||g"`
FILE=`for LIST in $LISTS; do echo $SYSTEM/lib/$LIST; done`
ui_print "- Checking"
ui_print "$NAME"
ui_print "  function at"
ui_print "$FILE"
ui_print "  Please wait..."
if ! grep -q $NAME $FILE; then
  ui_print "  Using new $LIB"
  mv -f $MODPATH/system_support/lib/$LIB $MODPATH/system/lib
fi
ui_print " "

# check
NAME=_ZN7android4base15WriteStringToFdERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEENS0_11borrowed_fdE
LIB=libbase.so
if [ "$IS64BIT" == true ]; then
  DES=libcodec2_hidl@1.0.so
  LISTS=`strings $MODPATH/system/vendor/lib64/$DES | grep .so | sed -e "s|$DES||g" -e 's|android.hardware.media.c2@1.0.so||g' -e 's|libcodec2_vndk.so||g' -e 's|libstagefright_bufferpool@2.0.1.so||g'`
  FILE=`for LIST in $LISTS; do echo $SYSTEM/lib64/$LIST; done`
  ui_print "- Checking"
  ui_print "$NAME"
  ui_print "  function at"
  ui_print "$FILE"
  ui_print "  Please wait..."
  if ! grep -q $NAME $FILE; then
    ui_print "  Using new $LIB 64"
    mv -f $MODPATH/system_support/lib64/$LIB $MODPATH/system/lib64
  fi
  ui_print " "
fi
DES="$MODPATH/system/vendor/lib/libavservices_minijail_vendor.so
     $MODPATH/system/vendor/lib/libcodec2_hidl@1.0.so"
LISTS=`strings $DES | grep .so | sed -e 's|libavservices_minijail_vendor.so||g' -e 's|libcodec2_hidl@1.0.so||g' -e 's|android.hardware.media.c2@1.0.so||g' -e 's|libcodec2_vndk.so||g' -e 's|libstagefright_bufferpool@2.0.1.so||g' -e 's|libminijail.so||g' -e 's|kXoso||g'`
FILE=`for LIST in $LISTS; do echo $SYSTEM/lib/$LIST; done`
ui_print "- Checking"
ui_print "$NAME"
ui_print "  function at"
ui_print "$FILE"
ui_print "  Please wait..."
if ! grep -q $NAME $FILE; then
  ui_print "  Using new $LIB"
  mv -f $MODPATH/system_support/lib/$LIB $MODPATH/system/lib
fi
ui_print " "

# check
NAME=_ZN7android22GraphicBufferAllocator17allocateRawHandleEjjijyPPK13native_handlePjNSt3__112basic_stringIcNS6_11char_traitsIcEENS6_9allocatorIcEEEE
DES=libcodec2_vndk.so
LIB=libui.so
LISTS=`strings $MODPATH/system/vendor/lib/$DES | grep .so | sed -e "s|$DES||g" -e 's|libstagefright_bufferpool@2.0.1.so||g'`
FILE=`for LIST in $LISTS; do echo $SYSTEM/lib/$LIST; done`
ui_print "- Checking"
ui_print "$NAME"
ui_print "  function at"
ui_print "$FILE"
ui_print "  Please wait..."
if ! grep -q $NAME $FILE; then
  ui_print "  Using new $LIB"
  mv -f $MODPATH/system_support/lib/$LIB $MODPATH/system/lib
fi
ui_print " "

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
rm -rf $MODPATH/unused
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
if [ "`grep_prop data.cleanup $OPTIONALS`" == 1 ]; then
  sed -i 's/^data.cleanup=1/data.cleanup=0/' $OPTIONALS
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ] && ! grep -q "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
find_file() {
for NAME in $NAMES; do
  if [ "$IS64BIT" == true ]; then
    FILE=`find $SYSTEM/lib64 $VENDOR/lib64 $SYSTEM_EXT/lib64 -type f -name $NAME`
    if [ ! "$FILE" ]; then
      if [ "`grep_prop install.hwlib $OPTIONALS`" == 1 ]; then
        ui_print "- Installing $NAME 64 directly to"
        ui_print "$SYSTEM/lib64..."
        cp $MODPATH/system_support/lib64/$NAME $SYSTEM/lib64
        DES=$SYSTEM/lib64/$NAME
        if [ -f $MODPATH/system_support/lib64/$NAME ]\
        && [ ! -f $DES ]; then
          ui_print "  ! Installation failed."
          ui_print "    Using $NAME 64 systemlessly."
          cp -f $MODPATH/system_support/lib64/$NAME $MODPATH/system/lib64
        fi
      else
        ui_print "! $NAME 64 not found."
        ui_print "  Using $NAME 64 systemlessly."
        cp -f $MODPATH/system_support/lib64/$NAME $MODPATH/system/lib64
        ui_print "  If this module still doesn't work, type:"
        ui_print "  install.hwlib=1"
        ui_print "  inside $OPTIONALS"
        ui_print "  and reinstall this module"
        ui_print "  to install $NAME 64 directly to this ROM."
        ui_print "  DwYOR!"
      fi
      ui_print " "
    fi
  fi
  FILE=`find $SYSTEM/lib $VENDOR/lib $SYSTEM_EXT/lib -type f -name $NAME`
  if [ ! "$FILE" ]; then
    if [ "`grep_prop install.hwlib $OPTIONALS`" == 1 ]; then
      ui_print "- Installing $NAME directly to"
      ui_print "$SYSTEM/lib..."
      cp $MODPATH/system_support/lib/$NAME $SYSTEM/lib
      DES=$SYSTEM/lib/$NAME
      if [ -f $MODPATH/system_support/lib/$NAME ]\
      && [ ! -f $DES ]; then
        ui_print "  ! Installation failed."
        ui_print "    Using $NAME systemlessly."
        cp -f $MODPATH/system_support/lib/$NAME $MODPATH/system/lib
      fi
    else
      ui_print "! $NAME not found."
      ui_print "  Using $NAME systemlessly."
      cp -f $MODPATH/system_support/lib/$NAME $MODPATH/system/lib
      ui_print "  If this module still doesn't work, type:"
      ui_print "  install.hwlib=1"
      ui_print "  inside $OPTIONALS"
      ui_print "  and reinstall this module"
      ui_print "  to install $NAME directly to this ROM."
      ui_print "  DwYOR!"
    fi
    ui_print " "
  fi
done
sed -i 's|^install.hwlib=1|install.hwlib=0|g' $OPTIONALS
}

# check
remount_rw
chcon -R u:object_r:system_lib_file:s0 $MODPATH/system_support/lib*
NAMES="libhidltransport.so libhwbinder.so"
find_file
remount_ro
rm -rf $MODPATH/system_support

# run
. $MODPATH/copy.sh
. $MODPATH/.aml.sh

# unmount
if [ "$BOOTMODE" == true ] && [ ! "$MAGISKPATH" ]; then
  unmount_mirror
fi


















