# Build and install bash completions
* Make sure autoconf is installed (sudo apt install autoconf)
* Use the `build_scop_bash_completions` script
* There will be hardcoded absolute paths, clean them up manually for now, automate later

# GRC hacks
## grc/bin/grc
conffilenames = [home + '/.config/bash/global/grc/etc/grc.conf']
## grc/bin/grcat
conffilepath += [home + '/.config/bash/global/grc/share/grc/']

