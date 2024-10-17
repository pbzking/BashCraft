#!/bin/bash

#Defining asci color value
placeholder="\e[96m"
input="\e[93m"
success="\033[0;32m"
failure="\033[0;31m"
reset="\033[0m"

dir=""
hidden_included=0

prefix_=0
suffix_=0
find_and_replace_=0
numbered_=0

function expand_user()
{   
    dir="$HOME/${dir:1}"
}

function get_directory()
{
    printf "${placeholder}Enter directory path: ${input}"
    read dir

    if [ "${dir:0:1}" = '~' ]; then
        expand_user
    fi

    dir=$(realpath "$dir" 2>/dev/null)

    if [ -d "$dir" ]; then
        return 0
    else
        printf "${failure}Directory does not exist.\n${reset}"
        return 1
    fi
}

function confirmation()
{
    if gum confirm "$1"; then
        echo 1
    else
        echo 0
    fi
}

function read_directory()
{
    contents_count=$($list_command $1 | wc -l)
    (( contents_count -= unwanted_ls_output ))

    contents=()
    index=0
    
    if [ $contents_count -eq 0 ]; then
        printf "${failure}The specified directory is empty,\nPlease select a directory that contains files or folders\n"
        exit 0
    fi

    for (( i=unwanted_ls_output+1; i<contents_count+unwanted_ls_output; i++ ));
    {
       temp=$($list_command $dir | sed -n "${i}p" )
       contents[index]=$(echo $temp | awk '{for(j=9;j<=NF;j++) printf "%s ", $j; print "" }')
       (( index+=1 ))
    }
}

function prefix_file_name()
{
    file_name=$1
    prefix=$2

    if [[ ${file_name:0:1} == "." ]]; then

        f_name="${file_name#.}"
        file_name=".$prefix$f_name"
    else
        file_name="$prefix$file_name"
    fi

    echo $file_name
}

function suffix_file_name()
{
    file_name=$1
    suffix=$2

    if [[ ${file_name:0:1} == "." ]]; then
        file_name=$"{file_name#.}"

        if [[ $file_name == *.* ]]; then
            basename="${file_name%.*}"
            extension="${file_name##*.}"
            file_name=".$basename$suffix.$extension"
        else
            file_name=".$file_name$suffix"
        fi
    else
        if [[ $file_name == *.* ]]; then
            basename="${file_name%.*}"
            extension="${file_name##*.}"
            file_name="$basename$suffix.$extension"
        else
            file_name="$file_name$suffix"
        fi    
    fi

    echo $file_name
}

function find_and_replace()
{
    file_name=$1
    remove_text=$2
    replacement_text=$3

    if [[ $file_name == *$remove_text* ]]; then
        file_name=$(echo $file_name | sed "s/${remove_text}/${replacement_text}/g")
    fi

    echo $file_name
}

function numbering_renaming()
{   
    file_name=$1
    
    modified_number=$(printf "00%d" $starting_number)
    file_name=$(suffix_file_name $file_name $modified_number) 
    
    echo $file_name
}

function alphebatical_renaming()
{
    file_name=$1
    
    current_alpha_character=$(printf "\\$(printf '%03o' $starting_alpha)")
    file_name=$(suffix_file_name $file_name  $current_alpha_character)

    echo $file_name
}

function prefix_submenu()
{
    while true; do
      choice=$(dialog --menu "Prefix renaming" 15 35 4 \
      1 "Enter the prefix: $prefix" \
      2 "Submit" \
      3 "Return to the main menu" 3>&1 1>&2 2>&3)
          
      exit_status=$?

      if [ $exit_status -eq 0 ]; then
            case $choice in
                1 ) prefix=$(dialog --inputbox "Enter the prefix to add to the filename: " 10 60 3>&1 1>&2 2>&3) ;;
                2 ) tmp_file_name=$(prefix_file_name $tmp_file_name $prefix) 
                    prefix_=1;;
                3 ) break ;;
            esac
      else
        break
      fi
    done
}

function suffix_submenu()
{
    while true; do
      choice=$(dialog --menu "Suffix renaming" 15 35 4 \
      1 "Enter the suffix: $suffix" \
      2 "Submit" \
      3 "Return to the main menu" 3>&1 1>&2 2>&3)

      exit_status=$?

      if [ $exit_status -eq 0 ]; then
            case $choice in
                1 ) suffix=$(dialog --inputbox "Enter the suffix to add to the filename: " 10 60 3>&1 1>&2 2>&3) ;;
                2 ) tmp_file_name=$(suffix_file_name $tmp_file_name $suffix)
                    suffix_=1 ;;
                3 ) break ;;
            esac
      else
        break
      fi
    done
}

function find_and_replace_submenu()
{
    while true; do
      choice=$(dialog --menu "Find and replace in filename:" 15 50 4 \
      1 "Enter the removing text" \
      2 "Enter the replacing text" \
      3 "Submit" \
      4 "Return to the main menu" 3>&1 1>&2 2>&3)

      exit_status=$?

      if [ $exit_status -eq 0 ]; then
            case $choice in
                1 ) remove_text=$(dialog --inputbox "Enter the text to find in the filename: " 10 60 3>&1 1>&2 2>&3) ;;
                2 ) replacement_text=$(dialog --inputbox "Enter the text to replace $remove_text with: " 10 60 3>&1 1>&2 2>&3) ;;
                3 ) if [[ -n "$remove_text" && -n "$replacement_text" ]]; then
                        tmp_file_name=$(find_and_replace $tmp_file_name $remove_text $replacement_text)
                        find_replace_=1
                    fi
                    ;;
                4 ) break ;;
            esac
      else
        break
      fi
    done
}

function numbering_submenu()
{
    while true; do
      choice=$(dialog --menu "Numbering based file naming:" 15 50 4 \
      1 "Enter the starting number" \
      2 "Submit" \
      3 "Return to the main menu" 3>&1 1>&2 2>&3)

      exit_status=$?

      if [ $exit_status -eq 0 ]; then
            case $choice in
                1 ) starting_number=$(dialog --inputbox "Enter the starting number: " 10 60 3>&1 1>&2 2>&3) ;;
                2 ) tmp_file_name=$(numbering_renaming $tmp_file_name)
                    numberrd_=1 ;;
                3 ) break ;;
            esac
      else
        break
      fi
    done
}

function print_main_menu()
{
    while true; do
      subchoice=$(dialog --menu "Renaming options" 15 50 4 \
      1 "Prefix" \
      2 "Suffix" \
      3 "Find and Replace" \
      4 "Numbering" \
      eg: "$tmp_file_name" 3>&1 1>&2 2>&3)
      
      
      exit_code=$?
      if [ $exit_code -eq 0 ]; then
        case $subchoice in
        1) prefix_submenu ;;
        2) suffix_submenu ;;
        3) find_and_replace_submenu ;;
        4) numbering_submenu ;;
        eg:) dialog --msgbox "Example: ${tmp_file_name}" 5 60
        esac
      else
          break
      fi
    done
}

if ! get_directory; then
    exit 1
fi

hidden_included=$(confirmation "Do you want to include hidden files for renaming?")

if [ $hidden_included -eq 1 ]; then
    list_command="ls -la"
    unwanted_ls_output=3
elif  [ $hidden_included -eq 0 ]; then
    list_command="ls -l"
    unwanted_ls_output=1
fi

read_directory $dir

content_size=${#contents[@]}
(( random_number = RANDOM % content_size ))

tmp_file_name=${contents[random_number]}

print_main_menu 

echo ""

src_file=()
dst_file=()

changes=0
root_required=0

for (( i=0; i<content_size; i++ )); 
{
    src_file[i]=${contents[i]}
    
    new_file_name=${contents[i]}

    if [ $prefix_ -eq 1 ]; then
        new_file_name=$(prefix_file_name $new_file_name $prefix)
    fi

    if [ $suffix_ -eq 1 ]; then
        new_file_name=$(suffix_file_name $new_file_name $suffix)
    fi

    if [ $find_and_replace_ -eq 1 ]; then
        new_file_name=$(find_and_replace $new_file_name $remove_text $replacement_text)
    fi

    if [ $numbered_ -eq 1 ]; then
        new_file_name=$(numbering_renaming $new_file_name $starting_number)
        (( starting_number += 1 ))
    fi

    dst_file[i]=$new_file_name

    src_full_path[i]="$dir/${src_file[i]}"
    dst_full_path[i]="$dir/${dst_file[i]}"

    file_access_user=$(ls -l $src_full_path | awk '{ print $3} ')
 
    if [ $file_access_user == "root" ]; then
        root_required=1
    fi

    if [ ${dst_file[i]} != ${src_file[i]} ];then
        (( changes+=1 ))
        gum log --structured  --level info "Renaming file" from ${src_file[i]} to ${dst_file[i]}
    fi
}

if [ $changes -gt 0 ]; then
    confirm=$(confirmation "Are you sure to continue")
else
    exit 0
fi

if [ $confirm -eq 1 ]; then

    if [ $root_required -eq 1 ]; then
        #Getting sudo priveligies without a unimpactfull program
        sudo echo -n ""
    fi

    for (( i=0; i<content_size; i++ ));
    {
        gum log --structured --level info "Renamed" src ${src_file[i]} dst ${dst_file[i]} 
        sudo mv ${src_full_path[i]} ${dst_full_path[i]} 2>/dev/null
    }
else
    exit 0
fi

