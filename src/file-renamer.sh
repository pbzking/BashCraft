#!/bin/bash

input_color="\033[0;36m"
placeholder_color="\033[0;33m"

success_status_color="\033[0;32m"
failure_status_color="\033[0;31m"

dir=""

function get_directory()
{
    gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 40 --height 1 --margin "1 1" --padding "1 2" \
    'Directory'
    printf "${input_color}Directory you want to rename: ${placeholder_color}"
    read dir

    if ! [ -d $dir ]; then
        printf "${failure_status_color}Invalid Directory\n"
        return 1
    else
        return 0
    fi
    
}

function get_pattern_type()
{
     gum style \
      --foreground 212 --border-foreground 212 --border double \
      --align center --width 40 --height 1 --margin "1 1" --padding "1 2" \
      'Pattern Type'
      pattern_type=()
      temp=$(gum choose "prefix" "suffix" "replace" "numbering" --no-limit | xargs)
      count=$(echo -n $temp | tr -cd ' ' | wc -c)
      count=$(( count + 1 ))
      
      for (( i=1; i<=count; i++ )); do
        pattern_type[i]=$(echo -n $temp | awk -v var="$i" '{ print $(var) }')
      done
}

function confirm_hidden_renaiming()
{
    if gum confirm  "Do you want to rename hidden files"; then
        hidden_files=1
    else
        hidden_files=0
    fi
    
}

if get_directory; then
    get_pattern_type
    confirm_hidden_renaiming

    if [ $hidden_files -eq 1 ]; then
        list_command="ls -la"
    else
        list_command="ls -l"
    fi
        
else
    exit 1
fi
