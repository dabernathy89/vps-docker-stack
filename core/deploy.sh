#!/bin/bash
# Script to deploy the core infrastructure stack

# Set the required Docker context
REQUIRED_CONTEXT="certain-painter"
CURRENT_CONTEXT=$(docker context show)

echo "Current Docker context: $CURRENT_CONTEXT"
if [ "$CURRENT_CONTEXT" != "$REQUIRED_CONTEXT" ]; then
  echo "Switching to required context: $REQUIRED_CONTEXT"
  docker context use $REQUIRED_CONTEXT
  
  # Verify the switch was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to switch to context '$REQUIRED_CONTEXT'"
    echo "Does this context exist? Check with 'docker context ls'"
    exit 1
  fi
  
  # Double-check that we're now using the correct context
  CURRENT_CONTEXT=$(docker context show)
  if [ "$CURRENT_CONTEXT" != "$REQUIRED_CONTEXT" ]; then
    echo "Error: Context switch did not take effect"
    exit 1
  fi
fi

echo "✓ Using Docker context: $CURRENT_CONTEXT"

# Source environment variables
if [ ! -f .env ]; then
  echo "Error: .env file not found in the current directory"
  exit 1
fi

# Export all variables from .env (excluding comments)
export $(grep -v '^#' .env | xargs)

# Build custom images
echo "Building custom images..."
./build.sh
if [ $? -ne 0 ]; then
  echo "Error: Failed to build custom images"
  exit 1
fi

# Deploy the stack
echo "Deploying core infrastructure stack (Traefik + Gantry)..."
docker stack deploy --with-registry-auth -c docker-stack.yml core

# Check status
echo "Checking service status..."
docker service ls | grep core