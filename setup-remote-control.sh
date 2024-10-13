#!/bin/sh -e

# Installs a module from the piCorePlayer repository - if not already installed.
# Call like this: install_if_missing module_name
install_if_missing(){
  if ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil "$1"
  fi
}

# Installs a module from the piCorePlayer repository, at least until the next reboot - if not already installed.
# Call like this: install_temporarily_if_missing module_name
install_temporarily_if_missing(){
  if ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil -t /tmp "$1" # Downloads to /tmp/optional and loads extensions temporarily
  fi
}

set -v

install_temporarily_if_missing git
install_if_missing python3.11
install_if_missing python3.11-evdev
cd /usr/local/
python3 -m venv remote-control
sed -i 's|include-system-site-packages = false|include-system-site-packages = true|g' remote-control/pyvenv.cfg
(tr -d '\r' < remote-control/bin/activate) > remote-control/bin/activate_new # Create fixed version of the activate script. See https://stackoverflow.com/a/44446239
mv -f remote-control/bin/activate_new remote-control/bin/activate
source remote-control/bin/activate # activate custom python environment
python3 -m pip install --upgrade pip
pip install git+https://github.com/HEnquist/pycamilladsp.git@v2.0.2


### Create and install remote-control.tcz

mkdir -p /tmp/remote-control/usr/local/tce.installed/

cd /tmp/remote-control

echo "#!/bin/sh
sudo -u tc sh -c '
while [ ! -f /usr/local/bin/python3 ]; do sleep 1; done
source /usr/local/remote-control/bin/activate
while [ ! -f /home/tc/remote-control.py ]; do sleep 1; done
python3 -u /home/tc/remote-control.py > /tmp/remote-control.log 2>&1 &
' &" > usr/local/tce.installed/remote-control
chmod 775 usr/local/tce.installed/remote-control

sudo mv /usr/local/remote-control usr/local/

cd /tmp
install_temporarily_if_missing squashfs-tools
mksquashfs remote-control remote-control.tcz
mv -f remote-control.tcz /etc/sysconfig/tcedir/optional
echo "python3.11.tcz
python3.11-evdev.tcz" > /etc/sysconfig/tcedir/optional/remote-control.tcz.dep
echo remote-control.tcz >> /etc/sysconfig/tcedir/onboot.lst

pcp backup
pcp reboot