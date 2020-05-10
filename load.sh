#!/bin/bash

set -e

nohup kubectl port-forward svc/solr-svc 8983:8983 > /dev/null
nohup kubectl port-forward svc/zk-cs 2181:2181 > /dev/null

solr rm -r /configs/* -z localhost:2181
solr zk upconfig -d data1 -n data1-config -z localhost:2181

generated_dir="$(date +%Y%m%d)"
working_dir=$(pwd)
echo "Data will be stored in directory $working_dir/$generated_dir"
rm -fr "$generated_dir"
mkdir -p "$generated_dir"
pushd "$generated_dir" && touch data.json && popd

echo "Processing the input files and generating data to index"
pushd temp || (mkdir temp && pushd temp)
git pull || git clone git@github.com:CSSEGISandData/COVID-19.git
pushd ./COVID-19/csse_covid_19_data/csse_covid_19_daily_reports

echo "Number of input files to process: $(ls | wc -l)"

i=0
for file in *.csv; do
  i=$((i + 1))
  awk 'NR==1{$0=tolower($0)} 1' "$file" \
  | sed -e '1s/ /_/g' \
  | sed -e '1s/\//_/g' \
  | csvtojson | jq -c .[] \
  | tr -d '\r' | while read line; do
    echo "$line" >>"$working_dir/$generated_dir/data.json"
  done

  post -c data1 "$working_dir/$generated_dir/data.json"

  true >"$working_dir/$generated_dir/data.json"

  if [[ $((i % 5)) -eq 0 ]]; then
    echo "Processed and indexed $i input files"
  fi
done

echo "*********** Indexing complete ***********"
popd 2
# shellcheck disable=SC2115
rm -fr "$working_dir/$generated_dir"
