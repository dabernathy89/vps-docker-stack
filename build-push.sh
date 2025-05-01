#!/bin/bash
# Script to build and push app images to GitHub Container Registry

# Load GitHub credentials from .env file
if [ -f ".env" ]; then
  echo "Loading GitHub credentials from .env"
  export $(grep -v '^#' .env | xargs)
else
  echo "Warning: .env file not found. Using default or environment values."
fi

# Check if GitHub credentials are available
if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_PAT" ]; then
  echo "Error: GitHub credentials not found in .env or environment"
  echo "Please create a .env file with GITHUB_USER and GITHUB_PAT"
  exit 1
fi

# Check if app name is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <app-name>"
  echo "Example: $0 app1"
  exit 1
fi

APP_NAME=$1
IMAGE_NAME="php-test-$APP_NAME"
IMAGE_TAG="latest"

# Verify the app directory exists
if [ ! -d "$APP_NAME" ]; then
  echo "Error: Directory '$APP_NAME' not found"
  exit 1
fi

# Switch to app directory
cd "$APP_NAME"

# Check for Dockerfile
if [ ! -f "Dockerfile" ]; then
  echo "Error: Dockerfile not found in $APP_NAME directory"
  exit 1
fi

echo "Building image: ghcr.io/$GITHUB_USER/$IMAGE_NAME:$IMAGE_TAG"
docker build -t "ghcr.io/$GITHUB_USER/$IMAGE_NAME:$IMAGE_TAG" .

# Check if build was successful
if [ $? -ne 0 ]; then
  echo "Error: Docker build failed"
  exit 1
fi

# Login to GitHub Container Registry
echo "Logging in to GitHub Container Registry..."
echo "$GITHUB_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

# Check if login was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to authenticate with GitHub Container Registry"
  echo "Please check your credentials in .env"
  exit 1
fi

echo "Pushing image to GitHub Container Registry..."
docker push "ghcr.io/$GITHUB_USER/$IMAGE_NAME:$IMAGE_TAG"

# Check if push was successful
if [ $? -ne 0 ]; then
  echo "Error: Docker push failed"
  exit 1
fi

echo "✓ Successfully built and pushed ghcr.io/$GITHUB_USER/$IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "Next steps:"
echo "1. cd $APP_NAME"
echo "2. ./deploy.sh"