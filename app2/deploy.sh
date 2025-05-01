#!/bin/bash
# Script to deploy the app2 stack

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

# Deploy the stack
echo "Deploying app2 stack..."
docker stack deploy --with-registry-auth -c docker-stack.yml app2

# Check status
echo "Checking service status..."
docker service ls | grep app2