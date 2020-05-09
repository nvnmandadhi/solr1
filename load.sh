#!/bin/bash

set -e

working_dir="$(date +"%D:%H:%M")"
echo "Working directory is $working_dir"
mkdir -p "$working_dir/data.json"

echo "Processing the data"
rm -fr temp
mkdir temp && pushd temp
git clone git@github.com:CSSEGISandData/COVID-19.git
pushd ./COVID-19/csse_covid_19_data/csse_covid_19_daily_reports

i=0
for file in *.csv; do
  i=$((i + 1))
  csvtojson "$file" | jq -c .[] <"$i.json" | tr -d '\r' | while read line; do
    echo '{ "index" : {"_index" : "test" } }' >>"$working_dir/data.json"
    echo "$line" >>"$working_dir/data.json"
  done
  if [ $((i % 100)) -eq 0 ]; then
    echo "Processed $i input files"
  fi
done

echo "Completed processing the input files"
echo "Indexing the data now, this takes time"
echo "********************************************"

curl -u 'elastic:f446grIQIADV99h22e2bM2T9' \
  -o /dev/null \
  -s -w '%{http_code}'-XPOST \
  -I \
  -H 'Content-Type: application/x-ndjson' \
  -k 'https://localhost:9200/test/_bulk?pretty' \
  --data-binary "@$working_dir/data.json"

echo "********************************************"

popd
popd
