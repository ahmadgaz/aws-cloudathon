terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3             = "http://s3.localhost.localstack.cloud:4566"
    dynamodb       = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    sts            = "http://localhost:4566"
    iam            = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    route53        = "http://localhost:4566"
    logs           = "http://localhost:4566"
    events         = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    wafv2          = "http://localhost:4566"
    ecr            = "http://localhost:4566"
    ecs            = "http://localhost:4566"
    efs            = "http://localhost:4566"
    eks            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    cloudfront     = "http://localhost:4566"
    cloudtrail     = "http://localhost:4566"
    codecommit     = "http://localhost:4566"
    codebuild      = "http://localhost:4566"
    codepipeline   = "http://localhost:4566"
    elasticsearch  = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    kms            = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    sagemaker      = "http://localhost:4566"
    swf            = "http://localhost:4566"
    xray           = "http://localhost:4566"
  }
}

provider "aws" {
  alias                       = "us_east_1"
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3             = "http://s3.localhost.localstack.cloud:4566"
    dynamodb       = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    sts            = "http://localhost:4566"
    iam            = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    route53        = "http://localhost:4566"
    logs           = "http://localhost:4566"
    events         = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    wafv2          = "http://localhost:4566"
    ecr            = "http://localhost:4566"
    ecs            = "http://localhost:4566"
    efs            = "http://localhost:4566"
    eks            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    cloudfront     = "http://localhost:4566"
    cloudtrail     = "http://localhost:4566"
    codecommit     = "http://localhost:4566"
    codebuild      = "http://localhost:4566"
    codepipeline   = "http://localhost:4566"
    elasticsearch  = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    kms            = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    sagemaker      = "http://localhost:4566"
    swf            = "http://localhost:4566"
    xray           = "http://localhost:4566"
  }
}

provider "aws" {
  alias                       = "us_west_2"
  region                      = "us-west-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3             = "http://s3.localhost.localstack.cloud:4566"
    dynamodb       = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    sts            = "http://localhost:4566"
    iam            = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    route53        = "http://localhost:4566"
    logs           = "http://localhost:4566"
    events         = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    wafv2          = "http://localhost:4566"
    ecr            = "http://localhost:4566"
    ecs            = "http://localhost:4566"
    efs            = "http://localhost:4566"
    eks            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    cloudfront     = "http://localhost:4566"
    cloudtrail     = "http://localhost:4566"
    codecommit     = "http://localhost:4566"
    codebuild      = "http://localhost:4566"
    codepipeline   = "http://localhost:4566"
    elasticsearch  = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    kms            = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    sagemaker      = "http://localhost:4566"
    swf            = "http://localhost:4566"
    xray           = "http://localhost:4566"
  }
} 