# space
ui_print " "

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
else
  ui_print " MagiskVersion=$MAGISK_VER"
  ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
fi
ui_print " "

# huskydg function
get_device() {
PAR="$1"
DEV="`cat /proc/self/mountinfo | awk '{ if ( $5 == "'$PAR'" ) print $3 }' | head -1 | sed 's/:/ /g'`"
}
mount_mirror() {
SRC="$1"
DES="$2"
RAN="`head -c6 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9'`"
while [ -e /dev/$RAN ]; do
  RAN="`head -c6 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9'`"
done
mknod /dev/$RAN b `get_device "$SRC"; echo $DEV`
if mount -t ext4 -o ro /dev/$RAN "$DES"\
|| mount -t erofs -o ro /dev/$RAN "$DES"\
|| mount -t f2fs -o ro /dev/$RAN "$DES"\
|| mount -t ubifs -o ro /dev/$RAN "$DES"; then
  blockdev --setrw /dev/$RAN
  rm -f /dev/$RAN
  return 0
fi
rm -f /dev/$RAN
return 1
}
unmount_mirror() {
DIRS="$MIRROR/system_root $MIRROR/system $MIRROR/vendor
      $MIRROR/product $MIRROR/system_ext $MIRROR/odm
      $MIRROR/my_product $MIRROR"
for DIR in $DIRS; do
  umount $DIR
done
}
mount_partitions_to_mirror() {
unmount_mirror
# mount system
if [ "$SYSTEM_ROOT" == true ]; then
  DIR=/system_root
  ui_print "- Mount $MIRROR$DIR..."
  mkdir -p $MIRROR$DIR
  if mount_mirror / $MIRROR$DIR; then
    ui_print "  $MIRROR$DIR mount success"
    rm -rf $MIRROR/system
    ln -sf $MIRROR$DIR/system $MIRROR
    ls $MIRROR$DIR
  else
    ui_print "  ! $MIRROR$DIR mount failed"
    rm -rf $MIRROR$DIR
  fi
else
  DIR=/system
  ui_print "- Mount $MIRROR$DIR..."
  mkdir -p $MIRROR$DIR
  if mount_mirror $DIR $MIRROR$DIR; then
    ui_print "  $MIRROR$DIR mount success"
    ls $MIRROR$DIR
  else
    ui_print "  ! $MIRROR$DIR mount failed"
    rm -rf $MIRROR$DIR
  fi
fi
ui_print " "
# mount vendor
DIR=/vendor
ui_print "- Mount $MIRROR$DIR..."
mkdir -p $MIRROR$DIR
if mount_mirror $DIR $MIRROR$DIR; then
  ui_print "  $MIRROR$DIR mount success"
  ls $MIRROR$DIR
else
  ui_print "  ! $MIRROR$DIR mount failed"
  rm -rf $MIRROR$DIR
  ln -sf $MIRROR/system$DIR $MIRROR
fi
ui_print " "
# mount product
DIR=/product
ui_print "- Mount $MIRROR$DIR..."
mkdir -p $MIRROR$DIR
if mount_mirror $DIR $MIRROR$DIR; then
  ui_print "  $MIRROR$DIR mount success"
  ls $MIRROR$DIR
else
  ui_print "  ! $MIRROR$DIR mount failed"
  rm -rf $MIRROR$DIR
  ln -sf $MIRROR/system$DIR $MIRROR
fi
ui_print " "
# mount system_ext
DIR=/system_ext
ui_print "- Mount $MIRROR$DIR..."
mkdir -p $MIRROR$DIR
if mount_mirror $DIR $MIRROR$DIR; then
  ui_print "  $MIRROR$DIR mount success"
  ls $MIRROR$DIR
else
  ui_print "  ! $MIRROR$DIR mount failed"
  rm -rf $MIRROR$DIR
  if [ -d $MIRROR/system$DIR ]; then
    ln -sf $MIRROR/system$DIR $MIRROR
  fi
fi
ui_print " "
# mount odm
DIR=/odm
ui_print "- Mount $MIRROR$DIR..."
mkdir -p $MIRROR$DIR
if mount_mirror $DIR $MIRROR$DIR; then
  ui_print "  $MIRROR$DIR mount success"
  ls $MIRROR$DIR
else
  ui_print "  ! $MIRROR$DIR mount failed"
  rm -rf $MIRROR$DIR
  if [ -d $MIRROR/system_root$DIR ]; then
    ln -sf $MIRROR/system_root$DIR $MIRROR
  fi
fi
ui_print " "
# mount my_product
DIR=/my_product
ui_print "- Mount $MIRROR$DIR..."
mkdir -p $MIRROR$DIR
if mount_mirror $DIR $MIRROR$DIR; then
  ui_print "  $MIRROR$DIR mount success"
  ls $MIRROR$DIR
else
  ui_print "  ! $MIRROR$DIR mount failed"
  rm -rf $MIRROR$DIR
  if [ -d $MIRROR/system_root$DIR ]; then
    ln -sf $MIRROR/system_root$DIR $MIRROR
  fi
fi
ui_print " "
}

# magisk
MAGISKPATH=`magisk --path`
if [ "$BOOTMODE" == true ]; then
  if [ "$MAGISKPATH" ]; then
    MAGISKTMP=$MAGISKPATH/.magisk
    MIRROR=$MAGISKTMP/mirror
  else
    MAGISKTMP=/mnt
    MIRROR=$MAGISKTMP/mirror
    mount_partitions_to_mirror
  fi
fi

# path
SYSTEM=`realpath $MIRROR/system`
PRODUCT=`realpath $MIRROR/product`
VENDOR=`realpath $MIRROR/vendor`
SYSTEM_EXT=`realpath $MIRROR/system_ext`
if [ -d $MIRROR/odm ]; then
  ODM=`realpath $MIRROR/odm`
else
  ODM=`realpath /odm`
fi
if [ -d $MIRROR/my_product ]; then
  MY_PRODUCT=`realpath $MIRROR/my_product`
else
  MY_PRODUCT=`realpath /my_product`
fi

# optionals
OPTIONALS=/sdcard/optionals.prop
if [ ! -f $OPTIONALS ]; then
  touch $OPTIONALS
fi

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
  if [ -e /dev/block/bootdevice/by-name/vendor ]; then
    mount -o rw -t auto /dev/block/bootdevice/by-name/vendor /vendor
  else
    mount -o rw -t auto /dev/block/bootdevice/by-name/cust /vendor
  fi
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi

# function
check_function() {
ui_print "- Checking"
ui_print "$NAME"
ui_print "  function at"
ui_print "$FILE"
ui_print "  Please wait..."
if ! grep -Eq $NAME $FILE; then
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
NAME=_ZN7android8hardware23getOrCreateCachedBinderEPNS_4hidl4base4V1_05IBaseE
TARGET=android.hardware.media.c2@1.0.so
LISTS=`strings $MODPATH/system/vendor/lib/$TARGET | grep .so | sed "s/$TARGET//"`
FILE=`for LIST in $LISTS; do echo $SYSTEM/lib/$LIST; done`
check_function
if [ "$IS64BIT" == true ]; then
  LISTS=`strings $MODPATH/system/vendor/lib64/$TARGET | grep .so | sed "s/$TARGET//"`
  FILE=`for LIST in $LISTS; do echo $SYSTEM/lib64/$LIST; done`
  check_function
fi
NAME=_ZN7android4base15WriteStringToFdERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEENS0_11borrowed_fdE
TARGET="$MODPATH/system/vendor/lib/libavservices_minijail_vendor.so
        $MODPATH/system/vendor/lib/libcodec2_hidl@1.0.so"
LISTS=`strings $TARGET | grep .so | sed 's/libavservices_minijail_vendor.so//' | sed 's/libcodec2_hidl@1.0.so//'`
FILE=`for LIST in $LISTS; do echo $SYSTEM/lib/$LIST; done`
check_function
if [ "$IS64BIT" == true ]; then
  TARGET=libcodec2_hidl@1.0.so
  LISTS=`strings $MODPATH/system/vendor/lib64/$TARGET | grep .so | sed "s/$TARGET//"`
  FILE=`for LIST in $LISTS; do echo $SYSTEM/lib64/$LIST; done`
  check_function
fi
NAME=_ZN7android22GraphicBufferAllocator17allocateRawHandleEjjijyPPK13native_handlePjNSt3__112basic_stringIcNS6_11char_traitsIcEENS6_9allocatorIcEEEE
TARGET=libcodec2_vndk.so
LISTS=`strings $MODPATH/system/vendor/lib/$TARGET | grep .so | sed "s/$TARGET//"`
FILE=`for LIST in $LISTS; do echo $SYSTEM/lib/$LIST; done`
check_function

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
    sh $DIR/uninstall.sh
  fi
  rm -rf $DIR
  DIR=/data/adb/modules/$NAMES
  rm -f $DIR/update
  touch $DIR/remove
  FILE=/data/adb/modules/$NAMES/uninstall.sh
  if [ -f $FILE ]; then
    sh $FILE
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
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
set_read_write() {
for NAME in $NAMES; do
  if [ -e $DIR$NAME ]; then
    blockdev --setrw $DIR$NAME
  fi
done
}
remount_rw() {
DIR=/dev/block/bootdevice/by-name
NAMES="/vendor$SLOT /cust$SLOT /system$SLOT /system_ext$SLOT"
set_read_write
DIR=/dev/block/mapper
set_read_write
DIR=$MAGISKTMP/block
NAMES="/vendor /system_root /system /system_ext"
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

# check
remount_rw
chcon -R u:object_r:system_lib_file:s0 $MODPATH/system_support/lib*
chcon -R u:object_r:same_process_hal_file:s0 $MODPATH/system_support/vendor/lib*
NAME="libhidltransport.so libhwbinder.so"
find_file
remount_ro
rm -rf $MODPATH/system_support

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

# unmount
if [ "$BOOTMODE" == true ] && [ ! "$MAGISKPATH" ]; then
  unmount_mirror
fi


















