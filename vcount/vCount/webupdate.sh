#!/bin/bash

SERVICE_NAME=vc_super.sh
SETTINGS_PATH=/usr/local/bin/tomcat/webapps/vcount/vCount
VCOUNT_PATH=/usr/local/bin/vcount

FLAG=$SETTINGS_PATH/flag
SETTINGS_DECRYPTED=$SETTINGS_PATH/settings_decrypted.xml
SETTINGS_ENCRYPTED=$SETTINGS_PATH/settings_encrypted.xml

CRYPTOR=$VCOUNT_PATH/cryptor
VCOUNT_SETTINGS=$VCOUNT_PATH/settings.xml

REPORTS=$VCOUNT_PATH/ext/reports
CACHE=$VCOUNT_PATH/ext/cache

LOG_FILE=$VCOUNT_PATH/ext/log/log.txt
START_TIME=$(date +%s)

IS_RUNNING=1
STOP_FLAG=./stop.flag


UPDATE_PATH=$SETTINGS_PATH/update
PATCH=$(ls $UPDATE_PATH/*.tar.gz.c 2>/dev/null)
TMPDIR=/tmp/update$$
PATCH_PASSWORD="rferwe434kjlrew32490hANKabkj"
UPDATE_FINISHED_FLAG=$UPDATE_PATH/updatefinished.flag


log() {
    echo "$(date):$$: $1 " >> $LOG_FILE
}
    
if [ "$PATCH" ]; then
    log "Update started with patch: $PATCH"
    sudo rm -f $UPDATE_FINISHED_FLAG
    sudo /etc/init.d/vcount stop
    sleep 3
    mkdir $TMPDIR

    cp $PATCH $TMPDIR
    PATCH=${PATCH##*/}
    #TARBALL=$(echo patch.tar.gz.c | sed 's/\(.*\).c/\1/')
    TARBALL=${PATCH%.*}
    PATCH_DIR=$TMPDIR/${TARBALL%.*.*}                
    MAP_SCRIPT=/tmp/map.sh
    MAP_FILE=$PATCH_DIR/mapfile.txt

    echo $PATCH_PASSWORD | gpg --no-tty --passphrase-fd 0 --output $TMPDIR/$TARBALL -d $TMPDIR/$PATCH 2>> $LOG_FILE

    if [ ! -f $TMPDIR/$TARBALL ]; then
        log "Error while decoding tarball"
        return -1
    fi

    tar -C $TMPDIR -xf $TMPDIR/$TARBALL
            
    if [ ! -f $MAP_FILE ]; then
        log "ERROR: Mapfile doesn't exist!"
    fi    
            
    ### Write script for file coping
    ###to make possible to update this vc_super.sh script
    echo "#!/bin/bash" > $MAP_SCRIPT
    echo "for item in \$(ls $PATCH_DIR); do" >> $MAP_SCRIPT
    echo "EXISTS=\$(grep \"\$item \" $MAP_FILE | grep -v grep | awk '{print \$1}')" >> $MAP_SCRIPT
    echo "if [ \"\$EXISTS\" ]; then"  >> $MAP_SCRIPT
    echo "TYPE=\$(grep \"\$item \" $MAP_FILE | grep -v grep | awk '{print \$2}')"  >> $MAP_SCRIPT
    echo "RIGHTS=\$(grep \"\$item \" $MAP_FILE | grep -v grep | awk '{print \$3}')"  >> $MAP_SCRIPT
    echo "DEST=\$(grep \"\$item \" $MAP_FILE | grep -v grep | awk '{print \$4}')"  >> $MAP_SCRIPT
    echo "if [ \"\$TYPE\" = \"d\" ]; then"  >> $MAP_SCRIPT
    echo "rm -rf \$DEST/*; cp -R $PATCH_DIR/\$item/* \$DEST; chmod -R \$RIGHTS \$DEST"  >> $MAP_SCRIPT
    echo "elif [ \"\$TYPE\" = \"f\" ]; then" >> $MAP_SCRIPT
    echo "cp -R $PATCH_DIR/\$item \$DEST; chmod \$RIGHTS \$DEST/\$item" >> $MAP_SCRIPT
    echo "fi" >> $MAP_SCRIPT
    echo "fi" >> $MAP_SCRIPT
    echo "done" >> $MAP_SCRIPT
    echo "if [ -f $PATCH_DIR/update.sh ]; then"  >> $MAP_SCRIPT
    echo "$PATCH_DIR/update.sh $PATCH_DIR" >> $MAP_SCRIPT
    echo "fi" >> $MAP_SCRIPT
        
    chmod +x $MAP_SCRIPT
        
    sleep 1
    
    $MAP_SCRIPT
    
    rm -rf $TMPDIR
    rm -rf $UPDATE_PATH/*
    
    log "Finish update"
    
    sudo /etc/init.d/vcount start
    echo 1 > $UPDATE_FINISHED_FLAG
 fi
