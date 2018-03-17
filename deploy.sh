#!/bin/sh
#$username=$1

echo "cleaning mdapi/"
rm -rf mdapi
echo "making mdapi/"
mkdir mdapi
echo "converting to mdapi folder"
sfdx force:source:convert -r force-app/ -d mdapi/
echo "deploying..."
sfdx force:mdapi:deploy -o -u $1 -d mdapi/ -w 10
