#!/bin/sh -e

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

print_heading() {
  echo
  echo "=== ${1} ==="
}

create_virtual_environment() {
  print_heading "Creating virtual environment"

  install_temporarily_if_missing git
  install_if_missing python3.11
  install_if_missing python3.11-evdev

  echo "Setting up virtual environment"
  cd /usr/local/
  python3 -m venv remote-control
  sed -i 's|include-system-site-packages = false|include-system-site-packages = true|g' remote-control/pyvenv.cfg # include system packages in the environment
  (tr -d '\r' < remote-control/bin/activate) > remote-control/bin/activate_new # Create fixed version of the activate script. See https://stackoverflow.com/a/44446239
  mv -f remote-control/bin/activate_new remote-control/bin/activate
  source remote-control/bin/activate # activate custom python environment

  python3 -m pip install --upgrade pip
  pip install git+https://github.com/HEnquist/pycamilladsp.git@v2.0.2

  mkdir -p /tmp/remote-control/usr/local/
  sudo mv /usr/local/remote-control /tmp/remote-control/usr/local/
}

create_startup_script() {
  print_heading "Creating startup script"
  mkdir -p /tmp/remote-control/usr/local/tce.installed/
  cd /tmp/remote-control/usr/local/tce.installed/
  echo "#!/bin/sh
  sudo -u tc sh -c '
  while [ ! -f /usr/local/bin/python3 ]; do sleep 1; done
  source /usr/local/remote-control/bin/activate
  while [ ! -f /home/tc/remote-control.py ]; do sleep 1; done
  python3 -u /home/tc/remote-control.py > /tmp/remote-control.log 2>&1 &
  ' &" > remote-control
  chmod 775 remote-control
}

create_tiny_core_extension() {
  print_heading "Creating tiny core extension"
  cd /tmp
  install_temporarily_if_missing squashfs-tools
  mksquashfs remote-control remote-control.tcz
  mv -f remote-control.tcz /etc/sysconfig/tcedir/optional
  echo "python3.11.tcz
  python3.11-evdev.tcz" > /etc/sysconfig/tcedir/optional/remote-control.tcz.dep
  echo remote-control.tcz >> /etc/sysconfig/tcedir/onboot.lst
}

backup_and_reboot() {
  print_heading "Backup and reboot"
  pcp backup
  pcp reboot
}

create_virtual_environment
create_startup_script
create_tiny_core_extension
backup_and_reboot