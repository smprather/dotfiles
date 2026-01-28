# There's more, read comments farther up.
# Switch to latest version of bash.
# If on an EL7 machine, this bash test fails. Just keep using the system bash version.
# The EL7 VM image does not have the TMOUT bug.
#_foss_tools_home="....../tools/foss/interactive"
#if $_foss_tools_home/bash/5.3.0/bin/bash -c exit >&/dev/null ; then
#    if [[ -z $REBOOT_FOR_INTERACTIVE_SHELL ]]; then
#        exec /usr/bin/env \
#            REBOOT_FOR_INTERACTIVE_SHELL=1 \
#            $_foss_tools_home/bash/5.3.0/bin/bash --noprofile --rcfile ~/.bashrc
#    fi
#    unset REBOOT_FOR_INTERACTIVE_SHELL
#fi
