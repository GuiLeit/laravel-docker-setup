# Stage 1: Build assets with Node.js (with PHP for Wayfinder generation)
FROM node:lts AS builder

# Install security updates and PHP for Wayfinder type generation
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    php8.2-cli \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-sqlite3 \
    php8.2-xml \
    php8.2-zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /var/www

# Copy composer files first for better caching
COPY composer.json composer.lock ./

# Install PHP dependencies (only those needed for Wayfinder)
RUN composer install --no-dev --no-scripts --no-autoloader --optimize-autoloader

# Copy package files first for better Docker layer caching
COPY package.json package-lock.json* ./

# Install Node.js dependencies with clean install for production builds
RUN npm ci

# Copy Laravel application source code
COPY . /var/www

# Copy build-time environment file and set up minimal Laravel environment
# COPY .env /var/www/.env

# Create minimal SQLite database and complete Laravel setup
RUN touch /tmp/database.sqlite && \
    composer dump-autoload --optimize --no-dev

# Generate Wayfinder types
RUN php artisan wayfinder:generate --with-form || echo "Wayfinder generation skipped - continuing anyway"

# Build production assets using original config (with Wayfinder types now available)
RUN npm run build

# Stage 2: Nginx production image
FROM nginx:alpine

# Copy custom Nginx configuration
# -----------------------------------------------------------
# Replace the default Nginx configuration with our custom one
# that is optimized for serving a Laravel application.
# -----------------------------------------------------------
COPY ./docker/production/nginx.conf /etc/nginx/nginx.conf

# Copy Laravel's public assets from the builder stage
# -----------------------------------------------------------
# We only need the 'public' directory from our Laravel app.
# -----------------------------------------------------------
COPY --from=builder /var/www/public /var/www/public

# Set the working directory to the public folder
WORKDIR /var/www/public

# Expose port 80 and start Nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]