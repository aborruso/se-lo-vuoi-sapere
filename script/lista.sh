#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cancella="no"
if [ "${cancella}" == "sì" ]; then
  find "${folder}"/../pubblicazioni -mindepth 2 -name "*.qmd" -type f -delete
fi


<"${folder}"/risorse/lista-pubblicazioni.csv mlrgo --icsv --ojsonl filter '$pronto=="x"' then cut -x -f indice then clean-whitespace then sort -t id then put 'if(${anno-mese}=~"^[0-9]{4}$"){${anno-mese}=${anno-mese}."-00"}else{${anno-mese}=${anno-mese}}' | while read -r line; do
  echo "${line}" | jq -r '.["titolo"]'
  id="$(echo "${line}" | jq -r '.["id"]')"
  mkdir -p "${folder}"/../pubblicazioni/"${id}"
  mkdir -p "${folder}"/../pubblicazioni/"${id}"/include
  fonte="$(echo "${line}" | jq -r '.["fonte"]')"

  titolo="$(echo "${line}" | jq -r '.["titolo"]' | sed -r 's/\"/\\"/g')"
  filename="$(echo "${line}" | jq -r '.["titolo"]' | qsv safenames | sed -r 's/_+/-/g;s/-$//')"
  data="$(echo "${line}" | jq -r '.["anno-mese"]')"
  categorie="$(echo "${line}" | jq -r '.["violenze"]')"

  truncate -s 0 "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd

  touch "${folder}"/../pubblicazioni/"${id}"/include/_"${id}".qmd

  echo "---" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd
  echo "title: \"$titolo\"" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd
  echo "data: $data" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd
  echo "fonte: \"$fonte\"" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd

  if [ -f "${folder}"/../pubblicazioni/"${id}"/risorse/"${filename}"_resized.png ]; then
    echo "image: ./risorse/${filename}_resized.png" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd
  fi

# if categorie greather than two characters echo "long" else echo "short"
  if [ "${#categorie}" -gt 2 ]; then
    echo "categories: [$categorie]" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd
  fi

  echo "---" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd
  echo "" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd

  echo "{{< include ./include/_${id}.qmd >}}" >> "${folder}"/../pubblicazioni/"${id}"/"${filename}".qmd
done
