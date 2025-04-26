# Dockerfile (for App 1)
# Builds the container image for the first FrankenPHP application.

# Use the official FrankenPHP image as a base
# See https://github.com/dunglas/frankenphp for available tags and options
# Choose specific PHP version if needed
FROM dunglas/frankenphp:latest-php8.3

# FrankenPHP uses /app/public as the default document root.
# Copy your application's public files into the container.
COPY public/ /app/public/

# Optional: Copy other application files if needed (e.g., vendor directory)
# COPY . /app

# Optional: Set environment variables if needed by your application
# ENV APP_ENV=production

# Optional: Expose port if needed for direct access (not required when using Traefik)
# EXPOSE 80

# The base image's entrypoint will start FrankenPHP.
# No CMD or ENTRYPOINT needed unless overriding default behavior.
