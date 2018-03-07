#!/bin/sh
#$username=$1

echo "cleaning mdapi/"
rm -rf mdapi
mkdir mdapi
sfdx force:source:convert -r force-app/ -d mdapi/
sfdx force:mdapi:deploy -o -u $1 -d mdapi/ -w 10
