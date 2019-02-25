#!/bin/bash

TARBALL_NAME="gather-data-compressed.tar.gz"
SCRIPT_NAME="gather-data-selfcontained.sh"
COMMAND_TO_RUN="gather-data.sh"
source=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)

if [ $TARBALL_NAME == "" ] ; then
	echo "No suitable tarball name given."
	exit 1
fi

if [ $SCRIPT_NAME == "" ] ; then
	echo "No output filename provided."
	exit 1
fi

if [ -e $source/bin ] | [ -e $source/gather-data.sh ] ; then
	echo "Creating tarball that contains the contents of $source/bin and $source/gather-data.sh..."
	pushd .. > /dev/null 2>&1
	tar -zcvf $TARBALL_NAME bin gather-data.sh > /dev/null 2>&1
	popd > /dev/null 2>&1
else
	echo "Can't find appropriate INVENTORYWARE_ROOT/support/bin directory or gather-data.sh script to tar."
	exit 1
fi

if [ -e $source/regen/tartos.sh ] ; then
	echo "Now creating a self extracting script..."
	pushd $source > /dev/null 2>&1
	$source/regen/tartos.sh "$TARBALL_NAME" "$SCRIPT_NAME" "$COMMAND_TO_RUN" > /dev/null 2>&1
	rm $source/$TARBALL_NAME
	echo "Complete - script can now be found at $source/$SCRIPT_NAME"
else
	echo "Cannot find 'tartos' script"
	exit 1
fi