# Fast and robust check for DPC or nDPC
if /bin/grep --silent -P "anvil_release.*ro," /proc/mounts; then
    export DPC=1
else
    export DPC=0
fi

# This is a "helper" that is causing a hang when command not found. Disable it.
# Leaving it here as a reminder though. PackageKit is USELESS.
# unset -f command_not_found_handle
