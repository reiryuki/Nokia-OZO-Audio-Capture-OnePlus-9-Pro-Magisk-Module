mount -o rw,remount /data
MODPATH=${0%/*}

# log
exec 2>$MODPATH/debug-pfsd.log
set -x

# var
API=`getprop ro.build.version.sdk`
ABI=`getprop ro.product.cpu.abi`

# function
permissive() {
if [ "$SELINUX" == Enforcing ]; then
  if ! setenforce 0; then
    echo 0 > /sys/fs/selinux/enforce
  fi
fi
}
magisk_permissive() {
if [ "$SELINUX" == Enforcing ]; then
  if [ -x "`command -v magiskpolicy`" ]; then
	magiskpolicy --live "permissive *"
  else
	$MODPATH/$ABI/libmagiskpolicy.so --live "permissive *"
  fi
fi
}
sepolicy_sh() {
if [ -f $FILE ]; then
  if [ -x "`command -v magiskpolicy`" ]; then
    magiskpolicy --live --apply $FILE 2>/dev/null
  else
    $MODPATH/$ABI/libmagiskpolicy.so --live --apply $FILE 2>/dev/null
  fi
fi
}

# selinux
SELINUX=`getenforce`
chmod 0755 $MODPATH/*/libmagiskpolicy.so
#1permissive
#2magisk_permissive
#kFILE=$MODPATH/sepolicy.rule
#ksepolicy_sh
FILE=$MODPATH/sepolicy.pfsd
sepolicy_sh

# run
. $MODPATH/copy.sh
. $MODPATH/.aml.sh

# permission
if [ -L $MODPATH/system/vendor ]\
&& [ -d $MODPATH/vendor ]; then
  chmod 0751 $MODPATH/vendor/bin
  chmod 0751 $MODPATH/vendor/bin/hw
  FILES=`find $MODPATH/vendor/bin -type f`
  for FILE in $FILES; do
    chmod 0755 $FILE
  done
else
  chmod 0751 $MODPATH/system/vendor/bin
  chmod 0751 $MODPATH/system/vendor/bin/hw
  FILES=`find $MODPATH/system/vendor/bin -type f`
  for FILE in $FILES; do
    chmod 0755 $FILE
  done
fi
if [ "$API" -ge 26 ]; then
  DIRS=`find $MODPATH/vendor\
             $MODPATH/system/vendor -type d`
  for DIR in $DIRS; do
    chown 0.2000 $DIR
  done
  chcon -R u:object_r:system_lib_file:s0 $MODPATH/system/lib*
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/odm/etc
  if [ -L $MODPATH/system/vendor ]\
  && [ -d $MODPATH/vendor ]; then
    FILES=`find $MODPATH/vendor/bin -type f`
    for FILE in $FILES; do
      chown 0.2000 $FILE
    done
    chcon -R u:object_r:vendor_file:s0 $MODPATH/vendor
    chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/vendor/etc
    chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/vendor/odm/etc
    chcon u:object_r:mediacodec_exec:s0 $MODPATH/vendor/bin/hw/vendor.ozoaudio.media.c2@*-service
  else
    FILES=`find $MODPATH/system/vendor/bin -type f`
    for FILE in $FILES; do
      chown 0.2000 $FILE
    done
    chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
    chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc
    chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/odm/etc
    chcon u:object_r:mediacodec_exec:s0 $MODPATH/system/vendor/bin/hw/vendor.ozoaudio.media.c2@*-service
  fi
fi

# function
mount_helper() {
if [ -d /odm ]\
&& [ "`realpath /odm/etc`" == /odm/etc ]; then
  DIR=$MODPATH/system/odm
  FILES=`find $DIR -type f -name $AUD`
  for FILE in $FILES; do
    DES=/odm`echo $FILE | sed "s|$DIR||g"`
    umount $DES
    mount -o bind $FILE $DES
  done
fi
if [ -d /my_product ]; then
  DIR=$MODPATH/system/my_product
  FILES=`find $DIR -type f -name $AUD`
  for FILE in $FILES; do
    DES=/my_product`echo $FILE | sed "s|$DIR||g"`
    umount $DES
    mount -o bind $FILE $DES
  done
fi
}

# mount
if ! grep -E 'delta|Delta|kitsune' /data/adb/magisk/util_functions.sh; then
  mount_helper
fi

# function
mount_bind_file() {
if [ -f $MODFILE ]; then
  for FILE in $FILES; do
    umount $FILE
    mount -o bind $MODFILE $FILE
  done
fi
}
mount_bind_to_apex() {
for NAME in $NAMES; do
  MODFILE=$MODPATH/system/lib64/$NAME
  FILES=`find /apex /system/apex -type f -path *lib64/$NAME`
  mount_bind_file
  MODFILE=$MODPATH/system/lib/$NAME
  FILES=`find /apex /system/apex -type f -path *lib/$NAME`
  mount_bind_file
done
}

# mount
NAMES="libhidlbase.so libbase.so libui.so"
mount_bind_to_apex








