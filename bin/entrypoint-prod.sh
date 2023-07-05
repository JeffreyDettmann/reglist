#!/bin/bash
set -e

# Wait for database
until nc -z -v -w30 $DATABASE_HOST  $DATABASE_PORT; do
    echo 'Waiting for database'
    sleep 1
done
echo 'DB up and running'

# Create database if not exist; run migrations
bundle exec rails db:migrate 2>/dev/null || bundle exec rails db:create db:migrate
echo 'DB created and migrated'

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
