# piCore python-environment

## Running your own python scripts

1. Edit the variables at the start of `setup-python-environment.sh` to fit your needs. ([example](https://github.com/JWahle/piCoreCDSP/compare/main...remote-control))
2. Copy `setup-python-environment.sh` from your local machine to pCP and run it:  
   `scp setup-python-environment.sh tc@pcp.local:~ && ssh tc@pcp.local "./scp setup-python-environment.sh"`
3. Copy your scripts from your local machine to pCP: `scp <your_script> tc@pcp.local:~`
4. Optional: If you want to run additional scripts on boot, you can add them in `Tweaks > User Commands` by setting one of the commands to this:  
   `sudo -u tc sh -c 'source /usr/local/camillagui/environment/bin/activate; python3 /home/tc/<your_script>'`
5. Save and reboot

If you need to access files in your script, make sure to use absolute paths.