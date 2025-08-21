gcloud functions deploy recipe_analyzer_api-v1 \
--gen2 \
--runtime=python311 \
--region=us-central1 \
--source=. \
--entry-point=recipe_analyzer_api \
--trigger-http \
--allow-unauthenticated \
--memory=1Gi