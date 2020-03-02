#!/bin/bash

set -e

# Start the run once job.
echo "Docker container has been started"

# Setup a cron schedule
echo "0 8 * * * /usr/bin/ruby /usr/app/mailbag.rb >> /var/log/cron.log 2>&1
# This extra line makes it a valid cron" | crontab - && crond -f -L /dev/stdout
