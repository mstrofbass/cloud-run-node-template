# Node-based Cloud Run Service Template

To configure and deploy a Cloud Run-based Node service using this template, please follow these instructions:

## Configure Your GCP Project

You first need to configure your GCP project. If you're using an existing project, you may be able to skip some of these steps (e.g., Artifact Registry repository creation). I have included a list of information you will need to have handy to configure, build, and deploy the service below the instructions and have explicitly noted when you will have access to that information. I highly recommend recording it as you go along.

1. Figure out the name of your service and record it as SERVICE NAME (e.g., `test-service`).
1. Create a new project if you do not already have one to use.
2. Select the project.
3. Record your project id (e.g., `cloud-run-test-874548`). (Available on the project welcome screen.)
4. Record your project number (e.g., `832246578452`). (Available on the project welcome screen.)
5. Go to Artifact Registry.
6. Enable the API if the Artifact Registry API screen is displayed.
7. Create a new repository with the following settings:
  a. Name: Whatever makes sense (e.g., `docker`)
  b. Format: Docker
  c. Mode: Standard
  d. Location Type: Region
  e. Region: Your preferred region (you will use this same region for your service)
8. Record the region as the REPOSITORY REGION.
9. Record the repository name as the REPOSITORY NAME.
10. Click into the repository (e.g., if you named the repository `docker`, click the `docker` link).
11. The top breadcrumbs will be something like `us-east1-docker.pkg.dev > PROJECT ID > REPOSITORY NAME`. Record the first part (e.g., `us-east1-docker.pkg.dev`) as the `CONTAINER REGISTRY`
10. Go to IAM > Service Accounts
11. Create new service account with the following configuration:
  a. Service account name: `github-actions`
  b. Step 2 ("Grant this service account access to project") - Grant the following roles: 
    i. `Artifact Registry Writer`
    ii. `Cloud Run Developer` 
  b. No other configuration required.
11. Create new service account with the following configuration:
  a. Service account name: use the service name that you chose in step one (e.g., `test-service`)
  b. Skip step 2 ("Grant this service account access to project")
  c. Step 3: Under "Service account users role", add your `github-actions` service account.
12. Go to IAM > Workload Identity Federation
13. Click `Get Started` if no WIF has been previously configured.
14. Create a new identity pool with the following configuration:
  a. Name: `github`
  b. Select a provider: `OpenID Connect (OIDC)`
  c. Provider name: `github`
  d. Issuer (URL): `https://token.actions.githubusercontent.com`
  e. Default audience
  f. Provider Attributes:
    i. google.subject -> assertion.sub
    ii. attribute.repository_visibility -> assertion.repository_visibility
    iii. attribute.repository -> assertion.repository
  g. Add Condition: `assertion.repository_visibility == "private" && assertion.repository in ["REPOSITORY NAME"]`
    i. REPOSITORY NAME should be in the `username/repo-name` form (e.g., `mstrofbass/cloud-run-test`). Example: `assertion.repository_visibility == "private" && assertion.repository in ["mstrofbass/cloud-run-test"]`
15. After creating the pool click on `GRANT ACCESS` and select the `github-actions` service account. Leave `All identifies in the pool` selected and click SAVE.
16. DISMISS the `Configure your application` screen without downloading anything.
17. Go to Cloud Run
18. Create Service with the following configuration:
  a. Container image URL: Click `TEST WITH A SAMPLE CONTAINER`
  b. Service name: Use the name of your service from above.
  c. Region: Use the same region as you used for your repository.
  d. Most of the remaining settings can be configured to match the requirements of your service. The defaults are fine to begin with but I would limit the maximum number of instances to `5` or something to keep you from accidentally incurring a bunch of charges if you screw up your testing.
  e. Authentication: Allow unauthentication invocations (this is usually not a great idea but we'll use it for simplicity sake).
  f. Expand `Container Networking Security` and select the service account that's named the same as your service (e.g., `test-service`)
  g. `Create`

SERVICE NAME: test-service
PROJECT ID: `cloud-run-test-378103`
PROJECT NUM: `756237419063`
REPOSITORY REGION: us-east1
REPOSITORY NAME: docker
CONTAINER REGISTRY: us-east1-docker.pkg.dev

## Configure Your Repository

1. Make a new repo based on this template.
2. Clone the repo to your local machine.
3. Run `npm install`
4. Create a new branch (e.g., `git checkout -b chore/configure-deployment`)
5. Open `.github/workflows/lint.yml`
6. Verify the `node` version (currently defaults to 18). Update to the version you prefer.
5. Open `.github/workflows/pull-request.yml`
6. Verify the `node` versions in the matrix strategy (currently defaults to 18 and 19). Update to the version(s) you prefer.
5. Open `.github/workflows/push.yml`
6. Verify the `node` versions in the matrix strategy (currently defaults to 18 and 19). Update to the version(s) you prefer.
5. Open `Dockerfile`
6. Verify the `node` version (currently defaults to 18). Update to the version you prefer.
5. Open `deployment/config.yml`
6. Update the `docker-build` configuration:
  a. workload-identity-provider: Replace `PROJECT_NUM` with the `PROJECT NUM` you recorded previously.
  b. gcp-service-account-email: Replace `PROJECT_ID` with the `PROJECT ID` you recorded previously.
  c. container-registry: Replace `CONTAINER_REGISTRY` with the `CONTAINER REGISTRY` you recorded previously.
  d. image-name: Replace `SERVICE_NAME` with the `SERVICE NAME` you recorded previously.
  e. image-path: 
    i. Replace `PROJECT_ID` with the `PROJECT ID` you recorded previously.
    ii. Replace `REPOSITORY_NAME` with the `REPOSITORY NAME` you recorded previously.
    iii. Replace `SERVICE_NAME` with the `SERVICE NAME` you recorded previously.
7. Update the `deploy-cloud-run` configuration:
  a. workload-identity-provider: Replace `PROJECT_NUM` with the `PROJECT NUM` you recorded previously.
  b. gcp-service-account-email: Replace `PROJECT_ID` with the `PROJECT ID` you recorded previously.
  c. service-region: Replace `GCP_REGION` with the `REPOSITORY REGION` you recorded previously.
  d. service-name: Replace `SERVICE_NAME` with the `SERVICE NAME` you recorded previously.
  e. image-path: Replace `IMAGE_PATH` with the `container-registry` and `image-path` from the `docker-build` config concatenated: e.g., `us-east1-docker.pkg.dev/cloud-run-test-874548/docker/test-service`
8. Commit and push your changes.
9 
