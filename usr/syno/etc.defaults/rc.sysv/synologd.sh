#!/bin/sh

SYNOLOGD="/usr/syno/bin/synologd"
PID_FILE="/var/run/synologd.pid"
PGUPGRADE_FLAG="/tmp/.UpgradePGSQLDatabase"
SQLITE="/bin/sqlite3"

get_pid()
{
    if [ ! -f ${PID_FILE} ]; then
        echo "${PID_FILE} not found. Not running?"
        return 1
    else
        pid=`cat ${PID_FILE} 2>/dev/null`
        if [ -f /proc/$pid/cmdline ]; then
            echo $pid
            return 0
        else
            rm -f ${PID_FILE}
            echo "${PID_FILE} is found, but not running?"
            return 1
        fi
    fi
}

FuncCheckDB()
{
    if [ -e $PGUPGRADE_FLAG ] || ! pidof postgres; then
        echo "PGSQL is not available"
        exit 1;
    fi

    echo "Checking synolog database existence..."
    su postgres -c "/usr/bin/psql synolog -c \"SELECT 1 FROM ftpxfer LIMIT 1\" > /dev/null"
    Ret=$?
    if [ $Ret = 2 ]; then
        echo "Creating synolog database..."
        su postgres -c "/usr/bin/createdb synolog"
        if [ $? != 0 ]; then
            echo "Failed to create database"
            exit 1
        fi
        Ret=1
    fi

    if [ $Ret = 1 ]; then
        echo "Creating synolog tables..."
        su postgres -c "/usr/bin/psql synolog -f /usr/syno/synologd/sql/synolog.pgsql"
        if [ $? != 0 ]; then
            echo "Failed to create tables in synolog database"
            exit 1
        fi
    elif [ $Ret = 0 ]; then
        upgrades=`find /usr/syno/synologd/sql/upgrade -name "*.sh" | sort`
        for ThisArg in $upgrades;
        do
            $ThisArg
        done
    else
        echo "Unknown error"
        exit 1
    fi

    return 0
}

FuncDropWebfmTable()
{
    echo "Drop TABLE webfmxfer ..."
    su postgres -c "/usr/bin/psql synolog -c \"SELECT 1 FROM webfmxfer LIMIT 1\" > /dev/null"
    if [ $? = 0 ]; then
        su postgres -c "/usr/bin/psql synolog -c \"INSERT INTO dsmfmxfer SELECT * FROM webfmxfer\" > /dev/null"
        if [ $? != 0 ]; then
            echo "Fail to SELECT * INTO dsmfmxfer FROM webfmxfer"
        fi
        su postgres -c "/usr/bin/psql synolog -c \"DROP TABLE webfmxfer\" > /dev/null"
        if [ $? != 0 ]; then
            echo "Failed to DROP TABLE webfmxfer"
        fi
    fi
}

FuncCheckIfNeedRun()
{
    echo "Checking if need to run synologd..."
    /usr/syno/sbin/synoservice --is-enabled ftpd
    RunFTP=$?
    /usr/syno/sbin/synoservice --is-enabled ftpd-ssl
    RunFTPS=$?
    /usr/syno/sbin/synoservice --is-enabled sftp
    RunSFTP=$?
    /usr/syno/sbin/synoservice --is-enabled tftp
    RunTFTP=$?
    LogFTP=`/bin/get_key_value /etc/synoinfo.conf ftpxferlog`
    LogTFTP=`/bin/get_key_value /etc/synoinfo.conf tftpxferlog`
    LogDSMFM=`/bin/get_key_value /etc/synoinfo.conf filebrowserxferlog`
    RunWEBDAV=`/bin/get_key_value /var/packages/WebDAVServer/target/etc/webdav.cfg enable_http`
    RunWEBDAVS=`/bin/get_key_value /var/packages/WebDAVServer/target/etc/webdav.cfg enable_https`
    LogWEBDAV=`/bin/get_key_value /etc/synoinfo.conf webdavxferlog`
    /usr/syno/sbin/synoservice --is-enabled samba
    RunSMB=$?
    LogSMB=`/bin/get_key_value /etc/synoinfo.conf smbxferlog`
    /usr/syno/sbin/synoservice --is-enabled atalk
    RunAFP=$?
    LogAFP=`/bin/get_key_value /etc/synoinfo.conf afpxferlog`

    if [  "$RunFTP" -eq 1 -o "$RunFTPS" -eq 1 -o "$RunSFTP" -eq 1 ] && [ "yes" = "$LogFTP" ]; then
        return 0
    elif [ "$RunTFTP" -eq 1 ] && [ "yes" = "$LogTFTP" ]; then
        return 0
    elif [ "yes" = "$LogDSMFM" ]; then
        return 0
    elif [ "$RunSMB" -eq 1 ] && [ "yes" = "$LogSMB" ]; then
        return 0
    elif [ "$RunAFP" -eq 1 ] && [ "yes" = "$LogAFP" ]; then
        return 0
    elif [ "yes" == "$RunWEBDAV" -o "yes" == "$RunWEBDAVS" ] && [ "yes" = "$LogWEBDAV" ]; then
        return 0
    fi
    echo "No need to start synologd..."
    return 1
}

ConvertXferLogToSqlite()
{
    PGDUMP="/bin/pg_dump"
    PGSQL="/bin/psql"
    SYNOLOG_FOLDER="/var/log/synolog"
    ALIVE_VOLUME="$(/usr/syno/bin/servicetool --get-first-alive-volume)"
    XFERLOG_FOLDER="$ALIVE_VOLUME/@database/synolog"
    TYPES="ftpxfer dsmfmxfer webdavxfer smbxfer afpxfer tftpxfer"

    if [ -e $PGUPGRADE_FLAG ] || ! pidof postgres > /dev/null; then
        echo "PGSQL is not available"
        exit 1;
    fi

    if [ "${ALIVE_VOLUME:0:7}" != "/volume" ]; then
        echo "No available volume"
        return 1
    fi

    mkdir -p "$XFERLOG_FOLDER"
    chown -R system:log "$XFERLOG_FOLDER"

    for TYPE in $TYPES; do
        case $TYPE in
            ftpxfer)
                DBPATH="$XFERLOG_FOLDER/.FTPXFERDB"
                ;;
            dsmfmxfer)
                DBPATH="$XFERLOG_FOLDER/.DSMFMXFERDB"
                ;;
            webdavxfer)
                DBPATH="$XFERLOG_FOLDER/.WEBDAVXFERDB"
                ;;
            smbxfer)
                DBPATH="$XFERLOG_FOLDER/.SMBXFERDB"
                ;;
            afpxfer)
                DBPATH="$XFERLOG_FOLDER/.AFPXFERDB"
                ;;
            tftpxfer)
                DBPATH="$XFERLOG_FOLDER/.TFTPXFERDB"
                ;;
            *)
                echo "Unsupported type."
                exit 1
                ;;
        esac

        # init sqlite db
        if [ ! -f "$DBPATH" ]; then
            CREATE_TABLE="CREATE TABLE logs (
                id integer primary key,
                time int default NULL,
                ip text default NULL,
                username text default NULL,
                cmd text default NULL,
                filesize int default NULL,
                filename text default NULL,
                isdir integer default 0);"
            if ! $SQLITE $DBPATH "$CREATE_TABLE"; then
                echo "Create DB \"$TYPE\" failed."
                continue
            fi
            /bin/chown system:log $DBPATH
            /bin/chmod 660 $DBPATH
        fi

        # link db to /var/log/synolog
        ln -sf "$DBPATH" "$SYNOLOG_FOLDER/$db"

        # check table exist
        $PGSQL -U postgres synolog -c "\\dt" | grep -o " $TYPE " > /dev/null 2>&1 || continue

        # dump xferlog
        DUMP_SQL="/var/tmp/${TYPE}.sql"
        if ! $PGDUMP -U postgres --dbname=synolog --table=$TYPE --column-inserts --data-only | grep "INSERT" > $DUMP_SQL; then
            echo "Dump \"$TYPE\" failed."
            continue
        fi
        sed -i "s/INSERT INTO $TYPE/INSERT INTO logs/g; s/false/0/g; s/true/1/g" $DUMP_SQL
        sed -i '1i BEGIN TRANSACTION;' $DUMP_SQL
        sed -i "\$a COMMIT;" $DUMP_SQL

        if $SQLITE $DBPATH < $DUMP_SQL; then
            $PGSQL -U postgres synolog -c "DROP TABLE $TYPE" > /dev/null 2>&1
        else
            echo "Convert \"$TYPE\" to \"$DBPATH\" failed."
        fi
        rm -f $DUMP_SQL
    done
}

MoveXferLogToVolume()
{
    SYNOLOG_FOLDER="/var/log/synolog"

    if [ -L "$SYNOLOG_FOLDER/.SMBXFERDB" ]; then
        return 0
    fi

    XFERLOG_DBSIZE=$(du -d0 -m "$SYNOLOG_FOLDER" | awk '{print $1}')
    ALIVE_VOLUME="$(/usr/syno/bin/servicetool --get-alive-volume $XFERLOG_DBSIZE)"
    XFERLOG_FOLDER="$ALIVE_VOLUME/@database/synolog"
    XFERLOG_DBS=".AFPXFERDB .DSMFMXFERDB .FTPXFERDB .SMBXFERDB .TFTPXFERDB .WEBDAVXFERDB"

    if [ "${ALIVE_VOLUME:0:7}" != "/volume" ]; then
        echo "No available volume"
        return 1
    fi

    mkdir -p "$XFERLOG_FOLDER"
    for db in $XFERLOG_DBS; do
        [ -f "$SYNOLOG_FOLDER/$db" ] || touch "$SYNOLOG_FOLDER/$db"
        mv "$SYNOLOG_FOLDER/$db" "$XFERLOG_FOLDER/$db"
        ln -sf "$XFERLOG_FOLDER/$db" "$SYNOLOG_FOLDER/$db"
    done
    chown -R system:log "$XFERLOG_FOLDER"
}

InitXferLogDatabase()
{
    SYNOLOG_FOLDER="/var/log/synolog"
    XFERLOG_DBS=".AFPXFERDB .DSMFMXFERDB .FTPXFERDB .SMBXFERDB .TFTPXFERDB .WEBDAVXFERDB"
    CREATE_TABLE="CREATE TABLE logs (
        id integer primary key,
        time int default NULL,
        ip text default NULL,
        username text default NULL,
        cmd text default NULL,
        filesize int default NULL,
        filename text default NULL,
        isdir integer default 0);"

    local REAL_DBPATH=
    for db in $XFERLOG_DBS; do
        if [ -L "$SYNOLOG_FOLDER/$db" ]; then
            REAL_DBPATH="$(realpath "$SYNOLOG_FOLDER/$db")"
            if ! [ -s "$REAL_DBPATH" ]; then
                $SQLITE "$REAL_DBPATH" "$CREATE_TABLE"
            else
                echo "$db was inited."
            fi
        else
            echo "Error occured. $db should be a symlink."
        fi
    done
}

case $1 in
check_if_need_run)
    FuncCheckIfNeedRun
    exit $?
    ;;
check_db)
    FuncCheckDB
    exit $?
    ;;
drop_webfm_table)
    FuncDropWebfmTable
    exit 0
    ;;
convert_xferlog)
    ConvertXferLogToSqlite
    exit 0
    ;;
move_xferlog)
    MoveXferLogToVolume
    exit $?
    ;;
init_xferlog_db)
    InitXferLogDatabase
    exit 0
    ;;
*)
    echo "Usage: $0 [check_if_need_run|check_db|drop_webfm_table|convert_xferlog|move_xferlog|init_xferlog_db]"
    exit 0
    ;;
esac

