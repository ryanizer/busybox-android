#!/bin/bash

# I modified the original script as below for use with my rooted Atrix phone.
# I'm using a retail build that still thinks it's a production device.
# The best way to state this is that ro.secure=1 in default.prop, but su
# executes under a shell on the device and yields root permissions
#
# Another oddity that I encountered is that mv can fail giving
# errors citing cross-device linkage:
#     It seems that this error is given because mv tries
#     to move the hard link to the data, but fails because
#     in this case, the src and dest filesystems aren't the same.
#
# Symptoms of this state are that the following adb commands fail (not an ordered list, but executing any atomically):
#   adb remount
#   adb ls /data/app/
#   adb root
# but executing this works fine:
#   adb shell
#   $ su
#   $ ls /data/app/
#

LOCAL_DIR=`dirname $0`
SCRIPT='android-remote-install.sh'
TMP='/sdcard'
TGT='/system/bin'
TMPIFS="$IFS"

function execMount()
{
    local cmd="$@"
    local output=
    "mount -o remount,rw /system"
}

function rootExec()
{
    echo -e "su\n\n$@\nexit\n\nexit\n\n" | adb shell
}

function usage()
{
    echo "$0 [install | uninstall]"
    echo "This script should be called with exactly one parameter, exiting"
}

function doMain()
{
    if [ $# -ne 1 ] ; then
        echo ne1
        usage
        return 1
    elif ! [ $1 == "install" ] || [ $1 == "uninstall" ] ; then
        usage
        return 1
    fi


    # move the files over to an adb writable location
    adb push $LOCAL_DIR/busybox-android $TMP/
    adb push $LOCAL_DIR/$SCRIPT $TMP/
    
    # now execute a string of commands over one adb connection using a
    # so-called here document
    # redirect chatter to /dev/null -- adb apparently puts stdin and stderr in
    # stdin so to add error checking we'd need to scan all the text
adb shell <<-DONE
	su
	# this is a remount form that works on "partially rooted devices"
	mount -o remount,rw /system
	cat $TMP/busybox-android > $TGT/busybox
	rm $TMP/busybox-android
	chmod 755 $TGT/busybox
	cat $TMP/$SCRIPT > $TGT/$SCRIPT
	rm $TMP/$SCRIPT
	cd $TGT
	chmod 755 $SCRIPT
	exit
	exit
DONE

    # cleanup tmp file
    CLEANUP="rm $TGT/$SCRIPT"

    IFS=
    if [ $1 == "install" ] ; then
        rootExec "busybox ash $TGT/$SCRIPT 1\n$CLEANUP"
    elif [ $1 == "uninstall" ] || [ $1 == "remove" ] ; then
        CLEANUP="${CLEANUP}\nrm $TGT/busybox"
        rootExec "busybox ash $TGT/$SCRIPT 0\n$CLEANUP"
    fi
    IFS="$TMPIFS"
}

doMain $1

