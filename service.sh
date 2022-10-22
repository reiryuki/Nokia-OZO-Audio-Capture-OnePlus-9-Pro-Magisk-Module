MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

# debug
exec 2>$MODPATH/debug.log
set -x

# function
stop_service() {
for NAMES in $NAME; do
  if getprop | grep "init.svc.$NAMES\]: \[running"; then
    stop $NAMES
  fi
done
}
run_service() {
for FILES in $FILE; do
  killall $FILES
  $FILES &
  PID=`pidof $FILES`
done
}

# stop
NAME=vendor-ozoaudio-media-c2-hal-1-0
stop_service

# run
FILE=`realpath /vendor`/bin/hw/vendor.ozoaudio.media.c2@1.0-service
run_service

# wait
sleep 20

# aml fix
DIR=$AML/system/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi

# mount
NAME="*audio*effects*.conf -o -name *audio*effects*.xml"
if [ -d $AML ] && [ ! -f $AML/disable ]\
&& find $AML/system/vendor -type f -name $NAME; then
  DIR=$AML/system/vendor
else
  DIR=$MODPATH/system/vendor
fi
FILE=`find $DIR/etc -maxdepth 1 -type f -name $NAME`
if [ "`realpath /odm/etc`" == /odm/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="/odm$(echo $i | sed "s|$DIR||")"
    if [ -f $j ]; then
      umount $j
      mount -o bind $i $j
    fi
  done
fi
if [ -d /my_product/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="/my_product$(echo $i | sed "s|$DIR||")"
    if [ -f $j ]; then
      umount $j
      mount -o bind $i $j
    fi
  done
fi

# restart
if [ "$API" -ge 24 ]; then
  PID=`pidof audioserver`
  if [ "$PID" ]; then
    killall audioserver
  fi
else
  PID=`pidof mediaserver`
  if [ "$PID" ]; then
    killall mediaserver
  fi
fi


