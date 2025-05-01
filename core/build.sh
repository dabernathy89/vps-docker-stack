#!/bin/bash
# Script to build custom Traefik and Gantry images

# Set the required Docker context
REQUIRED_CONTEXT="certain-painter"
CURRENT_CONTEXT=$(docker context show)

echo "Current Docker context: $CURRENT_CONTEXT"
if [ "$CURRENT_CONTEXT" != "$REQUIRED_CONTEXT" ]; then
  echo "Switching to required context: $REQUIRED_CONTEXT"
  docker context use $REQUIRED_CONTEXT
fi

# Build custom Traefik image
echo "Building custom Traefik image..."
docker build -t custom-traefik:latest -f Dockerfile.traefik .

# Build custom Gantry image
echo "Building custom Gantry image..."
docker build -t custom-gantry:latest -f Dockerfile.gantry .

echo "Build complete!"