# piCorePlayer python-environment
The goal of this project is to help you to easily set up your custom Python environment including
piCorePlayer/Tiny Core Linux extensions, pip dependencies and autostart your scripts on boot.


## Setup
1. Edit the variables at the start of `setup-python-environment.sh` to fit your needs. ([Example: setting up a remote control with FLIRC](https://github.com/JWahle/piCorePython/compare/main...remote-control))
2. Copy `setup-python-environment.sh` from your local machine to pCP and run it:  
   `scp setup-python-environment.sh tc@pcp.local:~ && ssh tc@pcp.local "./scp setup-python-environment.sh"`
3. Copy your scripts from your local machine to pCP: `scp <your_script> tc@pcp.local:~`
4. Optional: If you want to run additional scripts on boot, you can add them in `Tweaks > User Commands` by setting one of the commands to this:  
   `sudo -u tc sh -c 'source /usr/local/python-environment/environment/bin/activate; python3 -u /home/tc/<your_script> > /tmp/<your_logfile> 2>&1'`
5. Save and reboot

If you need to access files in your script, make sure to use absolute paths.