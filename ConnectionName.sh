#!/bin/sh
DIALOG=${DIALOG=dialog}
ConnectionName="/opt/tak/certs/ConnectionName.txt"

$DIALOG --backtitle "TAK Server Management Console created by S.W. Denissen (github.com/DenissenStefan)" \
        --title "TAK Server Management Console" --clear \
        --inputbox "Please enter the IP or DNS name you want to use to connect to your TAK Server:" 16 51 2> $ConnectionName

retval=$?

case $retval in
  0)
    echo "Connection name is set as `cat $ConnectionName`"
    ;;
  1)
    echo "Cancel pressed."
    ;;
  255)
    if test -s $ConnectionName ; then
      cat $ConnectionName
    else
      echo "ESC pressed."
    fi
    ;;
esac