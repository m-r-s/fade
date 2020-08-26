#!/bin/bash

db_name="${1}"
db_action="${2}"
entry_name="${3}"
entry_value="${4}"

# Get Lock
while ! mkdir "${db_name}-lock.d" &>/dev/null; do
  sleep 1
done
# Do whatever
case $db_action in
  new)
    sqlite3 "${db_name}" "CREATE TABLE ${entry_name} (value varchar(20));"
    sqlite3 "${db_name}" "INSERT INTO ${entry_name} VALUES ('${entry_value}');"
  ;;
  add)
    sqlite3 "${db_name}" "INSERT INTO ${entry_name} VALUES ('${entry_value}');"
  ;;
  get)
    tmp=$(sqlite3 "${db_name}" "SELECT value FROM ${entry_name}")
    rws.sh "${tmp}"
  ;;
esac
# Unlock
rmdir "${db_name}-lock.d"
