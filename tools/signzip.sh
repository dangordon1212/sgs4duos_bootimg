#!/bin/bash
JDIR=$(dirname $(readlink -f "$0"))
#echo "$JDIR"
IF="$1"
OF="${IF%.zip}"-signed.zip

java -jar "$JDIR"/signapk.jar "$JDIR"/testkey.x509.pem  "$JDIR"/testkey.pk8 "$PWD/$IF" "$PWD/$OF"

