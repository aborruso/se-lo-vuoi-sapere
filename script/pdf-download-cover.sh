#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Questo script permette di scaricare dati e, opzionalmente, di cancellare
# i file scaricati passando un parametro specifico.
# Usa il parametro -d seguito da "sì" per abilitare la cancellazione dei file.
# Esempio di uso: ./download.sh -d sì
# Qualsiasi altro valore passato con -d, o l'omissione di -d, non attiverà la cancellazione.

# Imposta il valore di default di cancella a "no"
cancella="no"

# Usa getopts per gestire le opzioni
while getopts ":d:" opt; do
  case ${opt} in
    d )
      # Controlla se l'argomento è esattamente "sì"
      if [ "$OPTARG" = "sì" ]; then
        cancella="sì"
      else
        cancella="no"
      fi
      ;;
    \? )
      echo "Opzione Invalida: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Opzione -$OPTARG richiede un argomento." 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Controlla se cancella è impostato a "sì"
if [ "$cancella" = "sì" ]; then
  echo "Il valore di cancella è impostato a 'sì'."
  # Aggiungi qui il codice per gestire la cancellazione.
else
  echo "Il valore di cancella è impostato a 'no'."
fi


if [ "${cancella}" == "sì" ]; then
  find "${folder}"/../pubblicazioni -mindepth 2 -name "*.png" -type f -delete
  find "${folder}"/../pubblicazioni -mindepth 2 -name "*.pdf" -type f -delete
fi

<"${folder}"/risorse/lista-pubblicazioni.csv mlrgo --icsv --ojsonl filter '$pronto=="x"' then clean-whitespace then sort -t id | while read -r line; do
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



