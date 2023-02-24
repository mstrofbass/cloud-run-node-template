# Node-based Cloud Run Service Template <!-- omit from toc -->

- [What This Repository Is](#what-this-repository-is)
- [What This Repository Is Not](#what-this-repository-is-not)
- [Who Should Not Use This Repository](#who-should-not-use-this-repository)
- [How To Use This Repository](#how-to-use-this-repository)
- [Step-by-Step Instructions](#step-by-step-instructions)
  - [1. Prerequisites](#1-prerequisites)
  - [2. Cloning the repo](#2-cloning-the-repo)
  - [3. Bootstrapping Cloud Run](#3-bootstrapping-cloud-run)
  - [4. Deploying the Initial Service](#4-deploying-the-initial-service)
- [Troubleshooting Steps](#troubleshooting-steps)

## What This Repository Is

The purpose of this repo is to provide a _simple_ template repository that will allow you to deploy a `Node.js`-based service with minimal effort. It has a few different features:

1. GCP Project Bootstrap Script - Executes the GCP commands required to set up a new project and outputs the deployment config file used by the GitHub Workflows to actually build and deploy the service.
2. Minimal "functioning" `expressjs` service with some default project configuration (eslint/prettier/vitest/lint-staged/husky).
3. GitHub workflows that will do some standard CI/CD stuff like running the lint check and tests, building and pushing the `Docker` image, and deploying the `Docker` image to `Cloud Run`.

## What This Repository Is Not

This repository is not meant to:

1. Be highly configurable
2. Produce a secure, production-ready service or deployment
3. Be an example of best practices

## Who Should Not Use This Repository

If you are new to Node.js and aren't ready to deal with the hurdles that come with linting and testing requirements, using this template will probably be more frustrating than helpful. It has a non-minimal, opinionated configuration, so unless it just happens to behave exactly as you expect, you're probably going to end up spending a non-negligible amount of time trying to figure out how it's set up and why it's behaving the way it behaves.

## How To Use This Repository

There are two primary use cases for this repository:

1. As an initial template that you use to create your own template that's customized to your liking; and
2. As a template that you use directly.

In the first scenario, you're most likely using the repository for the bootstrapping and deployment workflows and will have to spend some time reconfiguring the project itself to work like you want it (e.g., switch it to `TypeScript`, switch tests to `Jest`, change the linting rules, etc.). If you fall in this category, I will assume you know what you're doing and look through the repository and figure out what's going on. In this case, you'll probably just want to read the section on Bootstrapping Cloud Run and skip the rest.

In the second scenario, you probably want to know how the repository is designed to be used, in which case you should read the Walkthrough as well, where I explain the general workflow that I use. This is not meant as instructions on how _you_ should use it, but merely giving you an idea of how _I_ use it so you can make whatever adjustments you want to suit your own workflow.

## Step-by-Step Instructions

_IMPORTANT:_ The GCP project requires billing to be enabled so you _will_ incur normal GCP-related charges. For the most part, this is limited to Artifact Registry and Cloud Run costs, which should be fairly low for a sample project. I am not responsible for any charges you incur.

### 1. Prerequisites

- Everything needed to work on a `Node.js` project in the first place and enough familiarity that you can look through the repository and figure out what's going on by default.
- Docker installed and setup (for local e2e tests)
- `gcloud` CLI installed (see [here](https://cloud.google.com/sdk/docs/install) for instructions)
- Google application default credentials configured (see [here](https://cloud.google.com/docs/authentication/provide-credentials-adc) for instructions)
- A GCP billing account configured (see [here](https://cloud.google.com/billing/docs/how-to/create-billing-account) for instructions)
- Some general working knowledge of GCP, serverless, Cloud Run, and GitHub workflows is useful.

### 2. Cloning the repo

1. Create a new repository using this one as the template.
2. Clone the new repository to your local machine or wherever you want to do development.

### 3. Bootstrapping Cloud Run

During this process, we will set the configuration we need to bootstrap our Cloud Run service on GCP and then actually perform the bootstrapping. Although the process seems somewhat long, it should only take about ten minutes, and half of that is waiting for the bootstrapping script to set everything up!

1. Open `gcp-config.sh` and
   1. Replace the empty string assigned to the `GITHUB_REPO_PATH` variable with your GitHub repository path (e.g., `username/new-repo-name`).
   1. Replace the empty string assigned to the `SERVICE_NAME` variable with your desired service name.
   1. Replace the empty string assigned to the `PROJECT_NAME` variable with your desired project name.
   1. Replace the empty string assigned to the `BILLING_ACCOUNT_ID` variable with your billing account id (e.g., `3215754-215487-659845`).
   1. Review the other options and update as desired.
   1. Note that these values must conform to GCP requirements; no validation is performed so if they do not then the bootstrapping process may fail in the middle.
2. Navigate to your project directory in the terminal.
3. Run `./bootstrap.sh` to create and configure your new project. This should take a few minutes. At least one command (the creation of the workload identity federation pool) is expected to fail and re-run several times after a waiting period. It should succeed after a minute or so.
4. If the script completes successfully, add, commit, and push the newly generated `deployment/config.yml` file to your remote repository. If it did not, see the troubleshooting steps below.
5. 4. You probably _should not_ commit your updated `gcp-config.sh` file to version control. I don't think there's a likelihood of any issues if you do, but there's probably no reason to do it in the first place.

### 4. Deploying the Initial Service

The previous step deployed a `hello-world` container that Google provides to the service, not the actual service in this repository. Thus, our next step is to actually build and deploy our own service.

1. In your GitHub repositry, go to the `Actions` tab.
2. Click on the `Trigger Build and Deployment` Action, which should be listed on the left side.
3. Click on the `Run workflow` dropdown and, leaving the `main` branch selected, click the `Run workflow` button.
4. When the UI updates and shows the workflow running, click into the running workflow to see the status of the individual jobs.

If all goes well, both the `Build and Push Docker Image` job and the `Deploy Cloud Run` job will run successfully and you should be able to send a `GET` request to your service and get a `JSON` response of `{"hello": "world"}`. To figure out the URL for your newly deployed service, go to `Cloud Run` in the GCP console, click into your service, and the URL should be displayed towards the top.

## Troubleshooting Steps

There are probably a few things that could go wrong during this process, but here are some details of the two most likely:

1. The `bootstrap.sh` script failed to complete - This could be any number of problems from invalid config values in `gcp-config.sh` to permissions issues. Generally, however, whatever fails will give you an indication of what the problem, but it's probably going to require some research to figure out what the root cause is. The bigger problem is that `bootstrap.sh` does not supprt re-trying in the case of failure, so you'll have a project that's not fully set up and you can't really do anything except (1) just delete the project and try again or (2) comment out the commands in `bootstrap.sh` that have run and then re-run it again. The latter actually works really well but generally requires understanding what's going on in the `bootstrap.sh` script. It's not complex but does require some time!

2. The build and deployment jobs failed - This could be for any number of reasons. Again, the error messages should be helpful. The most common problem will likely be that you didn't correctly specify the `GITHUB_REPO_PATH` env var. This should be the same basic structure you see in the URL bar on `github.com` for your repo. E.g., if my username is `mstrofbass` and my repo name is `cloud-run-test`, then the path will be `mstrofbass/cloud-run-test`, just like in the GitHub URL.

To fix this problem, we have to fix the Workload Identity Federation configuration:

1. Go to the GCP Cloud Console > IAM & Admin > Workload Identity Federation
2. You should see a table with your `github` pool listed. Click the link under `Display Name` to go to the pool.
3. When your pool opens up, you should see a section on the right side that has `PROVIDERS` and `CONNECTED SERVICE ACCOUNTS` tabs. `PROVIDERS` should already be selected and should have a table with your `github` provider in it. Click the pencil icon in that row.
4. After the provider page loads, scroll all the way down to where it says `Attribute Conditions`. It should have a value that looks like `assertion.repository_visibility == "private" && assertion.repository in ["GITHUB_REPO_PATH"]` where `GITHUB_REPO_PATH` is what you had in your `gcp-config.sh` file.
5. Update the value in the `GITHUB_REPO_PATH` spot to be the correct path to your GitHub repository.
6. Go back to your GitHub actions and retrigger the `Trigger Build and Deployment` action.

<!-- This is meant to be a simple template suitable for experimentation or creating a more complex template for your specific use case. For example, the Cloud Run service configuration options are minimal, the service is exposed to unauthenticated users and the configuration is probably insecure, and it only deploys to one environment. However, it will allow you to get something workable deployed to `dev` in a few minutes and everything is fairly easy to understand.

This is probably not the best repository to use if you're new to `Node.js` development because it does have some things that might be really annoying while you're learning the basics (e.g., commits will fail if `eslint` can't fix something or a test fails). This is more of a `sane default` based on the configuration I have been using day-to-day. It is also probably not the best, so suggestions are welcome.

Please keep in mind that I'm not an expert in infrastructure and devops stuff, so everything is generally just the simplest way I found to do things and likely not the best. Open an issue or PR if you want to help make it better. With that in mind, please remember that the goal of this repo is to be simple template, not full featured, so I'm not sure doing things like making it highly configurable are as important as making it easier to use and more in line with best practices.

Specific Features:

1. Automatic project creation and configuration via `bootstrap.sh`.
2. Basic, functioning `expressjs` service.
3. `eslint`, `prettier`, and `jest` setup and configured to run automatically on commit via `lint-staged` and `husky`. (This is an "opinionated" configuration only because it's the default configuration that I have been personally using...it's probably not the best!)
4. `lint` workflow that gets triggered on pushes to any branch but `main` and `release` branches and runs the `lint-check` script.
5. `push` workflow that gets triggered on pushes to any branch but `main` and `release` branches and runs the unit tests using both `Node.js` versions 18 and 19.
6. `pull-request` workflow that gets triggered on PR opening and runs the integration tests using both `Node.js` versions 18 and 19. (There are no actual integration tests beyond a placeholder tests currently.)
7. `trigger-docker-deployment` workflow that gets triggered on push to `main` (e.g., by merging a pull request) with some path restrictions (so it doesn't trigger when you update the `push` workflow, for example)
8. `docker-build` workflow that is triggered by the `trigger-docker-deployment` workflow (or manually) and builds the Docker image then pushes it to `Artifact Registry`.
9. `deploy-cloud-run` workflow that is triggered by the `trigger-docker-deployment` workflow when the `docker-build` workflow is successful (or manually) and deploys the Docker image to the Cloud Run service.
10. `e2e` workflow that should be triggered by the `trigger-docker-deployment` workflow (or manually) after deployment and run the `e2e` tests but is currently disabled.
11. Workload Identity Federation for authentication between GitHub and GCP.
12. Workflow configuration via `deployment/config.yml`, which gets automatically generated based on your `gcp-config.sh` config.

Some enhancements that I think might be worthwhile:

1. Anything to make the basic configuration more secure (besides turning off unauthenticated access unless there's another way to make it easily accessible to the developer). First on the list is probably updating the Workload Identity Federation attribute condition to only allow specific users to authenticate.
2. e2e test skeleton
3. Creation and deployment to multiple environments (at least having the GitHub workflows for it)
4. GCP configuration validation (e.g., ensuring that the values in `gcp-config.sh` are valid)
5. Allow the `bootstrap.sh` script to be used on an existing project.
6. Docker image caching for building (maybe?)
7. Node.js project setup (I don't actually know what the best project setup is, this is just what I've settled on for the time being.)

## Prerequisites:

1. Everything needed to work on a `Node.js` project in the first place and enough familiarity that you can look through the repository and figure out what's going on by default.
2. `gcloud` CLI installed (see [here](https://cloud.google.com/sdk/docs/install) for instructions)
3. Google application default credentials configured (see [here](https://cloud.google.com/docs/authentication/provide-credentials-adc) for instructions)
4. A GCP billing account configured (see [here](https://cloud.google.com/billing/docs/how-to/create-billing-account) for instructions)
5. Some general working knowledge of GCP, serverless, Cloud Run, and GitHub workflows is useful.





### Continued Development

If you continue using the repository for development, the general things to be aware of are the following:

1. `eslint`, `prettier`, and `jest` are run every time you commit, so if any of these fails (e.g., any `eslint` rule is broken or test fails), you will not be able to commit.
2. The only real test is a unit test for the minimal `handleRequest` function. Any change to that function will break the test.
3. The `unit` tests are run on `push`, any `integration` tests you add will be run on the opening of a pull request, and any `e2e` tests you write will not run automatically because I don't have that configured yet.
4. The general idea for the `e2e` tests is to have the URL to the service stored in an environment variable and then have that environment variable set in the `e2e` workflow.
5. The whole project is set up with the expectation that code will be merged to main _by pull request only_.
1. Update the service name in the docker-compose file
6. When you merge source code to `main` that meets any of the following patterns, the Docker image will automatically be built and deployed. If you want other things to trigger a build and deployment, you need to update the `.github/workflows/trigger-docker-deployment.yml` file.
   a. app.js
   c. src/\*\*
   d. package-lock.json -->
