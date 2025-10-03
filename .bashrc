### Non-interactive and interactive
# This section of the script is for non-interactive shell, so "keep it clean"
# Start with a clean slate: basic path, clear all aliases and functions and modules (below)
#set -x
# Capture all set -x to a log file for really hard to catch stuff
#exec 2> ~/bashrc.log

export PATH="/bin:/usr/bin:/usr/sbin"
unalias -a
unset -f $(declare -F | /bin/awk '{print $3}')

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
get_script_dir()
{
    local source_path="${BASH_SOURCE[0]}"
    local symlink_dir
    local script_dir
    while [[ -L "$source_path" ]]; do
        symlink_dir="$(cd -P "$(/usr/bin/dirname "$source_path" )" >/dev/null 2>&1 && pwd)"
        source_path="$(/usr/bin/readlink "$source_path")"
        if [[ $source_path != /* ]]; then
            source_path="$symlink_dir/$source_path"
        fi
    done
    script_dir="$(cd -P "$(/usr/bin/dirname "$source_path")" >/dev/null 2>&1 && pwd)"
    echo "$script_dir"
}
bashrc_root=$(get_script_dir)
bashrc_user=$(/bin/whoami)
export USER=$bashrc_user

# I use this dir for high-speed access to small/temporary files
/bin/mkdir -p /dev/shm/$bashrc_user

# Fast and robust check for DPC or nDPC
if /bin/grep --silent -P "anvil_release.*ro," /proc/mounts; then
    export DPC=1
else
    export DPC=0
fi

######## HOOK TOP ########
[[ -r ~/.bashrc_hook.top ]] && source ~/.bashrc_hook.top
##########################

# These are copies of the system-level shell startup scripts with:
#   * Fix the TMOUT env-var bug
#   * Prevent using /usr/share/Modules. We have our own modules.
#   * Prevent scl-init which has a bug due to missing modulepath file
#   * Prevent the incredibly annoying PackageKit from loading
#     (There was also a bad bug, but I can't recall what it was)
if shopt -q login_shell; then
    # Login shell
    source $bashrc_root/etc/profile
else
    # Not a login shell
    source $bashrc_root/etc/bashrc
fi

# Make xterm-256color the default terminal.
# Some trouble w/ RH7 not respecting the ~/.terminfo dir. Need to debug later.
export TERM="xterm-256color"

# Further environment management employs the Environment Modules utility,
# which must be initialized.  We use a modern Environment Modules version,
# which we expect to find in our common grid area.  Note that we don't use
# /usr/share/Modules because its content and behavior varies on different
# systems.  Note also that its possible /usr/share/Modules or some other
# Environment Modules installation might already be in service on entry.
# If so, we do our best to remove it from the environment before loading
# our preferred version.
if type 'module' > /dev/null 2>&1; then
    # Environment Modules is already running
    module purge >& /dev/null # valid command in all EM versions
    module reset --force >& /dev/null # aggressive reset in newer EM versions
    for modulevar in $(/bin/printenv | /bin/egrep '^MODULE|^__MODULE|LOADEDMODULES|_LMFILES_' | /bin/cut -f1 -d=); do
        unset $modulevar
    done
fi
export MODULESHOME="..../modules/v5.4.0"
source "$MODULESHOME/init/bash"
module reset --force >& /dev/null
export MODULEPATH="..../modules"

###################################### HOOK: MODULES ###############################################
[[ -r ~/.bashrc_hook.module_setup ]] && source ~/.bashrc_hook.modules
####################################################################################################

# Exit here is not interactive
if [[ $- != *i* ]]; then
    # Unset all local variables. I use the bashrc_ leader to mark these.
    unset ${!bashrc_@}
    return
fi

####################################################################################################
###################################     Interactive    #############################################
####################################################################################################
# Fix the IT VM-setup TMOUT bug (/etc/profile.d/tmout.sh).
# There's more, read comments farther up.
# Switch to latest version of bash.
# If on an EL7 machine, this bash test fails. Just keep using the system bash version.
# The EL7 VM image does not have the TMOUT bug.
bashrc_foss_tools_home="....../tools/foss/interactive"
if $bashrc_foss_tools_home/bash/5.3.0/bin/bash -c exit >&/dev/null ; then
    if [[ -z $REBOOT_FOR_INTERACTIVE_SHELL ]]; then
        exec /usr/bin/env \
            --unset=TMOUT \
            REBOOT_FOR_INTERACTIVE_SHELL=1 \
            $bashrc_foss_tools_home/bash/5.3.0/bin/bash --noprofile --rcfile "$bashrc_root/.bashrc"
    fi
    unset REBOOT_FOR_INTERACTIVE_SHELL
fi

source "$bashrc_root/bash_script_helpers.sh"

export WHITE="\e[38;2;255;255;255m"
export GREEN="\e[38;2;0;255;0m"
export RED="\e[38;2;255;0;0m"
export VIOLET="\e[38;2;255;0;255m"
export YELLOW="\e[38;2;255;255;0m"
export CYAN="\e[38;2;0;255;255m"
export BOLD="\e[1m"
export NORMAL="\e[22m"
# Use the \[ and \] to let bash-prompt know these are zero-width on-screen
export PROMPT_WHITE="\\[$WHITE\\]"
export PROMPT_GREEN="\\[${GREEN}\\]"
export PROMPT_RED="\\[$RED\\]"
export PROMPT_VIOLET="\\[$VIOLET\\]"
export PROMPT_YELLOW="\\[$YELLOW\\]"
export PROMPT_CYAN="\\[$CYAN\\]"
export PROMPT_BOLD="\\[$BOLD\\]"
export PROMPT_NORMAL="\\[$NORMAL\\]"

# Detect a valid X desktop
xterm -e "exit" 2>/dev/null
if [[ $? -eq 0 ]]; then
    # Make .local/share/fonts visible to the X server
    xset +fp ~/.local/share/fonts
fi

# Detect GLIBC version. I can't support everything on RH7, but I want a
# minimal level of usability since we still occasionally find ourselves on
# incredibly old RH7 VMs (sjdpc-remotenx for example).
bashrc_glibc=$(/bin/ldd --version | /bin/grep -Po "\d\.\d+")

# https://junegunn.github.io/fzf/shell-integration/
# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="--walker-skip .git,.snapshot --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# https://github.com/junegunn/fzf?tab=readme-ov-file#key-bindings-for-command-line
eval "$(fzf --bash)"

# This is a "helper" that is causing a hang on DPC when command not found. Disable it.
# I fixed it in my /etc/bashrc|bash_profile hacks, so I don't need this unset anymore.
# Leaving it here as a reminder though. PackageKit is USELESS for us. (Google it)
# unset -f command_not_found_handle

# Default settings
# There are two nice ls replacements: eza and lsd. User can choose. (Need to add pls)
bashrc_settings_preferred_ls="eza"
# If a tmux session exists, auto-attach to it (but only for ssh, not GUI terminals)
bashrc_settings_auto_attach_tmux=1
# Include the host name in the prompt. include_host=yes, no_include_host=no
bashrc_settings_prompt_include_host=0
#bashrc_settings_terminal_program="WindowsTerminal"
export EZA_ARGS="--classify=always --color=always --icons=always --long --sort date --time modified --time-style relative"
export LSD_ARGS="--sort time --long --reverse --date '+%D %H:%M:%S'"
bashrc_settings_prompt_color_normal=$PROMPT_GREEN
bashrc_settings_prompt_color_farm=$PROMPT_RED
bashrc_settings_enable_tmux_dir_db=1
bashrc_settings_use_fastnvim=0
#################################### HOOK: SETTINGS ################################################
source_if_exists $HOME/.bashrc_hook.settings
####################################################################################################

# Commented on 8/13/25, remove later if still ok
#export NVIM_RELEASE=$bashrc_settings_nvim_release

# Tmux will not detect UTF-8 support unless you set LANG/LC_ALL like this
# When broken, all non-ASCII glyphs will show up as _ chars.
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Farm maching won't allow me to create a directory in /run/user.
# Unsolved mystery. Just make it in /dev/shm instead.
if [[ ! -r $XDG_RUNTIME_DIR ]]; then
    export XDG_RUNTIME_DIR=/dev/shm/$(id -u)
    mkdir -p "$XDG_RUNTIME_DIR"
fi

# Separating this from env-modules init because I only want completions in interactive
source $$MODULESHOME/v5.4.0/init/bash_completion

# bash checks the window size after each command and, if necessary, updates the values of LINES and COLUMNS.
shopt -s checkwinsize

# Don't escape vars when tab-complete. Expand instead.
shopt -s direxpand

# Don't save to history if command line starts with a space char
# Erasedups causes all previous lines matching the current line to be removed from the history list before that line is saved.
export HISTCONTROL=ignorespace:erasedups
shopt -s histappend
# Save history accross shell re-boots (ie, exec bash)
export HISTFILE="$XDG_RUNTIME_DIR/bash_history.$$"
export HISTSIZE=10000
export HISTFILESIZE=10000
# If a history file with the PID already exists, that means an exec bash just happened.
if [[ ! -r "$HISTFILE" ]]; then
    # If not, then do this...
    if /bin/ps -f $PPID | /bin/grep -q bash; then
        # If this is a child bash, then inherit the history from the parent.
        [[ -r $XDG_RUNTIME_DIR/bash_history.$PPID ]] && cp $XDG_RUNTIME_DIR/bash_history.$PPID $HISTFILE
    else
        # Else, start the shell history with the contents of the most recently modified history.
        if /bin/ls $XDG_RUNTIME_DIR/bash_history.* >&/dev/null; then
            cp $(/bin/ls -rt1 $XDG_RUNTIME_DIR/bash_history.* | tail -n 1) $HISTFILE
        fi
    fi
fi

# Compile python bytecode cache to fast /dev/shm filesystem
export PYTHONPYCACHEPREFIX=/dev/shm/$bashrc_user/pycache

# Should work for all cases, but this terminfo stuff is always trying to fail.
# When working correctly, you should see undercurl, italics, etc working in nvim.
export COLORTERM=truecolor
# This is a bad test for RH7 machines. There are better solutions, but in a rush.
if (( $(/bin/echo "$bashrc_glibc > 2.17" | bc -l) )); then
    export TERM="tmux-256color"
fi

# When using Python Poetry, it tries to access the desktop keyring
# which for some reason causes a hang. This var disables keyring.
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring

# Adds color to a lot of basic linux cmds
export GRC_ALIASES="true"
source $bashrc_root/grc.sh

# Create tmux_dir_db aliases. Run 'tdd' to see a list of aliases.
if is_truthy $bashrc_settings_enable_tmux_dir_db; then
    eval $(tmux_dir_db --bash)
fi

### START PATH SETUP ###

# If NOT in an activated python virtual env
if [[ -z ${VIRTUAL_ENV+x} ]]; then
    # This is required by bash in an empty if
    :

    # I manage everything with shims/ now, so this is hollowed out.
    ### START MODULES ###
    #module load foss/python_venv
    ### END MODULES ###

    # I want to re-order $HOME/.local/bin, so remove it first
    # path_remove PATH $HOME/.local/bin
    # [[ -d "$HOME/.local/bin" ]] && path_prepend PATH $HOME/.local/bin
fi

# Clean up any dupes that may have crept in
path_trim PATH

### END PATH SETUP ###

set_prompt() {
    local include_host="$1"
    local prompt_color=$bashrc_settings_prompt_color_normal
    local prompt_joined=""
    local prompt_parts=()

    # Assumption is that userid is in the VM name
    if [[ -n $LSB_JOBID ]]; then
        prompt_parts+=('LSF')
        prompt_color=$bashrc_settings_prompt_color_farm
    fi

    prompt_joined=$(join_by : "${prompt_parts[@]}")

    [[ $include_host == "1" ]] && prompt_joined+=":$(hostname)"

    get_prompt_uid() {
        local whoiam=$(/bin/whoami)
        if [[ "$whoiam" != "$USER" || "$whoiam" == "anviladm" ]]; then
            printf "$whoiam "
        else
            printf ""
        fi
    }

    # history -a: Always flush the latest command to the history file
    PROMPT_COMMAND="printf '$BOLD$CYAN'"'; history -a; echo $(realpath .); '"printf '$NORMAL'"

    PS1="${PROMPT_YELLOW}\$(get_prompt_uid)${prompt_color}\$ ${PROMPT_WHITE}"
}
set_prompt $bashrc_settings_prompt_include_host

# Disable ctrl-s terminal pausing
stty -ixon

if is_truthy $bashrc_settings_use_fastnvim; then
    vim_exec="fastnvim"
else
    vim_exec="nvim"
fi

export PAGER='less --incsearch --use-color --no-init --ignore-case --mouse'
export BAT_PAGER="$PAGER -RF"
export EDITOR=$vim_exec
export VISUAL=$EDITOR
export GIT_EDITOR=$EDITOR
export MANPAGER="sh -c '/bin/sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -l man'"

# Disable check for too many completions, and paging the results.
# This is so that I can use a 2nd TAB to cycle through the possible results.
bind 'set completion-query-items 0'
bind 'set page-completions off'

### Readline configuration
# Prevent pasted text from being highlighted in reverse text
bind 'set enable-bracketed-paste off'
# If there are multiple matches for completion, Tab should cycle through them
bind 'TAB:menu-complete'
# Display a list of the matching files
bind "set show-all-if-ambiguous on"
# Perform partial (common) completion on the first Tab press, only start
# cycling full results on the second Tab press (from bash version 5)
bind "set menu-complete-display-prefix on"
# Make dot-files not tab-complete visible. I was getting .snapshot hits.
bind 'set match-hidden-files off'
### Cycle through history based on characters already typed on the line
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'
bind "set colored-completion-prefix on"
# cycle completions forward/backward
bind '\C-j:menu-complete'
bind '\C-k:menu-complete-backward'

### Completions
# https://github.com/scop/bash-completion
source $bashrc_root/github.scop.bash-completion/bash_completion
for bashrc_comp_file in $(/bin/ls -1 $bashrc_root/completions/*.bash $HOME/.bash_completions/*.bash 2> /dev/null); do
    source $bashrc_comp_file
done
for bashrc_cmd in uv ruff; do
    command -v $bashrc_cmd >/dev/null && eval "$($bashrc_cmd generate-shell-completion bash)"
done

if [[ $DPC == "1" ]]; then
    # interactive tfo-dpc-int fast-int
    export BS_INTERACTIVE_QUEUE="tfo-dpc-int"
    # batch tfo-dpc-bat fast-bat
    export BS_BATCH_QUEUE="tfo-dpc-bat"
else
    # interactive tfo-ndpc-int
    export BS_INTERACTIVE_QUEUE="interactive"
    # lnx64 tfo-ndpc-bat
    export BS_BATCH_QUEUE="lnx64"
fi

# Using eval so that the value of the de-symlinking realpath call is baked into the definition instead of
# calling it every time, and so that OS doesn't have to deal w/ symlink for every ls. And so it doesn't have
# to test for preferred ls tool everytime.
if (( $(/bin/echo "$bashrc_glibc > 2.17" | bc -l) )); then
    if [[ $bashrc_settings_preferred_ls == "lsd" ]]; then
        eval "
        ls_func() {
            if [[ \$1 == '-1' ]]; then
                /bin/ls \$*
                return
            fi
            local option_size=\$([[ \$ls_func_human_readable == 1 ]] && echo -n short || echo -n bytes)
            # Careful, the ^[ in the sd search string is acually [ESC] ie typed with <ctrl-v>ESC
            $(/bin/realpath $bashrc_foss_tools_home/rust/cargo/bin/lsd) --size \$option_size \$LSD_ARGS --date '+%D %H:%M:%S' \$LSD_ARGS \$*
        }"
    elif [[ $bashrc_settings_preferred_ls == "eza" ]]; then
        rsync $(/bin/realpath $(/bin/which eza)) /dev/shm/$bashrc_user
        eval "
        ls_func() {
            if [[ \$1 == '-1' ]]; then
                /bin/ls -1 \$*
                return
            fi
            local option_a=\$([[ \$ls_func_list_all == 1 ]] && echo -n -a || echo -n '')
            local option_B=\$([[ \$ls_func_human_readable == 1 ]] && echo -n '' || echo -n -B)
            local option_g=\$([[ \$ls_func_show_group == 1 ]] && echo -n '-g' || echo -n '')
            /dev/shm/$bashrc_user/eza --time-style '+%D %H:%M:%S' \$option_a \$option_B \$option_g \$EZA_ARGS \$*
        }"
    fi
    /bin/rsync $bashrc_foss_tools_home/eza/latest/bin/eza /dev/shm/$bashrc_user
else
    eval "
    ls_func() {
        local option_a=\$([[ \$ls_func_list_all == 1 ]] && echo -n '-a' || echo -n '')
        local option_h=\$([[ \$ls_func_human_readable == 1 ]] && echo -n '' || echo -n '--human-readable')
        local option_g=\$([[ \$ls_func_show_group == 1 ]] && echo -n '' || echo -n '--no-group')
        /bin/ls --color -lrt $option_g $option_h $option_a \$*
    }"
fi

cd_func() {
    if [[ "$1" == "cd" ]]; then
        shift
    fi

    local target="$1"
    if [[ -d "$1" ]]; then
        target=$1
    elif [[ "$1" == "" ]]; then
        target=$HOME
    elif [[ "$1" == "-" ]]; then
        target="-"
    elif [[ -L "$1" || -e "$1" ]]; then
        target=${1%/*}
    elif [[ ! -d $target && -w $(/bin/dirname $target) ]]; then
        read -p "$target does not exist. Do you want to create it? [y]/n " response
        if [[ -z "$response" || $response == "y" ]]; then
            /bin/mkdir $target
        else
            return
        fi
    fi

    builtin cd "$target" && ls_func_human_readable=0 ls_func
    # z "$target" && ls_func_human_readable=0 ls_func
}
extract_rpm() {
    rpm2cpio "$1" | cpio -idmv
}
ga() {
    if [[ -z "$1" ]]; then
        git add --all .
    else
        git add $*
    fi
    git status
}
zhead() {
    zcat "${@: -1}" | head $(array_slice 0:-1 ${@})
}

# Executing a directory will cd to that directory. Makes it so that you can
# paste a directory to the cmd line w/o a cd first.
trap 'last_cmd=$BASH_COMMAND; [[ -r $last_cmd && -d $last_cmd ]] && cd $last_cmd || ( [[ -r $last_cmd && ! -x $last_cmd ]] && cd $(/bin/dirname $last_cmd) )' ERR

bashrc_xterm_cmd="xterm -bg black -fg white -fa HackNerdFontMono-Regular -fs 10 +sb"

alias ls='ls_func'
alias sl='ls'
alias ll='ls_func'
alias lr='ls_func'
alias rl='ls_func'
alias lh='ls_func_human_readable=1 ls_func'
alias la='ls_func_list_all=1 ls_func'
alias lg='ls_func_show_group=1 ls_func'
alias lah='ls_func_human_readable=1 ls_func_list_all=1 ls_func'
alias lha='lah'
alias lsg='lg'
function cds {
  eval "$(cd-surfer "$@")"
}
alias cd-='cd -'
alias cd=cd_func
alias b='cd_func ..'
alias bb='cd_func ../..'
alias bbb='cd_func ../../..'
alias bbbb='cd_func ../../../..'
alias bbbbb='cd_func ../../../../..'
alias bbbbbb='cd_func ../../../../../..'
alias bbbbbbb='cd_func ../../../../../../..'
alias bbbbbbbb='cd_func ../../../../../../../..'
alias bbbbbbbbb='cd_func ../../../../../../../../..'
alias bbbbbbbbbb='cd_func ../../../../../../../../../..'
alias cdd='cd_func $(find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 1)'
alias cddd='cd_func `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 2 | head -n 1`'
alias cdddd='cd_func `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 3 | head -n 1`'
alias cddddd='cd_func `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 4 | head -n 1`'
alias cdddddd='cd_func `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 5 | head -n 1`'
alias p='pwd | tee /tmp/p_dir'
alias ho='hostname -s'
alias d='date'
alias vi=$vim_exec
alias vim=$vim_exec
alias vic="$vim_exec --clean -u ~/.vimrc"
alias vii="$vim_exec \$(find * -maxdepth 0 -type f | xargs /bin/ls -drt1 | tail -n 1)"
alias vimdiff="NVIM_WRAPPER_OPTS='-d -R' $vim_exec"
alias vid="$vim_exec -d"
alias ovi='\vim'
alias fls="ls \$(fzf)"
alias fvi="$vim_exec \$(fzf)"
alias fcd="eval \$(__fzf_cd__) && ls_func"
alias fcat="cat \$(fzf)"
alias t='exec bash'
alias hg='history | rg'
alias lr='ls'
alias la='lr -a'
alias f='fd --unrestricted --full-path'
fc() {
    fd --unrestricted --full-path $1 | wc -l
}
alias w='type -a'
alias du='du --block-size=G -s * | sort -r -n -k 1'
alias dum='/bin/du --block-size=M -s * | sort -r -n -k 1'
alias df='colourify df --block-size=G'
alias tl='tmux list-sessions'
alias ta='resize; tmux attach -d || tmux'
alias c='clear'
alias h='history | g'
alias rm='rm -f'
alias rs='rsync --archive --info=progress2 --info=name0 --no-inc-recursive --exclude="*/.snapshot/"'
alias pl='echo $PATH | tr ":" "\n" | nl'
alias ncdu='ncdu --color dark'
new() {
    touch $1
    chmod +x $1
    vi $1
}
g() {
    rg --smart-case --search-zip --hidden --no-ignore --glob='!*.snapshot*' "$@"
}
alias sg='rg --smart-case --search-zip --hidden --no-ignore --glob="!*.snapshot*" --max-filesize=100K'
alias gv='g -v'
alias tx='tar -xvf'
alias tt='tar -tvf'
alias ncdu='ncdu --graph-style hash --color dark'
alias mdkir='mkdir'
alias itcl="\$HOME/.local/lib/tcl/tclsh-wrapper/TclReadLine/TclReadLine.tcl"
alias ipy='ipython3'
alias x='chmod +x'
alias clean_bash='echo "/usr/bin/env --ignore-environment PATH=/bin HOME=$HOME USER=$(/bin/whoami) /bin/bash --rcfile ~/.clean.bashrc"'
alias tree='ls -T'
alias cat='bat --paging=never'
alias catp='bat'
alias invs='innovus -stylus'
alias vlts='voltus -stylus'
alias a="alias | sort > /tmp/alias.$$; declare -f >> /tmp/alias.$$; vi /tmp/alias.$$; rm /tmp/alias.$$"
alias gpw='chmod -R g+w'
alias gmw='chmod -R g-w'
bashrc_tmux_get_window_cmd='TMUX_WINDOW=$(tmux display-message -p "#W")'
alias btopu='btop -u $(/bin/whoami)'
alias rlrt="find \$1 -type f -print0 | xargs -0 stat --format '%Y :%y %n' | sort -nr | cut -d: -f2- | head"
# There's a fxn above for ga (git add)
alias xterm=$bashrc_xterm_cmd
alias gc='git commit'
alias gs='git status'
alias gp='git push'
alias gd='git d'
alias gr='git review'
alias pg='pgrep -u $(/bin/whoami) --full --list-full'
alias pk='pkill'
alias wget='wget -O-'
alias pyprofile='python3 -m cProfile -s cumtime'
alias my_total_cpu="while true; do top -b -n 1 -u \$(/bin/whoami) | awk 'NR>7 { sum += \$9; } END { print sum; }'; sleep 1; done"
alias sp1="set_prompt"
alias sp2="set_prompt include_host"
alias agrep="alias | g"
alias fdon="echo 'export FLEXLM_DIAGNOSTICS=3'; export FLEXLM_DIAGNOSTICS=3"
alias fdoff="echo 'unset FLEXLM_DIAGNOSTICS'; unset FLEXLM_DIAGNOSTICS"
alias wip='vim $HOME/wip.txt'
alias cdp='cd $(cat /tmp/p_dir)'
alias mkdir='mkdir -p'
alias fsbm='fio --randrepeat=1 --ioengine=libaio --direct=0 --gtod_reduce=1 --name=test --bs=4k --iodepth=64 --readwrite=randrw --rwmixread=75 --size=4G --filename=./fio_test; rm ./fio_test'
alias we='watchexec --clear --poll 500'
bq() {
    [[ $1 == "-l" ]] && bqueues -l $* || bqueues -u $(/bin/whoami) -o 'queue_name: status: njobs: pend: run:'
}
#alias bq="bqueues -u $bashrc_user -o 'queue_name: status: njobs: pend: run:'"
alias bqs="bq"
alias sbqueues='echo "QUEUE_NAME      PRIO STATUS          MAX JL/U JL/P JL/H NJOBS  PEND   RUN  SUSP  RSV PJOBS "; bqueues | grep hw_ | egrep "interactive|reg_batch|reg_user|cot|batch|biggermem|spot|reg_ci"'
alias sbq='sbqueues'
alias pgrep='pgrep -f'
alias pkill='pkill -f'
alias bkillall='bkill -u $(/bin/whoami) 0'
alias gf='g -F'
alias gpy='g --glob "*.py" --glob="!*.snapshot*"'
alias gtcl='g --glob "*.tcl" --glob="!*.snapshot*"'
alias mli='module list'
alias ms='module show'
alias ma='module avail'
# This makes grep run way faster. Though you should be using rg instead!
alias grep='LC_ALL=C grep'
latest() {
    local latest
    rm -f latest
    if [[ -n $1 ]]; then
        mkdir -p $1
        ln -s $1 latest
        latest=$1
    else
        latest=$(/bin/ls -1drt */ | tail -n 1)
        ln -s $latest latest
    fi
    cd $latest
}
ln_s_func() {
    # Assume deletion of any existing sym-link
    if [[ -n $2 ]]; then
        if /bin/readlink $2 > /dev/null; then
            /bin/rm -f $2
        fi
    else
        local b=$(basename $1)
        if /bin/readlink $b > /dev/null; then
            /bin/rm -f $b
        fi
    fi

    /bin/ln -s "$@"
}
alias lns='ln_s_func'
alias test_nvim='NVIM_APPNAME=test_nvim nvim_wrapper'
alias gsp='git stash; git pull; git stash pop'
alias gunzip='unpigz'
alias gzip='pigz'
alias gz='pigz'
rp() { [[ -n "$1" ]] && realpath $1 || realpath . ; }
alias less='less --incsearch --use-color +X'
alias bjobsv='export LSB_BJOBS_FORMAT="jobid:7 stat:5 user:12 queue:15 slots:3 proj_name:15 sla:15 exec_host:13 max_mem:12 pend_time:12 max_req_proc:12 mem"'
alias v="nvim -n -R -"
# Without args, start a VNC server. With args, be an alias for vncserver.
vnc() {
    if [[ -z $1 ]]; then
        vncserver -SecurityTypes None
    else
        vncserver "$@"
    fi
}
alias startvnc="vncserver -SecurityTypes None"
alias stopvnc="vncserver -kill"
alias killvnc="vncserver -kill"
alias st="strace -o /tmp/strace.$USER -f -v -s 1000000"
alias vman="MANPAGER='nvim +Man\!' man"
# "Grep All (bash) History"
gah() {
    # g will use the alias for rg
    g $* /run/user/*/bash_history.* 2>/dev/null
}

# https://github.com/ajeetdsouza/zoxide
#eval "$(zoxide init bash)"

# There is a rare-to-never used LSF tool-let called 'btop' that conflicts with
# https://github.com/aristocratos/btop
# Overriding here
alias btop="$ANVIL_HOME/tools/foss/interactive/btop/latest/bin/btop"

if (( $(/bin/echo "$bashrc_glibc < 2.18" | bc -l) )); then
    export PATH="$ANVIL_HOME/tools/foss/pkgs/nvim/latest/bin:$PATH"
    #unalias f vi vim vimdiff vid vidiff 2>/dev/null
    unalias f 2>/dev/null
    unset -f f
    function f() {
        if [ "$#" -ne 1 ]; then
            rg_args='.'
        else
            rg_args="$@"
        fi
        /bin/find . | rg --smart-case "$rg_args"
    }
    #alias vi="vim"
    alias vidiff="vimdiff"
    unalias cat
    alias bat="/bin/cat"
fi

source_if_exists $HOME/.bashrc_hook.bottom

# Auto-attach is misfiring too often. Turn it off until I have a better way to make it
# work only when wanted.
# Auto-attach to tmux if session exists, but only if using ssh to connect. $TERM_PROGRAM
# is set by tmux. Don't auto-attach when creating new GUI terminals.
bashrc_is_ssh_connection=$(/bin/ps -f $PPID | /bin/grep -c sshd)
if false && \
    is_truthy $bashrc_settings_auto_attach_tmux && \
    is_truthy $bashrc_is_ssh_connection && \
    [[ "$TERM_PROGRAM" != "tmux" ]] && \
    [[ $(/bin/hostname -f) != "sj-ajm-01" ]]; then

    # Unset all local variables. I use the bashrc_ leader to mark these.
    # Can't do it before this if-cmd since vars are used in the conditional.
    # So have to do it here, and in the else clause.
    unset ${!bashrc_@}

    # Make sure terminal is in a known-good state
    reset
    if tmux has-session 2>/dev/null; then
        # Attach this bash, -d -> detach all others
        tmux attach -d
    else
        # Create a new tmux session
        tmux
    fi
else
    unset ${!bashrc_@}
fi

# vim: ft=bash
