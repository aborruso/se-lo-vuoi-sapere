#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cancella="sì"
if [ "${cancella}" == "sì" ]; then
  find "${folder}"/../pubblicazioni -mindepth 2 -name "*.png" -type f -delete
  #find "${folder}"/../pubblicazioni -mindepth 2 -name "*.pdf" -type f -delete
fi

<"${folder}"/risorse/lista-pubblicazioni.csv mlrgo --icsv --ojsonl filter '$pronto=="x"' | while read -r line; do
  url="$(echo "${line}" | jq -r '.["URL"]')"
  id="$(echo "${line}" | jq -r '.["id"]')"
  mkdir -p "${folder}"/../pubblicazioni/"${id}"
  mkdir -p "${folder}"/../pubblicazioni/"${id}"/risorse
  titolo="$(echo "${line}" | jq -r '.["titolo"]')"
  filename="$(echo "${line}" | jq -r '.["titolo"]' | qsv safenames | sed -r 's/_+/-/g;s/-$//')"

  if [[ ${url} == *".pdf"* ]]; then
    if [ ! -f "${folder}"/../pubblicazioni/"${id}"/risorse/"${filename}".pdf ]; then
      curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36" ${url} -o "${folder}"/../pubblicazioni/"${id}"/risorse/"${filename}".pdf
    fi
  else
      echo "non è un PDF"
  fi

done

find "${folder}"/../pubblicazioni -name "*.pdf" -type f | while read -r file; do
  filename=$(basename "$file" .pdf)
  echo "$filename"
  path=$(dirname "$file")
  if [ ! -f "${path}"/"${filename}".png ]; then
    pdftoppm -png -f 1 -singlefile -r 96 "$file" "${path}"/"${filename}"
  fi
done

find "${folder}"/../pubblicazioni -name "*.png" ! -name "*_resized*" -type f | while read -r file; do
  filename=$(basename "$file" .png)
  path=$(dirname "$file")

  new_file="${filename}_resized"

  if [ ! -f "${path}"/"${new_file}".png ]; then
    convert "$file" -resize 640x480 -background white -gravity center -extent 790x480 "${path}"/"${new_file}".png
  fi
done



