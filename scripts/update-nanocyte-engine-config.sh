#!/bin/bash

run_jq(){
  local json=$1
  local command=$2
  docker run --rm --name jq realguess/jq sh -c "echo '$json' | jq --raw-output --compact-output \"$command\""
}

run_in_redis(){
  local command=$@

  docker run \
    --rm redis \
    sh -c "exec redis-cli -h \"$REDIS_HOST\" $command | cat"
}

filter_flows() {
  local keys=$1
  echo "$keys" \
    | grep -v ':' \
    | grep -v ElastiCacheMasterReplicationTimestamp
}

filter_engine_output() {
  local raw_keys=$1

  echo "$raw_keys" \
    | grep 'engine-output' \
    | grep 'config'
}

get_flow_keys() {
  local keys=$(run_in_redis KEYS '*')
  local raw_flows=$(filter_flows "$keys")
  local flows

  IFS=$'\n' read -rd '' -a flows <<<"$raw_flows"
  echo "${flows[@]}"
}

get_engine_output_keys(){
  local flow_key="$1"
  local raw_keys=$(run_in_redis HKEYS "$flow_key")
  local raw_output_keys=$(filter_engine_output "$raw_keys")
  local engine_output_keys

  IFS=$'\n' read -rd '' -a engine_output_keys <<<"$raw_output_keys"
  echo "${engine_output_keys[@]}"
}

replace_meshblu_server(){
  local config=$1
  run_jq $config 'setpath([\"server\"]; \"meshblu-messages.octoblu.com\")'
}

update_flow_output_config(){
  local flow_key=$1
  local instance_key=$2
  local config=$(run_in_redis HGET "$flow_key" "$instance_key")

  local updated_config=$(replace_meshblu_server "$config")
  run_in_redis HSET "$flow_key" "$instance_key" "'$updated_config'"
  run_in_redis HGET "$flow_key" "$instance_key"
}

update_flow_output_configs(){
  local flow_key="$1"
  local instance_keys=( $(get_engine_output_keys "$flow_key") )
  echo "${instance_keys[@]}"

  for instance_key in "${instance_keys[@]}"; do
    update_flow_output_config "$flow_key" "$instance_key"
  done
}

main() {
  local flow_keys=( $(get_flow_keys) )

  for flow_key in "${flow_keys[@]}"; do
    echo "updating: $flow_key"
    update_flow_output_configs "$flow_key"
  done
}
main $@
