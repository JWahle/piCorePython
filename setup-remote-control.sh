#!/bin/sh -e

PYCDSP_VERSION="v3.0.0"  # https://github.com/HEnquist/pycamilladsp/releases
EXTENSION_NAME="python-environment"
BUILD_DIR="/tmp/${EXTENSION_NAME}"
# TODO add tcz-dependencies, pip dependencies and python scripts to autostart

### Abort, if extension is already installed
if [ -f "/etc/sysconfig/tcedir/optional/${EXTENSION_NAME}.tcz" ]; then
    >&2 echo "Uninstall the ${EXTENSION_NAME} Extension and reboot, before installing it again"
    >&2 echo "In Main Page > Extensions > Installed > select '${EXTENSION_NAME}.tcz' and press 'Delete'"
    exit 1
fi

### Abort, if not enough free space
requiredSpaceInMB=100
availableSpaceInMB=$(/bin/df -m /dev/mmcblk0p2 | awk 'NR==2 { print $4 }')
if [[ $availableSpaceInMB -le $requiredSpaceInMB ]]; then
    >&2 echo "Not enough free space"
    >&2 echo "Increase SD-Card size: Main Page > Additional functions > Resize FS"
    exit 1
fi

### Ensure fresh build dir exists
if [ -d $BUILD_DIR ]; then
    >&2 echo "Reboot before running the script again."
    exit 1
fi
mkdir -p $BUILD_DIR

# Installs a module from the piCorePlayer repository - if not already installed.
# Call like this: install_if_missing module_name
install_if_missing(){
  if tce-status -u | grep -q "$1" ; then
    pcp-load -il "$1"
  elif ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil "$1"
  fi
}

# Installs a module from the piCorePlayer repository, at least until the next reboot - if not already installed.
# Call like this: install_temporarily_if_missing module_name
install_temporarily_if_missing(){
  if tce-status -u | grep -q "$1" ; then
    pcp-load -il "$1"
  elif ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil -t /tmp "$1" # Downloads to /tmp/optional and loads extensions temporarily
  fi
}

set -v


### Creating virtual environment
install_temporarily_if_missing git
install_if_missing python3.11
install_if_missing python3.11-evdev
sudo mkdir -m 775 "/usr/local/${EXTENSION_NAME}"
sudo chown root:staff "/usr/local/${EXTENSION_NAME}"
cd "/usr/local/${EXTENSION_NAME}"
python3 -m venv environment
sed -i 's|include-system-site-packages = false|include-system-site-packages = true|g' environment/pyvenv.cfg # include system packages in the environment
source environment/bin/activate # activate custom python environment
python3 -m pip install --upgrade pip
pip install git+https://github.com/HEnquist/pycamilladsp.git@${PYCDSP_VERSION}
mkdir -p ${BUILD_DIR}/usr/local/
sudo mv "/usr/local/${EXTENSION_NAME}" ${BUILD_DIR}/usr/local/


### Creating startup script
mkdir -p ${BUILD_DIR}/usr/local/tce.installed/
cd ${BUILD_DIR}/usr/local/tce.installed/
echo "#!/bin/sh
sudo -u tc sh -c '
while [ ! -f /usr/local/bin/python3 ]; do sleep 1; done
source /usr/local/${EXTENSION_NAME}/environment/bin/activate
while [ ! -f /home/tc/remote-control.py ]; do sleep 1; done
python3 -u /home/tc/remote-control.py > /tmp/remote-control.log 2>&1 &
' &" > "${EXTENSION_NAME}"
chmod 775 "${EXTENSION_NAME}"


### Creating tiny core extension
cd /tmp
install_temporarily_if_missing squashfs-tools
mksquashfs "${EXTENSION_NAME}" "${EXTENSION_NAME}.tcz"
mv -f "${EXTENSION_NAME}.tcz" /etc/sysconfig/tcedir/optional
echo "python3.11.tcz
python3.11-evdev.tcz" > "/etc/sysconfig/tcedir/optional/${EXTENSION_NAME}.tcz.dep"
echo "${EXTENSION_NAME}.tcz" >> /etc/sysconfig/tcedir/onboot.lst


### Backup and reboot
pcp backup
pcp reboot