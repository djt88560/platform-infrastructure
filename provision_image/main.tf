provider "aws" {
  region = "eu-west-2"
}

resource "aws_apprunner_service" "service" {
  service_name = "template"
  source_configuration {
    image_repository {
      image_identifier = var.image
      image_repository_type = "ECR_PUBLIC"
      image_configuration {  
        port = "80"
      }
    } 
    auto_deployments_enabled = false
  }
}