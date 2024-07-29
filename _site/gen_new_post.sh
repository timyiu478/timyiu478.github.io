#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

file_name="$1"

if [[ -z "$file_name" ]]
then
  echo "Please enter file name with no space"
  exit 1
fi

file_path="./_posts/"
today_date=$(date +%F)

cp post_template.md "${file_path}${today_date}-${file_name}.md"
