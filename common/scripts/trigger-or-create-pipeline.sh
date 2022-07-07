#!/bin/bash
CF_DIR="common/cloudformation"

PIPELINE="pipeline.yaml"
PIPELINE_PREFIX="spring-gitops-"
PIPELINE_STACK_POSTFIX="-pipeline"

EB_STACK="eb-stack.yaml"
EB_STACK_CONFIG="stack-config.json"
EB_STACK_PREFIX="springboot-eb-"


for ENV_DIR in $(ls -d */| sed 's:/*$::') ; do
  # Skip the common branch with common resources
  if [ "$ENV_DIR" = "common" ]; then
    continue
  fi

  PIPELINE_NAME="${PIPELINE_PREFIX}${ENV_DIR}"
  PIPELINE_CONFIG_COPY="pipeline-config-${ENV_DIR}.json"
  STACK_NAME=${PIPELINE_NAME}${PIPELINE_STACK_POSTFIX}
  EB_STACK_NAME=${EB_STACK_PREFIX}${ENV_DIR}

  echo "Checking for changes in $ENV_DIR"
  git diff --quiet HEAD~1 HEAD -- $ENV_DIR
  if [ ! $? -eq 0 ] 
  then
    echo "Detected changes in the $ENV_DIR branch."

    echo "Checking if pipeline $PIPELINE_NAME exists"
    PIPELINE_EXISTS=false
    for pipeline in `aws codepipeline list-pipelines | yq '.pipelines[].name'`; do
      if [ "$pipeline" = "$PIPELINE_NAME" ]; then
        PIPELINE_EXISTS=true
        break
      fi
    done

    if [ ! "$PIPELINE_EXISTS" = true ] ; then
      echo "The pipeline $PIPELINE_NAME does not exist, creating it..."

      cp ${CF_DIR}/pipeline-config.json $PIPELINE_CONFIG_COPY

      sed -i "s@PIPELINE_NAME@$PIPELINE_NAME@g" $PIPELINE_CONFIG_COPY
      sed -i "s@STACK_TEMPLATE_FILE@${CF_DIR}/${EB_STACK}@g" $PIPELINE_CONFIG_COPY
      sed -i "s@STACK_CONFIG_FILE@${ENV_DIR}/${EB_STACK_CONFIG}@g" $PIPELINE_CONFIG_COPY
      sed -i "s@STACK_NAME@${EB_STACK_NAME}@g" $PIPELINE_CONFIG_COPY

      echo "Pipeline Config:"
      cat $PIPELINE_CONFIG_COPY

      aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body "file://$(pwd)/${CF_DIR}/${PIPELINE}" --parameters "file://$(pwd)/${PIPELINE_CONFIG_COPY}" --capabilities CAPABILITY_NAMED_IAM 
      if [ ! $? -eq 0 ] 
      then
        echo "something went wrong"
        exit -1
      fi
      
      echo "A CF stack to create the pipeline has been created. The pipeline will trigger automatically after creation."

    else
      echo "The pipeline $PIPELINE_NAME exists, triggering the pipeline!"
      aws codepipeline start-pipeline-execution --name $PIPELINE_NAME
      if [ ! $? -eq 0 ] 
      then
        echo "something went wrong"
        exit -1
      fi
    fi

  fi
done