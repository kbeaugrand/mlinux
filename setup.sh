#!/usr/bin/env bash

set -e

if [ "$1" != "--update" ]; then
  echo ""
  echo "Setting up git hooks..."
  ln -s ../../scripts/git-hooks/post-merge .git/hooks/post-merge || true
  ln -s ../../scripts/git-hooks/post-checkout .git/hooks/post-checkout || true
  ln -s ../../scripts/git-hooks/pre-commit .git/hooks/pre-commit || true
  ln -s ../../scripts/git-hooks/pre-push .git/hooks/pre-push || true
fi

echo ""
echo "Updating git submodules..."
git submodule update --init

if [ "$1" != "--update" ]; then
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
fi

echo ""
echo "Setup Done."
echo ""
echo "To build mlinux-base-image:"
echo "   source env-oe.sh"
echo "   bitbake mlinux-base-image"
echo ""
echo "To build mlinux-mtcap-image:"
echo "   source env-oe.sh"
echo "   MACHINE=mtcap bitbake mlinux-mtcap-image"

