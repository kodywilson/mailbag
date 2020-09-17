#!/bin/bash

set -x;
# ^^^ verbosely echo command lines run
set -e;
# ^^^ exit on error in subprocess
 
# Optionally you can add sleep if your service takes many minutes to validate.
sleep 10;
# ^^^ time is in seconds

output=$(pwd);
if [ "${output}" != "/usr/app" ]; then
    echo something went wrong, got ${output} but expected /usr/app
    exit 1;
fi
exit 0;
