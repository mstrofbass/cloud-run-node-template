#! /bin/sh

echoBlue () {
  echo "${BLUE}$1${NC}"
}

echoRed () {
  echo "${RED}$1${NC}"
}

echoEnvVar () {
  echo "  ${BLUE}$1:${NC} $2"
}

function retry_command () {
  SLEEP_TIME=10

  echo "Trying command $@ with a sleep time of $SLEEP_TIME seconds"
  
  for i in 1 2 3 4 5 6 7 8 9 10
    do 
      echo "attempt $i" 
      "$@" && break || sleep $SLEEP_TIME
    done
}

set -e
script_dir=`dirname $0`

source $script_dir/gcp-config.sh

DEPLOYMENT_CONFIG_FILE_PATH=./deployment/config.yml
APIS_TO_ENABLE=(iam run artifactregistry)

if test -f "$DEPLOYMENT_CONFIG_FILE_PATH"; then
  echoRed "$DEPLOYMENT_CONFIG_FILE_PATH already exists. Please delete it if you would like to continue."
  exit 1
fi


###############
# Create Project
###############

echoRed "\n[Project Settings]\n"

echoBlue "Creating project $PROJECT_NAME..."
gcloud projects create $PROJECT_NAME

echoBlue "Enabling billing account for $PROJECT_NAME..."
gcloud beta billing projects link $PROJECT_NAME --billing-account $BILLING_ACCOUNT_ID


###############
# Enable APIs
###############

echoRed "\n[API Settings]\n"

for i in "${APIS_TO_ENABLE[@]}"
do
  apiPath="$i.googleapis.com"
  echoBlue "Enabling $apiPath API..."
  gcloud --project $PROJECT_NAME services enable $apiPath
done


###############
# Create Service Accounts
###############

echoRed "\n[Service Accounts]\n"

GITHUB_SERVICE_ACCOUNT_EMAIL="github-actions@$PROJECT_NAME.iam.gserviceaccount.com"
SERVICE_SERVICE_ACCOUNT_EMAIL="$SERVICE_NAME@$PROJECT_NAME.iam.gserviceaccount.com"

echoBlue "Creating the $SERVICE_NAME service account..."
gcloud --project $PROJECT_NAME iam service-accounts create $SERVICE_NAME

echoBlue "Creating the github-actions service account..."
gcloud --project $PROJECT_NAME iam service-accounts create github-actions


###############
# Create Workload Identity Federation Stuff
#
# I ran into an error saying:
# ERROR: (gcloud.iam.workload-identity-pools.create) PERMISSION_DENIED: Permission 'iam.workloadIdentityPools.create' denied on resource 
# '//iam.googleapis.com/projects/mstrofbass-test2/locations/global' (or it may not exist).
# When I reran the command shortly after, it worked, so I think this was a creation delay so I'm adding a retry command fn.
###############

echoRed "\n[Workload Identity Federation]\n"

echoBlue "Creating the workload identity federation pool..."
retry_command gcloud --project $PROJECT_NAME iam workload-identity-pools create github --location="global"

echoBlue "Creating the workload identity federation provider..."
gcloud --project $PROJECT_NAME iam workload-identity-pools providers create-oidc github \
  --location="global" \
  --workload-identity-pool="github" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository_visibility=assertion.repository_visibility,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository_visibility == \"private\" && assertion.repository in [\"$GITHUB_REPO_PATH\"]"


# get project number because why would Google make this easy?

echoBlue "Getting the project number from Google..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_NAME --format=value\(projectNumber\))

echoBlue "Extracted the project number: $PROJECT_NUMBER"

echoBlue "Adding the $GITHUB_SERVICE_ACCOUNT_EMAIL to the provider as an impersonable service account..."
gcloud --project $PROJECT_NAME iam service-accounts add-iam-policy-binding $GITHUB_SERVICE_ACCOUNT_EMAIL \
    --role=roles/iam.workloadIdentityUser \
    --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/*"


###############
# Create artifact registry repository
###############

echoRed "\n[Artifact Registry]\n"

echoBlue "Creating the artifact registry repository..."
gcloud --project $PROJECT_NAME artifacts repositories create $DOCKER_REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --mode standard-repository


###############
# Create service
###############

echoRed "\n[Cloud Run]\n"

echoBlue "Creating the initial Cloud Run service..."
gcloud --project $PROJECT_NAME run deploy $SERVICE_NAME \
  --region $REGION \
  --image "us-docker.pkg.dev/cloudrun/container/hello" \
  --concurrency $CLOUD_RUN_MAX_CONCURRENT \
  --cpu $CLOUD_RUN_CPU \
  --max-instances $CLOUD_RUN_MAX_INSTANCES \
  --memory $CLOUD_RUN_MEMORY \
  --service-account $SERVICE_SERVICE_ACCOUNT_EMAIL \
  --allow-unauthenticated


###############
# Assign IAM roles
# We do this last because in some cases we can't do this until certain resources are created. 
# For example, if you want to give the Secret Manager Secret Accessor role to a particular secret,
# the secret has to be created first. Not required here but useful in case we want to reuse
# this script elsewhere
###############

echoRed "\n[Permissions]\n"

echoBlue "Assigning the roles/run.developer role to the $GITHUB_SERVICE_ACCOUNT_EMAIL service account"
gcloud projects add-iam-policy-binding $PROJECT_NAME --member="serviceAccount:$GITHUB_SERVICE_ACCOUNT_EMAIL" --role="roles/run.developer"

echoBlue "Assigning the roles/artifactregistry.writer role to the $GITHUB_SERVICE_ACCOUNT_EMAIL service account"
gcloud projects add-iam-policy-binding $PROJECT_NAME --member="serviceAccount:$GITHUB_SERVICE_ACCOUNT_EMAIL" --role="roles/artifactregistry.writer"

echoBlue "Assigning the $GITHUB_SERVICE_ACCOUNT_EMAIL the serviceAccountUser role for the $SERVICE_SERVICE_ACCOUNT_EMAIL"
gcloud --project $PROJECT_NAME iam service-accounts add-iam-policy-binding $SERVICE_SERVICE_ACCOUNT_EMAIL --member "serviceAccount:$GITHUB_SERVICE_ACCOUNT_EMAIL" --role roles/iam.serviceAccountUser


###############
# Write out the deployment config file
###############

echoRed "\n[Deployment Configuration]\n"

WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/github"
CONTAINER_REGISTRY="$REGION-docker.pkg.dev"
DOCKER_IMAGE_PATH="$PROJECT_NAME/$DOCKER_REPO_NAME/$SERVICE_NAME"

echoBlue "Saving deployment config to ./deployment/config.yml ..."

cat > "$DEPLOYMENT_CONFIG_FILE_PATH" <<config
docker-build:
  workload-identity-provider: "$WORKLOAD_IDENTITY_PROVIDER"
  gcp-service-account-email: "$GITHUB_SERVICE_ACCOUNT_EMAIL"
  container-registry: "$CONTAINER_REGISTRY"
  image-name: "$SERVICE_NAME"
  image-path: "$DOCKER_IMAGE_PATH"

deploy-cloud-run:
  workload-identity-provider: "$WORKLOAD_IDENTITY_PROVIDER"
  gcp-service-account-email: "$GITHUB_SERVICE_ACCOUNT_EMAIL"
  service-region: $REGION
  service-name: "$SERVICE_NAME"
  image-path: "$CONTAINER_REGISTRY/$DOCKER_IMAGE_PATH"
  env-vars-file-path: "deployment/env.dev.yml"
config