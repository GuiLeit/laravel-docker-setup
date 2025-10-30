#!/bin/bash

# Change to the Laravel project directory first
cd /var/www

# Install Composer dependencies if vendor directory doesn't exist
if [ ! -d "vendor" ]; then
    echo "Installing Composer dependencies..."
    composer install --optimize-autoloader --no-interaction
fi

# Clean up any existing node_modules/.vite-temp
if [ -d "node_modules/.vite-temp" ]; then
    echo "Cleaning up Vite temp files..."
    rm -rf node_modules/.vite-temp
fi

# Install npm dependencies
echo "Installing npm dependencies..."
npm install

# Start Vite development server in background
echo "Starting Vite development server..."
npm run dev &

# Keep container running
tail -f /dev/null