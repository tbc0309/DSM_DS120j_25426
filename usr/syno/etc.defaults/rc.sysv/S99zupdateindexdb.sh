#!/bin/sh
#

# 1 = download failure
# 2 = extract failure
# 3 = fail to get url

G_Running_File_Path="/tmp/downloadHelp.running"
G_Error_File_Path="/tmp/downloadHelp.error"
G_Download_Tar="/usr/syno/synoman/indexdb/tmp/indexdb.tgz"

syslog() {
        local ret=$?
        logger -p user.err -t $(basename $0) "$@"
        return $ret
}

getIndexDB() {
        getUpdateServer
        mkdir -p /usr/syno/synoman/indexdb/tmp/
        if [ 0 -eq $? -a -n "$G_update_server" ]; then       
                get="--data-urlencode timezone=$G_timeZone --data-urlencode dsm_version=$G_DSMVersion --data-urlencode version=$G_dsmVersion --data-urlencode platform=$G_platform  --data-urlencode model=$G_model"
                G_Response=`curl -G  $get ${G_update_server}indexdbupdate/getIndexdb.php`
                if [ 0 -eq $? ]; then
                    echo $G_Response > /tmp/indexdb.json
                    G_URL=`grep "url" /tmp/indexdb.json | cut -d'"' -f4`
                    G_URL=`echo $G_URL | sed -e 's/\\\//g'`
                    #syslog $G_URL
                    G_md5=`grep "md5" /tmp/indexdb.json | cut -d',' -f2 | cut -d':' -f2 | cut -d'"' -f2 | cut -d'"' -f1`
                    G_SUCCESS=`grep "success" /tmp/indexdb.json | cut -d',' -f3 | cut -d':' -f2 | cut -d'}' -f1`
                    rm -f /tmp/indexdb.json
                else
                    rm -f $G_Running_File_Path
                    echo "error=3" > $G_Error_File_Path
                fi
        else
                rm -f $G_Running_File_Path
                echo "error=3" > $G_Error_File_Path
        fi

        if [ 0 -eq $? -a "$G_SUCCESS" == "true" ]; then
                echo $G_URL
                wget -O $G_Download_Tar $G_URL --no-check-certificat
                md5=`/usr/bin/openssl md5 $G_Download_Tar 2>/dev/null | cut -d' ' -f2`
                if [ 0 -eq $? -a -f $G_Download_Tar -a "$md5" == "$G_md5" ];
                then
                        rm -rf /usr/syno/synoman/indexdb/appindexdb
                        rm -rf /usr/syno/synoman/indexdb/helpindexdb
                        
                        if [ 0 -eq $? -a -f $G_Download_Tar ]; then
                                mkdir -p /usr/syno/synoman/indexdb/tmp/extract
                                tar -xf $G_Download_Tar -C /usr/syno/synoman/indexdb/tmp/extract
                                if [ 0 -eq $? ]; then
                                        cp -af /usr/syno/synoman/indexdb/tmp/extract/* /usr/syno/synoman/indexdb
                                        rm -rf /usr/syno/synoman/indexdb/tmp/
                                else
                                        rm -f $G_Running_File_Path
                                        rm -rf /usr/syno/synoman/indexdb/tmp/
                                        echo "error=2" > $G_Error_File_Path
                                        exit 2
                                fi
                        fi
                else
                        echo "error=1" > $G_Error_File_Path
                        rm -f $G_Running_File_Path
                        rm -rf /usr/syno/synoman/indexdb/tmp/
                        exit 1
                fi
        else
                rm -f $G_Running_File_Path
                echo "error=3" > $G_Error_File_Path
                rm -rf /usr/syno/synoman/indexdb/tmp/
                exit 3
        fi
}

getPlatform() {
        G_platform=`uname -a | awk '{print $NF}' | cut -d'_' -f2`
}

getUpdateServer() {
        G_update_server=`grep "update_server" /etc.defaults/synoinfo.conf  | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'"' -f1`
}

getModel() {
        G_model=`uname -a | awk '{print $NF}' | cut -d'_' -f3`
}

getVersion() {
        G_dsmVersion=`uname -a | sed 's/ /\n/g' | grep ^# | cut -d'#' -f2`
}

getIndexdbVersion() {
        G_indexdbVersion=`grep "buildnumber" /usr/syno/synoman/indexdb/indexdb.version  | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'"' -f1`
}

getTimeZone() {
        G_timeZone=`grep "timezone" /etc/synoinfo.conf  | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'"' -f1`
}

getMinorVersion() {
        G_MinorVersion=`grep "minorversion" /etc.defaults/VERSION | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'"' -f1`
}

getMajorVersion() {
        G_MajorVersion=`grep "majorversion" /etc.defaults/VERSION | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'"' -f1`
}

getDSMVersion() {
        getMajorVersion
        getMinorVersion
        G_DSMVersion="DSM${G_MajorVersion}.${G_MinorVersion}"
}

main() {
        if [ -f $G_Running_File_Path ];
        then
                exit
        fi

        touch $G_Running_File_Path
        rm -f $G_Download_Tar
        rm -f $G_Error_File_Path

        getDSMVersion
        getTimeZone
        getModel
        getPlatform
        getVersion

        if [ -f /usr/syno/synoman/indexdb/indexdb.version ]; then
                getIndexdbVersion
                if [ $G_dsmVersion != $G_indexdbVersion ]; then
                        getIndexDB
                fi
        else
                getIndexDB
        fi
        rm -f $G_Running_File_Path
}

main &
