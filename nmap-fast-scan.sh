#!/bin/bash
fname=$(uuidgen -r)
ports=$(nmap -p- --min-rate=500 $1 | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//)
nmap -p$ports -A $1 -oN /tmp/$fname
echo "file saved in /tmp/"$fname