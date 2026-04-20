# platform-infrastructure
A sibling repository to service-template. This repo should provide the functionality to deploy the docker container into the cloud



# Runbook
- Create a user called programmaticAccess
- Give it admin privileges
- create an access key and secret
- Go to Aws configure on the command line enter those details on your machine
- Verify the identity with aws sts get-caller-identity
- initialise and apply terraform with your image
- go on to ecs on aws and find your cluster (make sure you are in the us-east-1 region)
- terraform destroy with the image name when you are done
