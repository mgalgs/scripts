#!/bin/sh
#note: this file is meant to be source'd, not executed directly

mdie()
{
    echo "Error: $1"
    echo "exiting..."
    exit
}

mdie_sending()
{
    notify-send "Error: $1"
    exit
}

mdie_zen()
{
    zenity --error --title="Error" --text="$1"
    exit
}

minfo_zen()
{
    zenity --info --text="$1"
}

#convert to upper case
toupper()
{
    local char="$*"
    out=$(echo $char | tr [:lower:] [:upper:])
    local retval=$?
    echo "$out"
    unset out char
    return $retval
}

#convert to lower case
tolower()
{
    local char="$*"
    out=$(echo $char | tr [:upper:] [:lower:])
    local retval=$?
    echo "$out"
    unset out
    unset char
    return $retval
}


#returns 1 if they the user gives some permutation of 'yes', else 0
respondYes()
{
    read response
    echo $(isYes $response)
}

#returns 1 if they the user gives some permutation of 'no', else 0
respondNo()
{
    read response
    echo $(isNo $response)
}

isYes()
{
    case `tolower $1` in
        'y'*)
            echo 1
            return 1
            ;;
    esac
    echo 0
    return 0
}

isNo()
{
    case `tolower $1` in
        'n'*)
            echo 1
            return 1
            ;;
    esac
    echo 0
    return 0
}


### Below here is for PROMPT_COMMAND and PS1 fun ###
# example usage:
# source ~/school/and_such_as/dot_rands/dot_ansicolor
# MYPS1FRONT="$C_BROWN(\w)\n$C_LIGHT_RED\u$C_BLUE@$C_LIGHT_RED\H$C_GREEN[$C_RED"
# MYPS1BACK="$C_GREEN]$C_LIGHT_RED\$ $C_RESET"
# source ~/school/and_such_as/scripts/util.sh
# PROMPT_COMMAND=myps1messages


appendMessage()
{
    #if $MESS has non-zero length:
    if [ -n "$MESS" ]
        then
            MESS="${MESS},$1"
        else
            MESS="$1"
    fi
}

# set these to yes to activate svn or git status in PS1
USE_SVN_IN_PS1=no
USE_GIT_IN_PS1=yes
USE_RUBY_IN_PS1=no
USE_COMMAND_HISTORY_IN_PS1=no
USE_UPTIME_IN_PS1=yes

myps1messages()
{
    MESS=""
    # append the command history
    [[ $(isYes $USE_COMMAND_HISTORY_IN_PS1) == "1" ]] && appendMessage "!\!"
    # append the load average over the past 1 minute
    [[ $(isYes $USE_UPTIME_IN_PS1) == "1" ]] && appendMessage `uptime | sed 's/\(.*load\ average:\ \)//g' | sed 's/,.*$//g'`
    # append ruby stuff from rvm
    [[ $(isYes $USE_RUBY_IN_PS1) == "1" ]] && appendMessage "$(rvm-prompt)"

    # svn status
    [[ $(isYes $USE_SVN_IN_PS1) == "1" ]] && { [ `svn status -N 2>/dev/null | awk 'BEGIN {i=0} {i++} END {print i}'` -gt 0 ] && appendMessage "svn changes"; }

    # git status
    [[ $(isYes $USE_GIT_IN_PS1) == "1" ]] && { git_stuff=$(__git_ps1 "(%s)"); [ `echo $git_stuff | wc -c` -gt 2 ] && appendMessage $git_stuff; }

    PS1="${MYPS1FRONT}${MESS}${MYPS1BACK}"
}

hostisup()
{
    ping -W 1 -c 1 $1 2>&1 > /dev/null
    retval=$?
    if [[ $retval = 0 ]]; then
        ret="yes"
    else
        ret="no"
    fi
    echo $ret
    return $retval
}

bold_print()
{
    echo -e "\033[1m$1\033[0m $2"
}

in_array()
{
    local hay needle=$1
    shift
    for hay; do
        [[ $hay == $needle ]] && return 0
    done
    return 1
}
