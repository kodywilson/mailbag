#!/bin/bash

set -e

# Start the run once job.
echo "Ruby mailbag Docker container has been started"

crond -n
# Setup a cron schedule - run every 5 minutes - old way
#crontab -l | { cat; echo "*/5 * * * * /usr/bin/ruby /usr/app/mailbag.rb >> /var/log/cron.log 2>&1
# This extra line makes it a valid cron"; } | crontab - && crond -n
# crond won't work like above, you have to remove the command flags
