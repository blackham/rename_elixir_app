#!/bin/bash

is_mix_project() {
  grep MixProject mix.exs &> /dev/null
  if [[ $? -eq 0 ]]; then
    true
  else
    false
  fi
}

get_current_project_snake_name () {
  # Get the app/project name from the mix.exs file
  # sed -n 's/app: :\(.*\),/\1/p' mix.exs  

  # This gets the project name from the basename of the current directory
  echo "${PWD##*/}"
}

get_current_project_pascal_name () {
  sed -n 's/defmodule \(.*\)\.MixProject do/\1/p' mix.exs
}

pascal_to_snake_case() {
  local pascal_case="$1"
  local snake_case

  snake_case=$(echo "${pascal_case}" | sed 's/\([a-z]\)\([A-Z]\)/\1_\L\2/g; s/\([A-Z]\)\([A-Z]\)/\1_\L\2/g; s/^\([A-Z]\)/\L\1/')

  echo "$snake_case"
}

snake_case_to_pascal() {
  local snake_case="$1"
  local pascal_case

  pascal_case=$(echo "${snake_case}" | sed -e 's/_\([a-z]\)/\u\1/g' -e 's/^./\u&/')


  echo "$pascal_case"
}

is_snake_case() {
  if echo "$1" | grep -q '[[:upper:]]' && ! echo "$1" | grep -q '_'; then
    return 1  # snake_case
  else
    return 0  # not snake_case
  fi
}

rename_directories() {
  local old_project_snake_name="$1"
  local new_project_snake_name="$2"
  find . -depth -type d -name "*${old_project_snake_name}*" -exec bash -c 'dir="$1" && newdir="${dir//'"${old_project_snake_name}"'/'"${new_project_snake_name}"'}" && [ "$dir" != "$newdir" ] && mv "$dir" "$newdir"' _ {} \;                                                                                                                                                            
}

# Function to rename files
rename_files() {
  local file_ext="$1"
  local old_project_snake_name="$2"
  local new_project_snake_name="$3"
  find . -type f \( -name "*.${file_ext}" \) -exec bash -c 'file="$1" && newfile="${file//'"${old_project_snake_name}"'/'"${new_project_snake_name}"'}" && [ "$file" != "$newfile" ] && mv "$file" "$newfile"' _ {} \;
}

# Function to update contents inside files
update_file_contents() {
  local file_ext="$1"
  local old_project_snake_name="$2"
  local new_project_snake_name="$3"
  local old_project_pascal_name="$4"
  local new_project_pascal_name="$5"
  find . -type f \( -name "*.${file_ext}" \) -exec sed -i -e "s/${old_project_pascal_name}/${new_project_pascal_name}/g" -e "s/${old_project_snake_name}/${new_project_snake_name}/g" {} +
}

# Ensure the new project name was given
if [ -z "$1" ]; then
  echo "Please provide the name of the new project in Pascal case. example:"
  echo ""
  echo " ${0} ProjectName [project_name]"
  echo ""
  exit 10
fi

# Ensure we are in a mix.exs directory
if ! is_mix_project; then
  echo "Can't find MixProject in a mix.exs file. Please run this script in the root of the project"
  exit 20
fi

if is_snake_case "${1}"; then
  pascal_name=$(snake_case_to_pascal "${1}")
  snake_name=$(pascal_to_snake_case "${1}")
  echo "The new project ${1} appeares to be in snake_case. Please rename it to PascalCase. example:"
  echo ""
  echo " ${0} ProjectName [project_name]"
  echo " ${0} ${pascal_name}" 
  echo " ${0} ${pascal_name} ${snake_name}"
  echo ""
  exit 30
fi

new_project_pascal_name=${1}
if [ -n "$2" ]; then
  new_project_snake_name="$2"
else
  new_project_snake_name=$(pascal_to_snake_case "${new_project_pascal_name}")
fi
old_project_snake_name="$(get_current_project_snake_name)"
old_project_pascal_name="$(get_current_project_pascal_name)"
file_types=("ex" "exs" "eex" "md") # Only modify these file types 

read -p "Rename ${old_project_pascal_name} (${old_project_snake_name}) to ${new_project_pascal_name} (${new_project_snake_name}). (Y/N) " yn 

case $yn in 
  yes ) echo "Processing..";;
  y ) echo "Processing..";;
  Y ) echo "Processing..";;
  YES ) echo "Processing..";;
  Yes ) echo "Processing..";;
  * ) echo "Abort";
    exit 41;;
esac

rename_directories ${old_project_snake_name} ${new_project_snake_name}
for type in "${file_types[@]}"; do
  rename_files ${type} ${old_project_snake_name} ${new_project_snake_name}
  update_file_contents ${type} ${old_project_snake_name} ${new_project_snake_name} ${old_project_pascal_name} ${new_project_pascal_name}
done
cd ..
mv ${old_project_snake_name} ${new_project_snake_name}
cd ${new_project_snake_name}

echo "Project successfully renamed from ${old_project_pascal_name} to ${new_project_pascal_name}."
echo ""
echo "Note: The DB name in ./config/dev.exs may have been changed"
echo "      Verify if the project name in .git/config needs changing"
echo "      Verify the js and css files are happy. (Or add \"js\" and \"css\" to file_types"
echo "      rm ${0}"

exec $SHELL
