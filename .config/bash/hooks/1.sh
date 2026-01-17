# Fast and robust check for DPC or nDPC
if /bin/grep --silent -P "anvil_release.*ro," /proc/mounts; then
    export DPC=1
else
    export DPC=0
fi
