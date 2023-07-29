#!/usr/bin/env bash

# Google Sheet ID for published url
jamf=$(which jamf)
sheetID='Google Sheet ID'

# letter of column to use for device serial number
serialColumn='A'

# letter of column to use for asset tag
assetTagColumn='B'

# get serial number of device
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# uncomment for debug
# echo $serialNumber

# look up asset tag in google sheet based on serial number and return asset tag
assetTag=$(curl -s "https://docs.google.com/spreadsheets/d/$sheetID/gviz/tq?tqx=out:csv&tq=select%20$assetTagColumn%20where%20$serialColumn%20=%20'$serialNumber'" | tail -n +2)


# uncomment for debug
echo $assetTag

# If asset tag is blank
if [ -z "$assetTag" ]
then
    # show message
    echo "Asset tag not found in Google Sheet"
fi

# If asset tag is not blank
if [ -n "$assetTag" ]
then
    # rename device
    newHostname=S$(echo $assetTag | tr -d '"')
    scutil --set ComputerName $newHostname
    scutil --set LocalHostName $newHostname
    scutil --set HostName $newHostname
    # set computer name in jamf
    $jamf setComputerName -name $newHostname
    # set asset tag in jamf
    $jamf recon -assetTag $assetTag

    dscacheutil -flushcache

fi
