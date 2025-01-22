#!/bin/sh -e

PYCDSP_VERSION="v3.0.0"  # https://github.com/HEnquist/pycamilladsp/releases
BUILD_DIR="/tmp/remote-control"

### Abort, if remote-control extension is already installed
if [ -f "/etc/sysconfig/tcedir/optional/remote-control.tcz" ]; then
    >&2 echo "Uninstall the remote-control Extension and reboot, before installing it again"
    >&2 echo "In Main Page > Extensions > Installed > select 'remote-control.tcz' and press 'Delete'"
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
install_if_missing() {
  if ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil "$1"
  fi
}

# Installs a module from the piCorePlayer repository, at least until the next reboot - if not already installed.
# Call like this: install_temporarily_if_missing module_name
install_temporarily_if_missing() {
  if ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil -t /tmp "$1" # Downloads to /tmp/optional and loads extensions temporarily
  fi
}

set -v


### Creating virtual environment
install_temporarily_if_missing git
install_if_missing python3.11
install_if_missing python3.11-evdev
cd /usr/local/
python3 -m venv remote-control
sed -i 's|include-system-site-packages = false|include-system-site-packages = true|g' remote-control/pyvenv.cfg # include system packages in the environment
(tr -d '\r' < remote-control/bin/activate) > remote-control/bin/activate_new # Create fixed version of the activate script. See https://stackoverflow.com/a/44446239
mv -f remote-control/bin/activate_new remote-control/bin/activate
source remote-control/bin/activate # activate custom python environment
python3 -m pip install --upgrade pip
pip install git+https://github.com/HEnquist/pycamilladsp.git@${PYCDSP_VERSION}
mkdir -p ${BUILD_DIR}/usr/local/
sudo mv /usr/local/remote-control ${BUILD_DIR}/usr/local/


### Creating startup script
mkdir -p ${BUILD_DIR}/usr/local/tce.installed/
cd ${BUILD_DIR}/usr/local/tce.installed/
echo "#!/bin/sh
sudo -u tc sh -c '
while [ ! -f /usr/local/bin/python3 ]; do sleep 1; done
source /usr/local/remote-control/bin/activate
while [ ! -f /home/tc/remote-control.py ]; do sleep 1; done
python3 -u /home/tc/remote-control.py > /tmp/remote-control.log 2>&1 &
' &" > remote-control
chmod 775 remote-control


### Creating tiny core extension
cd /tmp
install_temporarily_if_missing squashfs-tools
mksquashfs remote-control remote-control.tcz
mv -f remote-control.tcz /etc/sysconfig/tcedir/optional
echo "python3.11.tcz
python3.11-evdev.tcz" > /etc/sysconfig/tcedir/optional/remote-control.tcz.dep
echo remote-control.tcz >> /etc/sysconfig/tcedir/onboot.lst


### Backup and reboot
pcp backup
pcp reboot