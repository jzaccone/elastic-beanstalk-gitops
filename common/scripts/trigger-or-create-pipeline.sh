#!/bin/bash
for DIR_NAME in $(ls -d */| sed 's:/*$::') ; do
  # Skip the common branch with common resources
  if [ "$DIR_NAME" = "common" ]; then
    continue
  fi

  git diff --quiet HEAD~1 HEAD -- $DIR_NAME
  if [ ! $? -eq 0 ] 
  then
    echo "Detected changes in the $DIR_NAME branch."

    # Name convention
    PIPELINE_NAME="spring-gitops-${DIR_NAME}"
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

      PIPELINE_CONFIG_COPY="pipeline-config-${DIR_NAME}.json"
      cp common/pipeline-config.json $PIPELINE_CONFIG_COPY

      sed -i '' "s@PIPELINE_NAME@$PIPELINE_NAME@g" $PIPELINE_CONFIG_COPY
      sed -i '' "s@STACK_TEMPLATE_FILE@common/cloudformation.yaml@g" $PIPELINE_CONFIG_COPY
      sed -i '' "s@STACK_CONFIG_FILE@${DIR_NAME}/stack-config.json@g" $PIPELINE_CONFIG_COPY
      sed -i '' "s@STACK_NAME@spring-eb-${DIR_NAME}@g" $PIPELINE_CONFIG_COPY

      echo "Pipeline Config:"
      cat $PIPELINE_CONFIG_COPY

      aws cloudformation create-stack --stack-name ${PIPELINE_NAME}-pipeline --template-body "file://$(pwd)/common/pipeline.yaml" --parameters "file://$(pwd)/${PIPELINE_CONFIG_COPY}" --capabilities CAPABILITY_NAMED_IAM 
      if [ ! $? -eq 0 ] 
      then
        echo "something went wrong"
        exit -1
      fi
      
      echo "A CFT to create the stack has been created. The pipeline will trigger automatically after creation."

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