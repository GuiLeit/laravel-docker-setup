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

# Ensure the public directory is accessible
# chown -R www-data:www-data /var/www/public || true
# chmod -R 755 /var/www/public || true

chown -R www-data:www-data /var/www/storage/app/public || true
chmod -R 775 /var/www/storage/app/public || true

if grep -qE '^DB_CONNECTION=sqlite' /var/www/.env 2>/dev/null; then
  touch /var/www/database/database.sqlite
  chown www-data:www-data /var/www/database/database.sqlite
fi

# Install Composer dependencies
# -----------------------------------------------------------
# Ensure vendor directory exists before running Laravel commands
# -----------------------------------------------------------
echo "Installing Composer dependencies..."
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

php artisan key:generate --force

# Run Laravel migrations
# -----------------------------------------------------------
# Ensure the database schema is up to date.
# -----------------------------------------------------------
php artisan migrate --force

# Install NPM dependencies and build frontend assets
# -----------------------------------------------------------
# Ensure node_modules exists and assets are built
# -----------------------------------------------------------
echo "Installing NPM dependencies..."
npm install

echo "Building frontend assets..."
npm run build

# Clear and cache configurations
# -----------------------------------------------------------
# Improves performance by caching config and routes.
# -----------------------------------------------------------
php artisan config:cache
php artisan route:cache

php artisan storage:link

# Fix storage symlink permissions
if [ -L "/var/www/public/storage" ]; then
    echo "Fixing storage symlink permissions..."
    chown -h www-data:www-data /var/www/public/storage || true
    chmod -R 755 /var/www/public/storage || true
fi

# Run the default command
exec "$@"
