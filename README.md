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


# Load Balancer
I have added a load balancer to give a single stable entrypoint to the app via DNS
Before, I had to ask for the correct ip and port, and the ip could change if the app crashes
Go to EC2-Load Balancers to find the DNS namae

# Creating an s3 bucket on aws for destroying resources
- When creating a gha workflow to destroy the infrastructure, it must read from the terraform state file. This file must therefore be available remotely to be updated by and accessed from both workflows. Therefore an S3 bucket must be created. This can be achieved on aws by searching for "S3" and selecting "create bucket"
