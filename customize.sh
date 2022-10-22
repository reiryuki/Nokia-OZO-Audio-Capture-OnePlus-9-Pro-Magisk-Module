# space
if [ "$BOOTMODE" == true ]; then
  ui_print " "
fi

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`realpath /dev/*/.magisk`
fi

# path
if [ "$BOOTMODE" == true ]; then
  MIRROR=$MAGISKTMP/mirror
else
  MIRROR=
fi
SYSTEM=`realpath $MIRROR/system`
PRODUCT=`realpath $MIRROR/product`
VENDOR=`realpath $MIRROR/vendor`
SYSTEM_EXT=`realpath $MIRROR/system/system_ext`
ODM=`realpath /odm`
MY_PRODUCT=`realpath /my_product`

# optionals
OPTIONALS=/sdcard/optionals.prop

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
ui_print " MagiskVersion=$MAGISK_VER"
ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# bit
if [ "$IS64BIT" == true ]; then
  ui_print "- 64 bit"
else
  ui_print "- 32 bit"
  rm -rf `find $MODPATH/system -type d -name *64`
fi
ui_print " "

# mount
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/cust /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/vendor /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi

# sepolicy.rule
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && [ "`grep_prop sepolicy.sh $OPTIONALS`" != 1 ]; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# .aml.sh
mv -f $MODPATH/aml.sh $MODPATH/.aml.sh

# cleaning
ui_print "- Cleaning..."
rm -rf $MODPATH/unused
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

# function
conflict() {
for NAMES in $NAME; do
  DIR=/data/adb/modules_update/$NAMES
  if [ -f $DIR/uninstall.sh ]; then
    . $DIR/uninstall.sh
  fi
  rm -rf $DIR
  DIR=/data/adb/modules/$NAMES
  rm -f $DIR/update
  touch $DIR/remove
  FILE=/data/adb/modules/$NAMES/uninstall.sh
  if [ -f $FILE ]; then
    . $FILE
    rm -f $FILE
  fi
  rm -rf /metadata/magisk/$NAMES
  rm -rf /mnt/vendor/persist/magisk/$NAMES
  rm -rf /persist/magisk/$NAMES
  rm -rf /data/unencrypted/magisk/$NAMES
  rm -rf /cache/magisk/$NAMES
done
}

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  . $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  . $DIR/uninstall.sh
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
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
set_read_write() {
for NAMES in $NAME; do
  blockdev --setrw $DIR$NAMES
done
}
remount_rw() {
DIR=/dev/block/bootdevice/by-name
NAME="/vendor$SLOT /cust$SLOT /system$SLOT /system_ext$SLOT"
set_read_write
DIR=/dev/block/mapper
set_read_write
DIR=$MAGISKTMP/block
NAME="/vendor /system_root /system /system_ext"
set_read_write
mount -o rw,remount $MAGISKTMP/mirror/system
mount -o rw,remount $MAGISKTMP/mirror/system_root
mount -o rw,remount $MAGISKTMP/mirror/system_ext
mount -o rw,remount $MAGISKTMP/mirror/vendor
mount -o rw,remount /system
mount -o rw,remount /
mount -o rw,remount /system_root
mount -o rw,remount /system_ext
mount -o rw,remount /vendor
}
remount_ro() {
if [ "$BOOTMODE" == true ]; then
  mount -o ro,remount $MAGISKTMP/mirror/system
  mount -o ro,remount $MAGISKTMP/mirror/system_root
  mount -o ro,remount $MAGISKTMP/mirror/system_ext
  mount -o ro,remount $MAGISKTMP/mirror/vendor
  mount -o ro,remount /system
  mount -o ro,remount /
  mount -o ro,remount /system_root
  mount -o ro,remount /system_ext
  mount -o ro,remount /vendor
fi
}
find_file() {
for NAMES in $NAME; do
  FILE=`find $SYSTEM $VENDOR $SYSTEM_EXT -type f -name $NAMES`
  if [ ! "$FILE" ]; then
    if [ "`grep_prop install.hwlib $OPTIONALS`" == 1 ]; then
      sed -i 's/^install.hwlib=1/install.hwlib=0/' $OPTIONALS
      ui_print "- Installing $NAMES directly to /system and /vendor..."
      cp $MODPATH/system_support/lib/$NAMES $SYSTEM/lib
      cp $MODPATH/system_support/lib64/$NAMES $SYSTEM/lib64
      cp $MODPATH/system_support/vendor/lib/$NAMES $VENDOR/lib
      cp $MODPATH/system_support/vendor/lib64/$NAMES $VENDOR/lib64
      DES=$SYSTEM/lib/$NAMES
      DES2=$SYSTEM/lib64/$NAMES
      DES3=$VENDOR/lib/$NAMES
      DES4=$VENDOR/lib64/$NAMES
      if [ -f $MODPATH/system_support/lib/$NAMES ]\
      && [ ! -f $DES ]; then
        ui_print "  ! $DES"
        ui_print "    installation failed."
        ui_print "  Using $NAMES systemlessly."
        cp -f $MODPATH/system_support/lib/$NAMES $MODPATH/system/lib
      fi
      if [ -f $MODPATH/system_support/lib64/$NAMES ]\
      && [ ! -f $DES2 ]; then
        ui_print "  ! $DES2"
        ui_print "    installation failed."
        ui_print "  Using $NAMES systemlessly."
        cp -f $MODPATH/system_support/lib64/$NAMES $MODPATH/system/lib64
      fi
      if [ -f $MODPATH/system_support/vendor/lib/$NAMES ]\
      && [ ! -f $DES3 ]; then
        ui_print "  ! $DES3"
        ui_print "    installation failed."
        ui_print "  Using $NAMES systemlessly."
        cp -f $MODPATH/system_support/vendor/lib/$NAMES $MODPATH/system/vendor/lib
      fi
      if [ -f $MODPATH/system_support/vendor/lib64/$NAMES ]\
      && [ ! -f $DES4 ]; then
        ui_print "  ! $DES4"
        ui_print "    installation failed."
        ui_print "  Using $NAMES systemlessly."
        cp -f $MODPATH/system_support/vendor/lib64/$NAMES $MODPATH/system/vendor/lib64
      fi
    else
      ui_print "! $NAMES not found."
      ui_print "  Using $NAMES systemlessly."
      cp -f $MODPATH/system_support/lib/$NAMES $MODPATH/system/lib
      cp -f $MODPATH/system_support/lib64/$NAMES $MODPATH/system/lib64
      cp -f $MODPATH/system_support/vendor/lib/$NAMES $MODPATH/system/vendor/lib
      cp -f $MODPATH/system_support/vendor/lib64/$NAMES $MODPATH/system/vendor/lib64
      ui_print "  If this module still doesn't work, type:"
      ui_print "  install.hwlib=1"
      ui_print "  inside $OPTIONALS"
      ui_print "  and reinstall this module"
      ui_print "  to install $NAMES directly to this ROM."
      ui_print "  DwYOR!"
    fi
    ui_print " "
  fi
done
}
check_function() {
ui_print "- Checking"
ui_print "$NAME"
ui_print "  function at"
ui_print "$SYSTEM$FILE"
ui_print "  Please wait..."
if ! grep -Eq $NAME $SYSTEM$FILE; then
  ui_print "  ! Function not found."
  if [ "`grep_prop change.system $OPTIONALS`" == 1 ]\
  && [ "$API" -ge 30 ]; then
    sed -i 's/^change.system=1/change.system=0/' $OPTIONALS
    ui_print "  Installing new $FILE..."
    ui_print "  If your device reboot automatically, then install this"
    ui_print "  module again after reboot."
    sleep 5
    ui_print "  Your original files are stored to"
    ui_print "  /data/adb/system_original/"
    mkdir -p /data/adb/system_original/vendor/lib
    mkdir -p /data/adb/system_original/vendor/lib64
    cp $VENDOR$FILE /data/adb/system_original/vendor$FILE
    cp -f $MODPATH/system_support/vendor$FILE $VENDOR$FILE
    if ! grep -Eq $NAME $VENDOR$FILE; then
      ui_print "  ! $VENDOR$FILE"
      ui_print "    installation failed."
      ui_print "  Using new $FILE systemlessly."
      cp -f $MODPATH/system_support/vendor$FILE $MODPATH/system/vendor$FILE
    fi
    mkdir -p /data/adb/system_original/lib
    mkdir -p /data/adb/system_original/lib64
    cp $SYSTEM$FILE /data/adb/system_original/$FILE
    cp -f $MODPATH/system_support$FILE $SYSTEM$FILE
    if ! grep -Eq $NAME $SYSTEM$FILE; then
      ui_print "  ! $SYSTEM$FILE"
      ui_print "    installation failed."
      ui_print "  Using new $FILE systemlessly."
      cp -f $MODPATH/system_support$FILE $MODPATH/system$FILE
    fi
  else
    if [ "$API" -ge 30 ]; then
      ui_print "  Using new $FILE systemlessly."
      cp -f $MODPATH/system_support/vendor$FILE $MODPATH/system/vendor$FILE
      cp -f $MODPATH/system_support$FILE $MODPATH/system$FILE
      ui_print "  If this module still doesn't work, type:"
      ui_print "  change.system=1"
      ui_print "  inside $OPTIONALS"
      ui_print "  and reinstall this module"
      ui_print "  to install new $FILE directly to this ROM."
      ui_print "  DwYOR!"
    else
      remount_ro
      abort
    fi
  fi
fi
ui_print " "
}

# check
chcon -R u:object_r:system_lib_file:s0 $MODPATH/system_support/lib*
chcon -R u:object_r:same_process_hal_file:s0 $MODPATH/system_support/vendor/lib*
remount_rw
NAME="libhidltransport.so libhwbinder.so"
find_file
NAME=_ZN7android23sp_report_stack_pointerEv
if [ "$IS64BIT" == true ]; then
  FILE=/lib64/libhidlbase.so
  check_function
fi
FILE=/lib/libhidlbase.so
check_function
NAME=_ZN7android8hardware23getOrCreateCachedBinderEPNS_4hidl4base4V1_05IBaseE
if [ "$IS64BIT" == true ]; then
  FILE=/lib64/libhidlbase.so
  check_function
fi
FILE=/lib/libhidlbase.so
check_function
NAME=_ZN7android4base15WriteStringToFdERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEENS0_11borrowed_fdE
if [ "$IS64BIT" == true ]; then
  FILE=/lib64/libbase.so
  check_function
fi
FILE=/lib/libbase.so
check_function
NAME=_ZN7android22GraphicBufferAllocator17allocateRawHandleEjjijyPPK13native_handlePjNSt3__112basic_stringIcNS6_11char_traitsIcEENS6_9allocatorIcEEEE
FILE=/lib/libui.so
check_function
remount_ro
rm -rf $MODPATH/system_support

# directory
if [ ! -d $VENDOR/lib/soundfx ]; then
  ui_print "- /vendor/lib/soundfx is not suported."
  ui_print "  Moving to /system/lib/soundfx..."
  mv -f $MODPATH/system/vendor/lib* $MODPATH/system
  ui_print " "
fi

# permission
ui_print "- Setting permission..."
FILE=`find $MODPATH/system/vendor/bin -type f`
for FILES in $FILE; do
  chmod 0755 $FILES
  chown 0.2000 $FILES
done
chmod 0751 $MODPATH/system/vendor/bin
chmod 0751 $MODPATH/system/vendor/bin/hw
DIR=`find $MODPATH/system/vendor -type d`
for DIRS in $DIR; do
  chown 0.2000 $DIRS
done
ui_print " "











