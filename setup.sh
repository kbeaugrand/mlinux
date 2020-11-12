#!/usr/bin/env bash

set -e
BUILDCONF=build/conf/local.conf

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
git submodule update --init --recursive

# Apply patches
for f in $(ls patches) ; do
  if patch --dry-run -Np1 < patches/$f ; then
    patch -Np1 < patches/$f
  fi
done

# Remove yocto-linux bbappend
rm -f layers/meta-virtualization/recipes-kernel/linux/linux-yocto_*.bbappend

if [ "$1" != "--update" ]; then
  if [ ! -d build/conf ]; then
    mkdir -p build/conf
  fi

  echo ""
  response=y
  test -f ${BUILDCONF} && read -p "Overwrite ${BUILDCONF} with defaults? (y/N) " response
  if [[ $response =~ ^y$ || $response =~ ^yes$ ]]; then
    echo "Creating default bitbake configuration..."
    cp layers/meta-mlinux/contrib/local.conf build/conf/
  else
    echo "Leaving existing ${BUILDCONF} alone."
  fi

  root_pwd_hash=$(egrep '^MTADM_PASSWORD_HASH[[:space:]]*=' ${BUILDCONF} || true)
  if ((${#root_pwd_hash} == 0)) ; then
    if [[ "$MTADM_PASSWORD" ]] ; then
      pass=$MTADM_PASSWORD
    else
      pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 2>/dev/null | head -c${1:-8};echo)
    fi
    salt="$(openssl rand -base64 128 2>/dev/null)"
    hash="$(openssl passwd -1 -salt "$salt" "$pass")"
    echo "MTADM_PASSWORD = \"$pass\"" >password.txt
    echo "HASH = \"$hash\"" >>password.txt
    sed -ri "/MTADM_PASSWORD_HASH[[:space:]]=/d" ${BUILDCONF} || true
    echo "MTADM_PASSWORD_HASH = \"$hash\"" >>${BUILDCONF}
    sed -ri "/MTADM_PASSWORD[[:space:]]=/d" ${BUILDCONF} || true
    echo "MTADM_PASSWORD = \"$pass\"" >>${BUILDCONF}
  fi
  
  echo ""
  response=y
  test -f build/conf/bblayers.conf && read -p "Overwrite build/conf/bblayers.conf with defaults? (y/N) " response
  if [[ $response =~ ^y$ || $response =~ ^yes$ ]]; then
    echo "Copying default bblayers..."
    OEROOT=$(pwd)
    sed -e "s?__OEROOT__?${OEROOT}?" conf/bblayers.conf.mlinux >build/conf/bblayers.conf
  else
    echo "Leaving existing build/conf/bblayers.conf alone."
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
  mkdir -p build
fi

echo ""
echo "Setup Done."
echo ""
echo "oe-init-build-env will set the current directory to build"
echo "One must be within the build tree to run bitbake."
echo ""
echo "To build mlinux-base-image:"
echo "   source oe-init-build-env"
echo "   bitbake mlinux-base-image"
echo ""
echo "To build mlinux-mtcap-image:"
echo "   source oe-init-build-env"
echo "   MACHINE=mtcap bitbake mlinux-mtcap-image"

