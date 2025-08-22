#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Deploying to development endpoint: recette-api-dev..."

# Deploy the function with the hardcoded 'dev' name
gcloud functions deploy recette-api-dev \
  --gen2 \
  --runtime=python311 \
  --region=us-central1 \
  --source=. \
  --entry-point=recipe_analyzer_api \
  --trigger-http \
  --allow-unauthenticated \
  --memory=1Gi

echo "✅ Deployment to recette-api-dev complete."