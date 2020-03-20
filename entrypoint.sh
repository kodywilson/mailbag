#!/bin/bash

set -e

# Start the run once job.
echo "Ruby mailbag Docker container has been started"

# Setup a cron schedule - run every 5 minutes
crontab -l | { cat; echo "*/5 * * * * /usr/bin/ruby /usr/app/mailbag.rb >> /var/log/cron.log 2>&1
# This extra line makes it a valid cron"; } | crontab - && crond -f -L /dev/stdout
