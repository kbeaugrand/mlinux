#!/usr/bin/env bash

set -e

echo ""
echo "Updating git submodules..."
git submodule update --init

response=y
test -f env-oe.sh && read -p "Overwrite env-oe.sh with defaults? (y/N) " response
if [[ $response =~ ^y$ || $response =~ ^yes$ ]]; then
	echo "Copying default environment script..."
	cp layers/meta-mlinux/contrib/env-oe.sh .
else
	echo "Leaving existing env-oe.sh alone."
fi

echo ""
response=y
test -f conf/local.conf && read -p "Overwrite conf/local.conf with defaults? (y/N) " response
if [[ $response =~ ^y$ || $response =~ ^yes$ ]]; then
	echo "Creating default bitbake configuration..."
	cp layers/meta-mlinux/contrib/local.conf conf/
else
	echo "Leaving existing conf/local.conf alone."
fi

echo ""
echo "Creating user-layer..."
mkdir -p layers/user-layer/conf
mkdir -p layers/user-layer/recipes-core

echo ""
response=y
test -f layers/user-layer/conf/layer.conf && read -p "Overwrite layers/user-layer/conf/layer.conf with defaults? (y/N) " response
if [[ $response =~ ^y$ || $response =~ ^yes$ ]]; then
	echo "Creating default user-layer configuration..."
	cp layers/meta-mlinux/contrib/user-layer.conf layers/user-layer/conf/layer.conf
else
	echo "Leaving existing layers/user-layer/conf/layer.conf alone."
fi

echo ""
echo "Creating directory structure..."
mkdir -p downloads
mkdir -p build

echo ""
echo "Setup Done."
echo ""
echo "To build mlinux-base-image:"
echo "   source env-oe.sh"
echo "   bitbake mlinux-base-image"