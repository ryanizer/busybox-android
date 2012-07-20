
DEBUG=0

if [ $DEBUG -ne 0 ]; then
    set -x
    trap '{ set +e; set +x; set +u; };' INT QUIT EXIT
else
    trap '{ set +e; set +u; };' INT QUIT EXIT
fi

set -e
set -u

if [ $# -ne 1 ] ; then
    echo "main() takes one parameter, an int indicating to install or uninstall"
    return 0
fi

INSTALL="$1"
BACKUP="0"
BDIR="/data/local/busybox_backup"
SYSDIR="/system/bin"

if [ $INSTALL -eq 1 ] ; then
    if [ ! -f  "$BDIR/done" ] ; then
        echo "existing backup not detected, will attempt to create it at $BDIR"
        mkdir -p $BDIR >& /dev/null
        BACKUP=1
    fi

    if [ $BACKUP -eq 1 ] ; then
        echo "backing up existing files that will be clobbered"
        echo "#!/system/bin/busybox/ash" > restore_backup.sh
        for c in `busybox --list`; do
            if [ -f "$SYSDIR/$c" ] ; then
                echo "    cp -f $SYSDIR/$c $BDIR/"
                busybox cp -f $SYSDIR/$c $BDIR/
                perms=`busybox stat -c "%a" $SYSDIR/$c`
                echo "busybox chmod $PERMS $SYSDIR/$c" >> restore_backup.sh
            fi
        done
        echo "done" > "$BDIR/done"

        #prevent clobberage
        busybox chmod -R 444 $BDIR
    fi

    for c in `busybox --list`; do
        if [ `busybox stat -c "%F"` -eq "
    done

    echo "creating links for busybox commands"
    for c in `busybox --list`; do
        echo "    rm -f $SYSDIR/$c"
        busybox rm -f $SYSDIR/$c
        echo "    ln -s busybox $SYSDIR/$c"
        busybox ln -s busybox $SYSDIR/$c
    done
    return 0
else
    if [ -d "$BDIR" ] && [ -f "$BDIR/done" ] ; then
        echo "confirmed valid backup exists"

        echo "removing busybox links"
        for c in `busybox --list`; do
            echo "    busybox rm -f $SYSDIR/$c"
            busybox rm -f $SYSDIR/$c
        done

        echo "replacing original files from backup location"
        echo "    busybox mv $BDIR/* $SYSDIR/"
        busybox mv $BDIR/* $SYSDIR/
        for c in `ls $BDIR/*.perms`; do
            perms=`cat $c`
            busybox chmod $perms $SYSDIR/
        return 0
    echo
        echo "failed to detect backup"
        echo "$BDIR must exist and contain a file called \"done\""
    fi
fi
return 1

