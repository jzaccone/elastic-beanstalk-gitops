#!/bin/bash

EB_STACK_PREFIX="springboot-eb-"
PIPELINE_PREFIX="spring-gitops-"
PIPELINE_STACK_POSTFIX="-pipeline"

for deletedFolder in $(git diff-tree --diff-filter=D --name-only  HEAD~1 HEAD) ; do
    EB_STACK=${EB_STACK_PREFIX}${deletedFolder} 
    PIPELINE_STACK=${PIPELINE_PREFIX}${deletedFolder}${PIPELINE_STACK_POSTFIX}

    echo "Deleting EB stack for $deletedFolder"
    aws cloudformation delete-stack --stack-name ${EB_STACK}
    
    echo "Waiting for EB stack deletion to be completed for $deletedFolder"
    aws cloudformation wait stack-delete-complete --stack-name ${EB_STACK} 

    echo "Deleting pipeline stack for $deletedFolder" 
    aws cloudformation delete-stack --stack-name $PIPELINE_STACK
    aws cloudformation wait stack-delete-complete --stack-name $PIPELINE_STACK 
    aws cloudformation delete-stack --stack-name $PIPELINE_STACK  --retain-resources "ArtifactStoreBucket"
done