#!/bin/bash
# skc Set Kernel Version
# This sets the kernel version so that we
# can append/insert the kernel version and 
# revision to external kernel modules.
  _skv_BUILDCONF=conf/local.conf
  _skv_KERNELDIR=../layers/meta-multitech/recipes-kernel/linux
  _skv_KERNBB=${_skv_KERNELDIR}/linux-at91_*.bb
  if ! [[ -f $_skv_BUILDCONF ]] ; then
     echo "Current directory is $(pwd) and must be the build directory."
     echo "ERROR: Cannot find $_skv_BUILDCONF"
     unset _skv_BUILDCONF _skv_KERNELDIR _skv_KERNBB
     if ! return 1 2>/dev/null ; then
       exit 1
     fi
  fi
  _skv_ex_version=$(egrep '^PR[[:space:]]*=' ${_skv_KERNBB})
  if ((${#_skv_ex_version})) && [[ $_skv_ex_version =~ =[[:space:]]*([^[:space:]#]*) ]] ; then
    _skv_MLINUX_KERNEL_EXTRA_VERSION="${BASH_REMATCH[1]}"
    _skv_repl="MLINUX_KERNEL_EXTRA_VERSION = ${_skv_MLINUX_KERNEL_EXTRA_VERSION}"
    _skv_old=$(egrep '^MLINUX_KERNEL_EXTRA_VERSION[[:space:]]*=' ${_skv_BUILDCONF} | tail -1)
    if [[ ${_skv_old} !=  ${_skv_repl} ]] ; then
      sed -ri '/^MLINUX_KERNEL_EXTRA_VERSION[[:space:]]*=/d' ${_skv_BUILDCONF}
      echo "MLINUX_KERNEL_EXTRA_VERSION = ${_skv_MLINUX_KERNEL_EXTRA_VERSION}" >>${_skv_BUILDCONF}
    fi
  fi
  if ! [[ -d ${_skv_KERNELDIR} ]] ; then
    echo "Linux Kernel recipe directory is missing: ${_skv_KERNELDIR}"
    unset _skv_BUILDCONF _skv_KERNELDIR _skv_KERNBB
    unset _skv_repl _skv_old _skv_ex_version _skv_MLINUX_KERNEL_EXTRA_VERSION
    if ! return 1 2>/dev/null ; then
      exit 1
    fi
  fi
    
  _skv_krecipe=$(echo $(cd ../layers/meta-multitech/recipes-kernel/linux;echo linux-at91_*.bb))
  _skv_old=$(egrep '^MLINUX_KERNEL_VERSION[[:space:]]*=' ${_skv_BUILDCONF} | tail -1)

  
  if ((${#_skv_krecipe})) && [[ $_skv_krecipe =~ linux-at91_(.*).bb$ ]] ; then
    _skv_MLINUX_KERNEL_VERSION="${BASH_REMATCH[1]}"
    _skv_repl="MLINUX_KERNEL_VERSION = \"${_skv_MLINUX_KERNEL_VERSION}\""
    if [[ ${_skv_old} !=  ${_skv_repl} ]] ; then
        sed -ri '/^MLINUX_KERNEL_VERSION[[:space:]]*=/d' ${_skv_BUILDCONF}
        echo "${_skv_repl}" >>${_skv_BUILDCONF}
    fi
  fi
  
  unset _skv_BUILDCONF _skv_KERNELDIR _skv_KERNBB _skv_MLINUX_KERNEL_VERSION
  unset _skv_repl _skv_old _skv_ex_version _skv_MLINUX_KERNEL_EXTRA_VERSION
