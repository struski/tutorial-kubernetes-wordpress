#!/usr/bin/env bash
# based on tutorial https://codeable.io/wordpress-developers-intro-to-docker-part-two/
printf "READY\n";

while read line; do
  echo "Incoming Supervisor event: $line" >&2;
  kill -3 $(cat "/var/run/supervisord.pid")
done < /dev/stdin