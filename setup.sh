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
  ex_version=$(egrep '^PR[[:space:]]*=' layers/meta-multitech/recipes-kernel/linux/linux_*.bb)
  if ((${#ex_version})) && [[ $ex_version =~ =[[:space:]]*([^[:space:]#]*) ]] ; then
    MLINUX_KERNEL_EXTRA_VERSION="${BASH_REMATCH[1]}"
    sed -ri '/^MLINUX_KERNEL_EXTRA_VERSION[[:space:]]*=/d' conf/local.conf
    echo "MLINUX_KERNEL_EXTRA_VERSION = ${MLINUX_KERNEL_EXTRA_VERSION}" >>conf/local.conf
  fi
  krecipe=$(echo $(cd layers/meta-multitech/recipes-kernel/linux;echo linux_*.bb))
  if ((${#krecipe})) && [[ $krecipe =~ linux_(.*).bb$ ]] ; then
    MLINUX_KERNEL_VERSION="${BASH_REMATCH[1]}"
    sed -ri '/^MLINUX_KERNEL_VERSION[[:space:]]*=/d' conf/local.conf
    echo "MLINUX_KERNEL_VERSION = \"${MLINUX_KERNEL_VERSION}\"" >>conf/local.conf
  fi
  root_pwd_hash=$(egrep '^ROOT_PASSWORD_HASH[[:space:]]*=' conf/local.conf || true)
  if ((${#root_pwd_hash} == 0)) ; then
    if [[ "$ROOT_PASSWORD" ]] ; then
      pass=$ROOT_PASSWORD
    else
      pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 2>/dev/null | head -c${1:-8};echo)
    fi
    salt="$(openssl rand -base64 128 2>/dev/null)"
    hash="$(openssl passwd -1 -salt "$salt" "$pass")"
    echo "ROOT_PASSWORD = \"$pass\"" >password.txt
    echo "HASH = \"$hash\"" >>password.txt
    echo "ROOT_PASSWORD_HASH = \"$hash\"" >>conf/local.conf
    sed -ri "d/ROOT_PASSWORD[[:space:]]=/" conf/local.conf || true
    echo "ROOT_PASSWORD = \"$pass\"" >>conf/local.conf
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

