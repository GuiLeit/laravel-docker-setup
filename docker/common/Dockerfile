# ============================================
# Base Stage - Common dependencies
# ============================================
FROM php:8.4-fpm-alpine AS base

# Install system dependencies for Alpine Linux
RUN apk add --no-cache \
    # Build dependencies
    $PHPIZE_DEPS \
    autoconf \
    g++ \
    make \
    # Common dependencies
    bash \
    curl \
    git \
    unzip \
    wget \
    # PostgreSQL
    postgresql-client \
    postgresql-dev \
    # Image processing
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    # Compression
    libzip-dev \
    zlib-dev \
    # String processing
    oniguruma-dev \
    # XML
    libxml2-dev \
    # NodeJS and npm (for frontend assets)
    nodejs \
    npm \
    # Redis CLI (optional, for debugging)
    redis

# Configure GD with JPEG and FreeType support
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_pgsql \
    pgsql \
    gd \
    bcmath \
    zip \
    opcache \
    pcntl \
    mbstring \
    exif \
    xml \
    soap

# Install Redis extension via PECL
RUN pecl install redis \
    && docker-php-ext-enable redis

# Clean up build dependencies to reduce image size
RUN apk del $PHPIZE_DEPS autoconf g++ make

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Set Composer to allow running as root
ENV COMPOSER_ALLOW_SUPERUSER=1

# Set working directory
WORKDIR /var/www

# ============================================
# Development Stage
# ============================================
FROM base AS development

# Install Xdebug for development
RUN apk add --no-cache $PHPIZE_DEPS linux-headers \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del $PHPIZE_DEPS linux-headers

# Configure Xdebug (can be overridden by environment variables)
RUN echo "xdebug.mode=develop,debug,coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Create user for development (will match host user)
ARG UID=1000
ARG GID=1000
RUN addgroup -g ${GID} appuser \
    && adduser -D -u ${UID} -G appuser appuser

# Don't copy code in development - it will be mounted as volume
# Note: ENTRYPOINT and CMD are set in docker-compose for flexibility

# ============================================
# Production Stage
# ============================================
FROM base AS production

# Copy the codebase
COPY . ./

# Install production dependencies and optimize
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress \
    && composer clear-cache \
    && chmod -R 775 storage bootstrap/cache \
    && mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache/data \
    # Ensure correct ownership for runtime (php-fpm runs as www-data)
    && chown -R www-data:www-data /var/www \
    && chown -R www-data:www-data storage bootstrap/cache

# Build frontend assets
RUN npm ci && npm run build && rm -rf node_modules

# Note: ENTRYPOINT and CMD are set in docker-compose for flexibility