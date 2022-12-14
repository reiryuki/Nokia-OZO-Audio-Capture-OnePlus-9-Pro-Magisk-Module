MODPATH=${0%/*}

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`realpath /dev/*/.magisk`
fi

# path
MIRROR=$MAGISKTMP/mirror
VENDOR=`realpath $MIRROR/vendor`

# destination
if [ -d $VENDOR/lib/soundfx ]; then
  LIBPATH="\/vendor\/lib\/soundfx"
else
  LIBPATH="\/system\/lib\/soundfx"
fi
MODAEC=`find $MODPATH/system -type f -name *audio*effects*.conf`
MODAEX=`find $MODPATH/system -type f -name *audio*effects*.xml`

# function
remove_conf() {
for RMVS in $RMV; do
  sed -i "s/$RMVS/removed/g" $MODAEC
done
sed -i 's/path \/vendor\/lib\/soundfx\/removed//g' $MODAEC
sed -i 's/path \/system\/lib\/soundfx\/removed//g' $MODAEC
sed -i 's/path \/vendor\/lib\/removed//g' $MODAEC
sed -i 's/path \/system\/lib\/removed//g' $MODAEC
sed -i 's/library removed//g' $MODAEC
sed -i 's/uuid removed//g' $MODAEC
sed -i "/^        removed {/ {;N s/        removed {\n        }//}" $MODAEC
}
remove_xml() {
for RMVS in $RMV; do
  sed -i "s/\"$RMVS\"/\"removed\"/g" $MODAEX
done
sed -i 's/<library name="removed" path="removed"\/>//g' $MODAEX
sed -i 's/<library name="proxy" path="removed"\/>//g' $MODAEX
sed -i 's/<effect name="removed" library="removed" uuid="removed"\/>//g' $MODAEX
sed -i 's/<effect name="removed" uuid="removed" library="removed"\/>//g' $MODAEX
sed -i 's/<libsw library="removed" uuid="removed"\/>//g' $MODAEX
sed -i 's/<libhw library="removed" uuid="removed"\/>//g' $MODAEX
sed -i 's/<apply effect="removed"\/>//g' $MODAEX
sed -i 's/<library name="removed" path="removed" \/>//g' $MODAEX
sed -i 's/<library name="proxy" path="removed" \/>//g' $MODAEX
sed -i 's/<effect name="removed" library="removed" uuid="removed" \/>//g' $MODAEX
sed -i 's/<effect name="removed" uuid="removed" library="removed" \/>//g' $MODAEX
sed -i 's/<libsw library="removed" uuid="removed" \/>//g' $MODAEX
sed -i 's/<libhw library="removed" uuid="removed" \/>//g' $MODAEX
sed -i 's/<apply effect="removed" \/>//g' $MODAEX
}

# setup audio effects conf
if [ "$MODAEC" ]; then
  if ! grep -Eq '^pre_processing {' $MODAEC; then
    sed -i -e '$a\
pre_processing {\
  mic {\
  }\
  camcorder {\
  }\
  voice_recognition {\
  }\
  voice_communication {\
  }\
}\' $MODAEC
  else
    if ! grep -Eq '^  voice_communication {' $MODAEC; then
      sed -i "/^pre_processing {/a\  voice_communication {\n  }" $MODAEC
    fi
    if ! grep -Eq '^  voice_recognition {' $MODAEC; then
      sed -i "/^pre_processing {/a\  voice_recognition {\n  }" $MODAEC
    fi
    if ! grep -Eq '^  camcorder {' $MODAEC; then
      sed -i "/^pre_processing {/a\  camcorder {\n  }" $MODAEC
    fi
    if ! grep -Eq '^  mic {' $MODAEC; then
      sed -i "/^pre_processing {/a\  mic {\n  }" $MODAEC
    fi
  fi
fi

# setup audio effects xml
if [ "$MODAEX" ]; then
  if ! grep -Eq '<preprocess>' $MODAEX; then
    sed -i '/<\/effects>/a\
    <preprocess>\
        <stream type="mic">\
        <\/stream>\
        <stream type="camcorder">\
        <\/stream>\
        <stream type="voice_recognition">\
        <\/stream>\
        <stream type="voice_communication">\
        <\/stream>\
    <\/preprocess>' $MODAEX
  else
    if ! grep -Eq '<stream type="voice_communication">' $MODAEX; then
      sed -i "/<preprocess>/a\        <stream type=\"voice_communication\">\n        <\/stream>" $MODAEX
    fi
    if ! grep -Eq '<stream type="voice_recognition">' $MODAEX; then
      sed -i "/<preprocess>/a\        <stream type=\"voice_recognition\">\n        <\/stream>" $MODAEX
    fi
    if ! grep -Eq '<stream type="camcorder">' $MODAEX; then
      sed -i "/<preprocess>/a\        <stream type=\"camcorder\">\n        <\/stream>" $MODAEX
    fi
    if ! grep -Eq '<stream type="mic">' $MODAEX; then
      sed -i "/<preprocess>/a\        <stream type=\"mic\">\n        <\/stream>" $MODAEX
    fi
  fi
fi

# store
LIB=libozoprocessing.so
LIBNAME=ozo_processing
NAME=ozo
UUID=7e384a3b-7850-4a64-a097-884250d8a737
RMV="$LIB $LIBNAME $NAME $UUID"

# patch audio effects conf
if [ "$MODAEC" ]; then
  remove_conf
  sed -i "/^libraries {/a\  $LIBNAME {\n    path $LIBPATH\/$LIB\n  }" $MODAEC
  sed -i "/^effects {/a\  $NAME {\n    library $LIBNAME\n    uuid $UUID\n  }" $MODAEC
  sed -i "/^  camcorder {/a\    $NAME {\n    }" $MODAEC
  sed -i "/^  mic {/a\    $NAME {\n    }" $MODAEC
  sed -i "/^  voice_recognition {/a\    $NAME {\n    }" $MODAEC
  sed -i "/^  voice_communication {/a\    $NAME {\n    }" $MODAEC
fi

# patch audio effects xml
if [ "$MODAEX" ]; then
  remove_xml
  sed -i "/<libraries>/a\        <library name=\"$LIBNAME\" path=\"$LIB\"\/>" $MODAEX
  sed -i "/<effects>/a\        <effect name=\"$NAME\" library=\"$LIBNAME\" uuid=\"$UUID\"\/>" $MODAEX
  sed -i "/<stream type=\"camcorder\">/a\            <apply effect=\"$NAME\"\/>" $MODAEX
  sed -i "/<stream type=\"mic\">/a\            <apply effect=\"$NAME\"\/>" $MODAEX
  sed -i "/<stream type=\"voice_recognition\">/a\            <apply effect=\"$NAME\"\/>" $MODAEX
  sed -i "/<stream type=\"voice_communication\">/a\            <apply effect=\"$NAME\"\/>" $MODAEX
fi


