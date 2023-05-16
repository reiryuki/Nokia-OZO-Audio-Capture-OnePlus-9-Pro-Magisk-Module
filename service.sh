MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

# debug
exec 2>$MODPATH/debug.log
set -x

# restart
if [ "$API" -ge 24 ]; then
  SERVER=audioserver
else
  SERVER=mediaserver
fi
PID=`pidof $SERVER`
if [ "$PID" ]; then
  killall $SERVER
fi

# stop
NAMES=vendor-ozoaudio-media-c2-hal-1-0
for NAME in $NAMES; do
  if [ "`getprop init.svc.$NAME`" == running ]\
  || [ "`getprop init.svc.$NAME`" == restarting ]; then
    stop $NAME
  fi
done

# run
SERVICES=`realpath /vendor`/bin/hw/vendor.ozoaudio.media.c2@1.0-service
for SERVICE in $SERVICES; do
  killall $SERVICE
  $SERVICE &
  PID=`pidof $SERVICE`
done

# wait
sleep 20

# aml fix
DIR=$AML/system/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi

# magisk
MAGISKPATH=`magisk --path`
if [ "$MAGISKPATH" ]; then
  MAGISKTMP=$MAGISKPATH/.magisk
  MIRROR=$MAGISKTMP/mirror
  ODM=$MIRROR/odm
  MY_PRODUCT=$MIRROR/my_product
fi

# mount
NAME="*audio*effects*.conf -o -name *audio*effects*.xml"
if [ -d $AML ] && [ ! -f $AML/disable ]\
&& find $AML/system/vendor -type f -name $NAME; then
  DIR=$AML/system/vendor
else
  DIR=$MODPATH/system/vendor
fi
FILES=`find $DIR/etc -maxdepth 1 -type f -name $NAME`
if [ ! -d $ODM ] && [ -d /odm/etc ]\
&& [ "`realpath /odm/etc`" == /odm/etc ]\
&& [ "$FILES" ]; then
  for FILE in $FILES; do
    DES="/odm`echo $FILE | sed "s|$DIR||"`"
    if [ -f $DES ]; then
      umount $DES
      mount -o bind $FILE $DES
    fi
  done
fi
if [ ! -d $MY_PRODUCT ] && [ -d /my_product/etc ]\
&& [ "$FILES" ]; then
  for FILE in $FILES; do
    DES="/my_product`echo $FILE | sed "s|$DIR||"`"
    if [ -f $DES ]; then
      umount $DES
      mount -o bind $FILE $DES
    fi
  done
fi

# wait
until [ "`getprop sys.boot_completed`" == "1" ]; do
  sleep 10
done

# check
for SERVICE in $SERVICES; do
  if ! pidof $SERVICE; then
    $SERVICE &
    PID=`pidof $SERVICE`
  fi
done











