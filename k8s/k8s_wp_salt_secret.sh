#!/usr/bin/env bash
# https://struscode.com
# Creates a file containing Kubernetes Secret with base64 encoded key and satl values retrieved from Wordpress API

# store multiline text in env var
read -r -d '' SECRET_PREFIX << EOM
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
EOM

API_RESPONSE=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)

FILENAME=secret-$(date '+%Y%m%dT%H%M').yaml
prefix="define('"
suffix="');"

if [ ! -z "$API_RESPONSE" -a "$API_RESPONSE" != " " ]; then
    printf "$SECRET_PREFIX\n" > $FILENAME
    while read -r line; do
        tmp=${line#$prefix}
        tmp=${tmp%$suffix}
        tmp=$(echo $tmp | sed -e "s/',[[:space:]]\+'/ /g")
        vname=$(echo $tmp | cut -d' ' -f1)
        salt=$(echo $tmp | cut -d' ' -f2- | base64 -w 0)
        printf "  $vname: $salt\n" >> $FILENAME
    done <<< "$API_RESPONSE"
    echo -e "File $FILENAME has been created"
else
    echo -e "Problem with API response\n"
    echo -e "$API_RESPONSE"
    exit 1
fi
