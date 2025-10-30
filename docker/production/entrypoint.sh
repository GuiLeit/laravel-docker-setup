#!/bin/sh
set -e

# Initialize storage directory if empty
# -----------------------------------------------------------
# If the storage directory is empty, copy the initial contents
# and set the correct permissions.
# -----------------------------------------------------------
if [ ! "$(ls -A /var/www/storage)" ]; then
  echo "Initializing storage directory..."
  cp -R /var/www/storage-init/. /var/www/storage
fi

# Remove storage-init directory
rm -rf /var/www/storage-init

# Remove Vite hot file to ensure production uses built assets
# -----------------------------------------------------------
# The 'hot' file tells Laravel to use Vite dev server.
# We must remove it in production to use pre-built assets.
# -----------------------------------------------------------
rm -f /var/www/public/hot

# Fix permissions for Laravel directories
echo "Setting correct permissions..."
# Ensure directories are writable by the FPM process
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache || true
chmod -R 775 /var/www/storage /var/www/bootstrap/cache || true

php artisan key:generate --force

# Run Laravel migrations
# -----------------------------------------------------------
# Ensure the database schema is up to date.
# -----------------------------------------------------------
php artisan migrate --force

# Clear and cache configurations
# -----------------------------------------------------------
# Improves performance by caching config and routes.
# -----------------------------------------------------------
php artisan config:cache
php artisan route:cache

php artisan storage:link

# Run the default command
exec "$@"
