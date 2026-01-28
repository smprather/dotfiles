####################################################################################################
###################################       Debug        #############################################
####################################################################################################
set +x
# Try this first. Can catch most stuff.
#PS4='+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}: '
#set -x

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
_source_path="${BASH_SOURCE[0]}"
while [[ -L "$_source_path" ]]; do
    _symlink_dir="$(cd -P "$(dirname "$_source_path" )" >/dev/null 2>&1 && pwd)"
    _source_path="$(readlink "$_source_path")"
    if [[ $_source_path != /* ]]; then
        _source_path="$_symlink_dir/$_source_path"
    fi
done
_this_script_dir="$(cd -P "$(dirname "$_source_path" )" >/dev/null 2>&1 && pwd)"

source "$BASH_CONFIG_ROOT_DIR/global/functions.sh"

layered_preference_source "global_hooks/1.sh"

export WHITE="\e[38;2;255;255;255m"
export GREEN="\e[38;2;0;255;0m"
export RED="\e[38;2;255;0;0m"
export BLUE="\e[38;2;135;215;255m"
export VIOLET="\e[38;2;255;0;255m"
export YELLOW="\e[38;2;255;255;0m"
export CYAN="\e[38;2;0;255;255m"
export BOLD="\e[1m"
export NORMAL="\e[22m"
# Use the \[ and \] to let bash-prompt know these are zero-width on-screen
export PROMPT_WHITE="\\[$WHITE\\]"
export PROMPT_GREEN="\\[${GREEN}\\]"
export PROMPT_RED="\\[$RED\\]"
export PROMPT_BLUE="\\[$BLUE\\]"
export PROMPT_VIOLET="\\[$VIOLET\\]"
export PROMPT_YELLOW="\\[$YELLOW\\]"
export PROMPT_CYAN="\\[$CYAN\\]"
export PROMPT_BOLD="\\[$BOLD\\]"
export PROMPT_NORMAL="\\[$NORMAL\\]"

# Detect a valid X desktop
if xwininfo -root >& /dev/null && [[ -d ~/.local/share/fonts ]]; then
    # Make .local/share/fonts visible to the X server
    xset +fp ~/.local/share/fonts
fi

# Detect GLIBC version. I can't support everything on RH7, but I want a minimal level of usability
# since we still occasionally find ourselves on incredibly old RH7 machines.
_glibc=$(/usr/bin/ldd --version | /bin/grep -Po "\d\.\d+" | /bin/head -n 1)

layered_preference_source "global_hooks/2.sh"

# Tmux will not detect UTF-8 support unless you set LANG/LC_ALL like this
# When broken, all non-ASCII glyphs will show up as _ chars.
#export LC_ALL=en_US.UTF-8
#export LANG=en_US.UTF-8

if [[ ! -r $XDG_RUNTIME_DIR ]]; then
    export XDG_RUNTIME_DIR=/dev/shm/$(id -u)
    mkdir -p "$XDG_RUNTIME_DIR"
fi

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
if [[ ! -f "$HISTFILE" ]]; then
    # If not, then do this...
    if ps -f $PPID | grep -q bash; then
        # If this is a child bash, then inherit the history from the parent.
        [[ -f $XDG_RUNTIME_DIR/bash_history.$PPID ]] && cp $XDG_RUNTIME_DIR/bash_history.$PPID $HISTFILE
    else
        # Else, start the shell history with the contents of the most recently modified history.
        if ls $XDG_RUNTIME_DIR/bash_history.* >&/dev/null; then
            cp $(/bin/ls -rt1 $XDG_RUNTIME_DIR/bash_history.* | tail -n 1) $HISTFILE
        fi
    fi
fi

# Compile python bytecode cache to fast /dev/shm filesystem
export PYTHONPYCACHEPREFIX=/dev/shm/$USER/pycache

# When using Python Poetry, it tries to access the desktop keyring which for some reason causes a hang
# This var disables keyring
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring

# Should work for all cases, but this terminfo stuff is always trying to fail.
# When working correctly, you should see undercurl, italics, etc working in nvim.
export COLORTERM=truecolor
# This is a bad test for RH7 machines. There are better solutions, but in a rush.
#if (( $(/bin/echo "$_glibc > 2.17" | bc -l) )); then
#    export TERM="tmux-256color"
#fi

# Adds color to a lot of basic linux cmds
if is_truthy $cfg_enable_grc ; then
    path_prepend PATH "$BASH_CONFIG_ROOT_DIR/global/grc/bin"
    export GRC_ALIASES="true"
    source $BASH_CONFIG_ROOT_DIR/global/grc/etc/profile.d/grc.sh
fi

# Create tmux_path_store aliases. Run 'tdd' to see a list of aliases.
if is_truthy $cfg_enable_tmux_path_store ; then
    eval $(tmux_path_store --bash)
fi

### START PATH SETUP ###
for potential_bin_dir in \
    /usr/local \
    ~/.cargo \
    ~/.venv \
    ~/.local; do
    [[ -r $potential_bin_dir/bin ]] && export PATH="$potential_bin_dir/bin:$PATH"
done

# If NOT in an activated python virtual env
if [[ -z ${VIRTUAL_ENV+x} ]]; then
    # This is required by bash in an empty if
    :

    # I want to re-order $HOME/.local/bin, so remove it first
    # path_remove PATH $HOME/.local/bin
    # [[ -d "$HOME/.local/bin" ]] && path_prepend PATH $HOME/.local/bin
fi

layered_preference_source "global_hooks/3.sh"

# Clean up any dupes that may have crept in
path_trim PATH
### END PATH SETUP ###

export PAGER='less --incsearch --use-color --no-init --ignore-case --mouse'
export EDITOR="$cfg_preferred_vi"
export VISUAL=$EDITOR
export GIT_EDITOR=$EDITOR

if command -v batcat >&/dev/null; then
    _bat_exec="batcat"
elif command -v bat >&/dev/null; then
    _bat_exec="bat"
fi
if [[ -n $_bat_exec ]]; then
    alias bat="$_bat_exec"
    export BAT_PAGER="$PAGER -RF"
fi

if command -v fzf >&/dev/null && is_truthy $cfg_enable_fzf ; then
    if [[ -n $_bat_exec ]]; then
        # https://junegunn.github.io/fzf/shell-integration/
        # Preview file content using bat (https://github.com/sharkdp/bat)
        export FZF_CTRL_T_OPTS="--walker-skip .git,.snapshot --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
    else
        export FZF_CTRL_T_OPTS="--walker-skip .git,.snapshot --preview 'cat {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
    fi
    # https://github.com/junegunn/fzf?tab=readme-ov-file#key-bindings-for-command-line
    eval "$(fzf --bash)"
fi

set_prompt() {
    local include_host="$1"
    local prompt_color="$cfg_prompt_color_normal"
    local prompt_joined=""
    local prompt_parts=()

    if [[ -n $LSB_JOBID ]]; then
        prompt_parts+=('LSF')
        prompt_color="$cfg_prompt_color_farm"
    fi

    prompt_joined=$(join_by : "${prompt_parts[@]}")

    [[ $include_host == "1" ]] && prompt_joined+=":$(hostname)"

    get_prompt_uid() {
        local whoiam=$(/bin/whoami)
        if [[ "$whoiam" != "$USER" ]]; then
            printf "$whoiam "
        else
            printf ""
        fi
    }

    # history -a: Always flush the latest command to the history file
    PROMPT_COMMAND="printf '$BOLD$BLUE'"'; history -a; echo $(realpath .); '"printf '$NORMAL'"
    PROMPT_COMMAND="printf '$BOLD$CYAN'"'; history -a; echo $(realpath .); '"printf '$NORMAL'"

    PS1="${PROMPT_YELLOW}\$(get_prompt_uid)${prompt_color}\$ ${PROMPT_WHITE}"
}
layered_preference_source "global_hooks/4.sh"
set_prompt "$cfg_prompt_include_host"

# Disable ctrl-s terminal pausing
stty -ixon

#export MANPAGER="/bin/sh -c '/bin/sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | $cfg_preferred_cat -p -l man'"
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'
export MANPAGER="/usr/bin/less"
export MANROFFOPT="-c"

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

layered_preference_source "global_hooks/5.sh"

### Completions
# Clean the slate
complete -r
source $BASH_CONFIG_ROOT_DIR/global/github.scop.bash-completion/share/bash-completion/bash_completion
for _layer in global corp site team user; do
    for _comp_file in $BASH_CONFIG_ROOT_DIR/$_layer/completions/*.bash; do
        # Must check for exist since no-glob-match in bash resolves to the whole glob string with the * in it
        source_if_exists $_comp_file
    done
done
for _cmd in uv ruff; do
    command -v $_cmd >/dev/null && eval "$($_cmd generate-shell-completion bash)"
done

layered_preference_source "global_hooks/6.sh"

# Using eval:
#   * The de-symlinking realpath call is baked into the function definition instead of calling it every time
#   * Doesn't have to test for preferred ls tool everytime
if fpcmp $_glibc -gt 2.17; then
    export EZA_ARGS="--classify=always --color=always --icons=always --long --sort date --time modified --time-style relative"
    export LSD_ARGS="--sort time --long --reverse --date '+%D %H:%M:%S'"
    if [[ $cfg_preferred_ls == "lsd" ]]; then
        eval "
        ls() {
            if [[ \$1 == '-1' ]]; then
                command ls \$*
                return
            fi
            local option_size=\$([[ \$human_readable == 1 ]] && echo -n short || echo -n bytes)
            # Careful, the ^[ in the sd search string is acually [ESC] ie typed with <ctrl-v>ESC
            $(realpath $(which lsd)) --size \$option_size \$LSD_ARGS --date '+%D %H:%M:%S' \$LSD_ARGS \$*
        }"
    elif [[ $cfg_preferred_ls == "eza" ]]; then
        if [[ ! -f /dev/shm/$USER/bin/eza ]]; then
            mkdir -p /dev/shm/$USER/bin
            cp $(realpath $(which eza)) /dev/shm/$USER/bin
        fi
        eval "
        ls() {
            if [[ \$1 == '-1' ]]; then
                /bin/ls -1 \$*
                return
            fi
            local option_a=\$([[ \$list_all == 1 ]] && echo -n -a || echo -n '')
            local option_B=\$([[ \$human_readable == 1 ]] && echo -n '' || echo -n -B)
            local option_g=\$([[ \$show_group == 1 ]] && echo -n '-g' || echo -n '')
            /dev/shm/$USER/bin/eza --time-style '+%D %H:%M:%S' \$option_a \$option_B \$option_g \$EZA_ARGS \$*
        }"
        rsync $(which eza) /dev/shm/$USER/bin
    elif [[ $cfg_preferred_ls == "ls" ]]; then
        eval "
        ls() {
            local option_a=\$([[ \$list_all == 1 ]] && echo -n '-a' || echo -n '')
            local option_h=\$([[ \$human_readable == 1 ]] && echo -n '' || echo -n '--human-readable')
            local option_g=\$([[ \$show_group == 1 ]] && echo -n '' || echo -n '--no-group')
            /bin/ls --color -lrt $option_g $option_h $option_a \$*
        }"
    fi
fi

cd() {
    if [[ "$1" == "cd" ]]; then
        shift
    fi

    local target="$1"
    local response=""

    if [[ -d "$1" ]]; then
        target=$1
    elif [[ "$1" == "" ]]; then
        target=$HOME
    elif [[ "$1" == "-" ]]; then
        target="-"
    elif [[ -L "$1" || -e "$1" ]]; then
        target=${1%/*}
    elif [[ ! -d $target && -w $(dirname $target) ]]; then
        read -p "$target does not exist. Do you want to create it? [y]/n " response
        if [[ -z "$response" || $response == "y" ]]; then
            mkdir $target
        else
            return
        fi
    fi

    builtin cd "$target" && human_readable=0 ls
    # z "$target" && human_readable=0 ls
}
alias bcd="builtin cd"

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

_xterm_cmd="xterm -bg black -fg white -fa HackNerdFontMono-Regular -fs 10 +sb"

alias sl='ls'
alias ll='ls'
alias lr='ls'
alias rl='ls'
alias lh='human_readable=1 ls'
alias la='ls_func_list_all=1 ls_func'
alias lg='ls_func_show_group=1 ls_func'
alias lah='ls_func_human_readable=1 ls_func_list_all=1 ls_func'
alias lha='lah'
alias lsg='lg'
cds() {
    eval "$(cd-surfer "$@")"
}
alias cd-='cd -'
alias b='cd ..'
alias bb='cd ../..'
alias bbb='cd ../../..'
alias bbbb='cd ../../../..'
alias bbbbb='cd ../../../../..'
alias bbbbbb='cd ../../../../../..'
alias bbbbbbb='cd ../../../../../../..'
alias bbbbbbbb='cd ../../../../../../../..'
alias bbbbbbbbb='cd ../../../../../../../../..'
alias bbbbbbbbbb='cd ../../../../../../../../../..'
alias cdd='cd $(find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 1)'
alias cddd='cd `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 2 | head -n 1`'
alias cdddd='cd `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 3 | head -n 1`'
alias cddddd='cd `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 4 | head -n 1`'
alias cdddddd='cd `find * -maxdepth 0 -type d | xargs /bin/ls -drt1 | tail -n 5 | head -n 1`'
alias p='pwd | tee /tmp/p_dir'
alias ho='hostname -s'
alias d='date'
alias vi="$cfg_preferred_vi"
alias vim="$cfg_preferred_vi"
alias vic="$cfg_preferred_vi --clean -u ~/.vimrc"
alias vii="$cfg_preferred_vi \$(find * -maxdepth 0 -type f | xargs /bin/ls -drt1 | tail -n 1)"
alias vimdiff="NVIM_WRAPPER_OPTS='-d -R' $vim_exec"
alias vid="$cfg_preferred_vi -d"
alias ovi='\vim'
alias fls="ls \$(fzf)"
alias fvi="$vim_exec \$(fzf)"
alias fcd="eval \$(__fzf_cd__) && ls"
alias fcat="cat \$(fzf)"
alias t='exec bash'
alias hg='history | /bin/grep -i'
alias lr='ls'
alias la='lr -a'
if command -v fdfind >/dev/null; then
    alias fd="fdfind"
    alias f='fd --unrestricted --full-path'
else
    alias f='find .'
fi
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
if command -v rg >&/dev/null; then
    g() {
        rg --smart-case --search-zip --hidden --no-ignore --glob='!*.snapshot*' "$@"
    }
    alias sg='rg --smart-case --search-zip --hidden --no-ignore --glob="!*.snapshot*" --max-filesize=100K'
    alias gv='g -v'
else
    g() {
        grep --smart-case --search-zip --hidden --no-ignore --glob='!*.snapshot*' "$@"
    }
    alias sg='rg --smart-case --search-zip --hidden --no-ignore --glob="!*.snapshot*" --max-filesize=100K'
    alias gv='g -v'
fi
alias tx='tar -xvf'
alias tt='tar -tvf'
alias ncdu='ncdu --graph-style hash --color dark'
alias mdkir='mkdir'
alias itcl="\$HOME/.local/lib/tcl/tclsh-wrapper/TclReadLine/TclReadLine.tcl"
alias ipy='ipython3'
alias x='chmod +x'
alias clean_bash='echo "/usr/bin/env --ignore-environment PATH=/bin HOME=$HOME USER=$(/bin/whoami) /bin/bash --rcfile ~/.clean.bashrc"'
alias tree='ls -T'
if [[ -n $_bat_exec ]]; then
    alias cat='bat --paging=never'
    alias catp='bat'
fi
alias invs='innovus -stylus'
alias vlts='voltus -stylus'
alias a="alias | sort > /tmp/alias.$$; declare -f >> /tmp/alias.$$; vi /tmp/alias.$$; rm /tmp/alias.$$"
alias gpw='chmod -R g+w'
alias gmw='chmod -R g-w'
_tmux_get_window_cmd='TMUX_WINDOW=$(tmux display-message -p "#W")'
alias btopu='btop -u $(/bin/whoami)'
alias rlrt="find \$1 -type f -print0 | xargs -0 stat --format '%Y :%y %n' | sort -nr | cut -d: -f2- | head"
# There's a fxn above for ga (git add)
alias xterm=$_xterm_cmd
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
    [[ $1 == "-l" ]] && bqueues -l $* || bqueues -u $(whoami) -o 'queue_name: status: njobs: pend: run:'
}
#alias bq="bqueues -u $_user -o 'queue_name: status: njobs: pend: run:'"
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
        latest=$(command ls -1drt */ | tail -n 1)
        ln -s $latest latest
    fi
    cd $latest
}
lns() {
    # Assume deletion of any existing sym-link
    if [[ -n $2 ]]; then
        if /bin/readlink $2 > /dev/null; then
            rm -f $2
        fi
    else
        local b=$(basename $1)
        if readlink $b > /dev/null; then
            rm -f $b
        fi
    fi

    ln -s "$@"
}
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
    rg $* /run/user/*/bash_history.* 2>/dev/null
}

# https://github.com/ajeetdsouza/zoxide
#eval "$(zoxide init bash)"

layered_preference_source "hooks/7.sh"

# Auto-attach is misfiring too often. Turn it off until I have a better way to make it
# work only when wanted.
# Auto-attach to tmux if session exists, but only if using ssh to connect. $TERM_PROGRAM
# is set by tmux. Don't auto-attach when creating new GUI terminals.
_is_ssh_connection=$(ps -f $PPID | grep -c sshd)
if false && \
    is_truthy $_is_ssh_connection && \
    [[ "$TERM_PROGRAM" != "tmux" ]] \
    ; then

    cfg_attach_tmux=1
fi

# vim: ft=bash ts=4
