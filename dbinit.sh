#!/bin/bash
#
# This script prepares application database via the following steps:
#
#   1. Create user/database if needed
#   2. Run /home/app/.ondbcreate if it exists and db was just created
#   3. Run /home/app/.ondbready if it exists
#   4. Start supervisord services listed in $DBINIT_START
#
# See project home for details: https://github.com/LeKovr/consup
#


# strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# logging func
log() {
  D=$(date "+%F %T")
  echo  "$D $1"
}

# onExit handler
function finish {
  # Special formatted message, do not change
  log "** Init done **"
}
trap finish EXIT

# ------------------------------------------------------------------------------

log "***** RUN INIT FOR DB $DB_NAME ***"

log "Wait for consul and postgresql startup..."
while true; do sleep 1 && ping -c1 $PG_HOST > /dev/null 2>&1 && break; done
log "DB started"

if [ -z ${DB_TEMPLATE+x} ]; then
  tmpl=""
  note=""
else
  log "Will use template $DB_TEMPLATE"
  tmpl="&tmpl=$DB_TEMPLATE"
  note=" with template $DB_TEMPLATE"
fi

# Try to create user & database. Get result
log "Check db"
curl -s "http://$PG_HOST:$DBCC_PORT/?key=$DBCC_KEY&name=$DB_NAME&pass=$DB_PASS$tmpl" | grep "OK: 1" && {
  log "Created database $DB_NAME$note"
  if [ -e /home/app/.ondbcreate ] ; then
    log "Run onDBCreate script"
    . /home/app/.ondbcreate
  fi
}

if [ -e /home/app/.ondbready ] ; then
  log "Run onDBReady script"
  . /home/app/.ondbready
fi

log "Start app"
for s in $DBINIT_START ; do
  supervisorctl -c /etc/supervisor/supervisord.conf start $s
done


# Say all is Ok to supervisor
exit 0
