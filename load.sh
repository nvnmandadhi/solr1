#!/bin/bash

set -e

echo "Processing the input files and generating data to index"
git clone git@github.com:CSSEGISandData/COVID-19.git || echo "data is up-to-date"
pushd ./COVID-19/csse_covid_19_data/csse_covid_19_daily_reports

echo "Number of input files to process: $(ls | wc -l)"

i=0
for file in *.csv; do
  touch data.json
  i=$((i + 1))
  awk 'NR==1{$0=tolower($0)} 1' "$file" \
  | sed -e '1s/ /_/g' \
  | sed -e '1s/\//_/g' \
  | csvtojson | jq -c .[] \
  | tr -d '\r' | while read line; do
    echo "$line" >> data.json
  done

  post -c data data.json
  # shellcheck disable=SC2181
  if [[ "$?" -ne 0 ]]; then
    echo "failed at $file"
  fi

  rm -fr data.json

  if [[ $((i % 5)) -eq 0 ]]; then
    echo "Processed and indexed $i input files"
  fi
done

echo "*********** Indexing complete ***********"
popd