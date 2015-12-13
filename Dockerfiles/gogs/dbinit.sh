#!/bin/bash
# Create database & start postgrest

echo "***** RUN INIT FOR DB  $DB_NAME ***"

echo "Wait for local consul copy and postgresql startup..."
while true; do ping -c1 $PG_HOST > /dev/null 2>&1 && break; done
echo "Done"

# Try to create user & database. Get result
curl -s "http://$PG_HOST:8080/?key=$DBCC_KEY&name=$DB_NAME&pass=$DB_PASS" | grep "OK: .1" && {
  echo "Created database $DB_NAME"
  # Init db if needed
}

# Start app
# app named like db
supervisorctl -c /etc/supervisor/supervisord.conf start $DB_NAME

# Say all is Ok to supervisor
exit 0