The git repo is the core of the “GitOps” workflow. Following GitOps we use a git repository as the single source of truth for the state of environments. 

This repo contains 

“common” → cloud formation templates to create/update environments. Also includes cloud formation templates for the deployment pipelines.

“development”, “prod”, “featureX” (Environment specific folders) → configuration files that include the application version (image tag or other artifact identifier that points to something in an artifact store such as S3) that are provided as input for the cloud formation templates. Each environment folder will map to its own deploy pipeline and (Elastic Beanstalk) environment. 

 “.github/workflows” → GitHub actions workflows that trigger upon pushes to the Main branch of the repo. The workflow script will figure out which environment folders have changed and will trigger (or create) the appropriate execution deploy pipeline.

Part of the configuration in each environment folder will include the application version tag for a deployable artifact in S3, docker registry or other artifact store. This artifact is the hand-off between the build and deploy process. The cloud formation templates that are executed during the deployment pipeline will take the identifier as input and should know how to download and deploy the artifact.

Details about the Github Action Workflows

Action: Trigger or create deployment pipeline action → Listen to pushes, figures out which environment folder changed and triggers checks if the deploy pipeline exists.

if pipeline exists → triggers CodePipeline by name using aws codepipeline start-pipeline-execution --name [pipeline-name].

if pipeline doesn’t exist → runs aws cloudformation create-stack to create a new CodePipeline for each new environments using cloud formation templates from the common folder. Once the pipeline is created from cloud formation, it will run for the first time automatically.

Action: Delete environment and pipeline action → Listen to pushes, figures out deleted environment folders, runs aws cloudformation delete-stack for both the environment and the pipeline

Benefits of doing it using a GitOps workflow.

Version control over the changes of the desired state in our environments, 

Visibility over what app version is running in which environment

Easy way to update environments by simply changing the configuration file. Promote dev → prod by doing a simple cp. 

Create or delete environments quickly by adding or removing folders in this repo. All the automation is taken care of in the GitHub actions workflow and the deploy pipeline that is triggered downstream.

GitOps tools are widely available for Kubernetes such as ArgoCD that sync git repository and environments and show state between those two targets (“in sync” or “out of sync”). ArgoCD can detect changes from github, or the environments (environment drift). Environment drift can be detected in Cloud Formation with drift detection, but it is not done for you automatically.
