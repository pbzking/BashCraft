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

function prefix_filename()
{
    if [[ $1 == .* ]]; then
        f_name="${1#*.}"
        file_name=".$2$f_name"

    else
        file_name="$2$1"
    fi

    echo $file_name
}

function suffix_filename()
{
    if [[ "$1" == *.* ]]; then
        f_ext="${1##*.}"
        f_name="${1%.*}"
        file_name="$f_name$2.$f_ext"
    else
        f_name=$1
        file_name=$f_name$2
    fi

    echo $file_name
}

function find_and_replace_filename()
{
    
    if [[ $1 == .* ]]; then
        hidden=1
        basename="${1#*.}"
        if [[ $basename == *.* ]]; then
            is_file=1
            f_ext="${basename##*.}"
            basename="${basename%.*}"
        else
            is_file=0
            basename="$basename"
        fi
    else
        hidden=0
        basename=$1
        if [[ $basename == *.* ]]; then
            is_file=1
            f_ext="${basename##*.}"
            basename="${basename%.*}"
        else
            is_file=0
            basename=$1
        fi
    fi

    if [[ "$basename" == *"$2"* ]]; then
        basename=$(echo "$basename" | sed "s/$2/$3/g")
    fi

    if [ $hidden -eq 1 ]; then
        if [ $is_file -eq 1 ]; then
            file_name=".$basename.$f_ext"
        else
            file_name=".$basename"
        fi
    else
        if [ $is_file -eq 1 ]; then
            file_name="$basename.$f_ext"
        else
            file_name="$basename"
        fi
    fi

    echo $file_name
}

function numbered_filenaming()
{
    if [ $4 -eq 1 ]; then
        file_name="$2"
    else
        file_name=$(prefix_filename $1 $2)
    fi

    file_name=$(suffix_filename $file_name $3)

    echo $file_name


}



if get_directory; then
    
    get_pattern_type
    confirm_hidden_renaiming

    if [ $hidden_files -eq 1 ]; then
        list_command="ls -la $dir"
    else
        list_command="ls -l $dir"
    fi

    dir_contents_count=$($list_command | wc -l)
    
    contents=()
    new_name=()
    
    index=0

    #avoiding ., .. path
    for (( i=4; i<=dir_contents_count; i++ )); do
        temp=$($list_command | sed -n ${i}p)
        contents[index]=$(echo $temp | awk '{for(j=9;j<=NF;j++) printf "%s ", $j; print ""}' )
        contents[index]=$(echo ${contents[index]} | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        new_name[index]="${contents[index]}"
        (( index += 1 ))
    done
    
    array_size=${#contents[@]}
    random_number=$(( RANDOM % array_size ))

    tmp_filename=${new_name[random_number]}
    for (( i=0; i<${#pattern_type[@]}; i++ ));do
        # Removing leading and trailing spaces
        pattern_type[i]=$(echo "${pattern_type[i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        case ${pattern_type[i]} in
            "prefix")
                printf "${input_color}Enter the prefix to add to the filenames: ${placeholder_color}"
                read prefix
                tmp_filename=$(prefix_filename "$tmp_filename" "$prefix")
                gum style --padding "1 5" --margin "1 1" --border double --border-foreground 255 "eg: '$tmp_filename'"
                ;;
            "suffix")
                printf "${input_color}Enter the suffix to add to the filenames: ${placeholder_color}"
                read suffix
                
                tmp_filename=$(suffix_filename "$tmp_filename" "$suffix")
                 gum style --padding "1 5" --margin "1 1" --border double --border-foreground 255 "eg: '$tmp_filename'"
                ;;
            "replace")
                printf "${input_color}Enter the text to find and replace in filenames: ${placeholder_color}"
                read remove_text
                printf "${input_color}Enter the text to replace ${remove_text} with: ${placeholder_color}"
                read replacement_text
    
                tmp_filename=$(find_and_replace_filename "$tmp_filename" "$remove_text" "$replacement_text")
                gum style --padding "1 5" --margin "1 1" --border double --border-foreground 255 "eg: '$tmp_filename'"
                ;;
            "numbering")
                printf "${input_color}Enter the prefix for numbering: ${placeholder_color}"
                read prefix_numbering
                printf "${input_color}Enter the starting number: ${placeholder_color}"
                read starting_number
                echo ""
                if gum confirm "Do you want to overwrite current file name" ; then
                    overwrite=1
                else
                    overwrite=0
                fi
                tmp_starting_number=$(printf "%03d\n" "$starting_number")
                tmp_filename=$(numbered_filenaming "$tmp_filename" "$prefix_numbering" "$tmp_starting_number" $overwrite)
                gum style --padding "1 5" --margin "1 1" --border double --border-foreground 255 "eg: '$tmp_filename'"
                ;;
        esac
    done

    for (( i=0; i<${#pattern_type[@]}; i++ )); do
        case ${pattern_type[i]} in
            "prefix")
                for (( j=0; j<${#contents[@]}; j++ )); do
                    new_name[j]=$(prefix_filename "${new_name[j]}" "$prefix" )
                    
                done
                ;;
            "suffix")
                for (( j=0; j<${#contents[@]}; j++ )); do
                    new_name[j]=$(suffix_filename "${new_name[j]}" "$suffix")
                    
                done
                ;;  
            "replace")
                for (( j=0; j<${#contents[@]}; j++ )); do
                    new_name[j]=$(find_and_replace_filename "${new_name[j]}" "$remove_text" "$replacement_text")
                    
                done  
                ;;
            "numbering")
                for (( j=0; j<${#contents[@]}; j++ )); do
                    file_number=$(printf "%03d\n" "$starting_number"])
                    new_name[j]=$(numbered_filenaming "${new_name[j]}" "$prefix_numbering" "$file_number" $overwrite)
                    (( starting_number+=1 ))
    
                done
                ;;
            esac
    done

    for (( i=0; i<${#new_name[@]}; i++ )); do
         gum log --structured --level info "Renaming" From "${contents[i]}" To "${new_name[i]}"
    done
    echo ""
    if gum confirm "Do you want to confirm the changes"; then

        is_root_gained=0

        for (( i=0; i<${#new_name[@]};i++ )); do
            file_path=$(realpath "$dir/${contents[i]}" )
            dst_path="$dir/${new_name[i]}"
            is_root_access=$(ls -ld "$file_path" | awk '{ print $3 } 2>/dev/null')
            
            if [ "$is_root_access" == "root" ]; then
                gum log --structured --level warn "Root Access file found" src "${contents[i]}"
                    sudo mv "$file_path" "$dst_path" &>/dev/null
            else
                mv "$file_path" "$dst_path"  &>/dev/null
            fi
            gum log --structured --level warn "Renaming" From "${contents[i]}" To "${new_name[i]}"
        done
    fi 
else
    exit 1
fi
