#!/bin/bash

main() {
    if [ "$IS_WORKER" = "true" ]; then
        exec "$@"
    else
        prepare_file_permissions
        prepare_storage
        wait_for_db
        run_migrations
        optimize_app
        run_server "$@"
    fi
}

prepare_file_permissions() {
    chmod a+x ./artisan
}

prepare_storage() {
    # Create required directories for Laravel
    mkdir -p /var/www/storage/framework/cache/data
    mkdir -p /var/www/storage/framework/sessions
    mkdir -p /var/www/storage/framework/views
    mkdir -p /var/www/storage/logs
    mkdir -p /var/www/bootstrap/cache

    # Set permissions so both host user and www-data can write
    # Using 777 for development only (volumes are mounted from host)
    chmod -R 777 /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true

    # Ensure the symlink exists
    php artisan storage:link 2>/dev/null || true
}

wait_for_db() {
    echo "Waiting for DB to be ready"
    until ./artisan migrate:status 2>&1 | grep -q -E "(Migration table not found|Migration name)"; do
        sleep 1
    done
}

run_migrations() {
    ./artisan migrate --force
}

optimize_app() {
    ./artisan optimize:clear
    # Skip optimize in development for hot reload
    # ./artisan optimize
}

run_server() {
    exec /usr/local/bin/docker-php-entrypoint "$@"
}

main "$@"