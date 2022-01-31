terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "3.72.0"
      }
    }
  
    backend "s3" {
      bucket     = "terraform-my-task"
      key        = "AKIA2O32GJVFMI5I3KHH"
      region     = "eu-central-1"
    }
}
  
provider "aws" {
profile = "default"
region  = "eu-central-1"
}
  
# IAM Role Policy For Lambda
resource "aws_iam_role_policy" "lambda_policy" {
    name = "lambda_policy"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
            "Action": [
                    "s3:*",
                    "s3-object-lambda:*"
                ],
            "Effect": "Allow",
            "Sid"       = ""
            "Resource": [
                "arn:aws:s3:::${var.bucket_name}",
                "arn:aws:s3:::${var.bucket_name}/*",
                ]
            },
            {
            "Sid": "",
            "Action": "cloudwatch:*",
            "Effect": "Allow",
            "Resource": "*"
            },
            {
            "Sid": "",
            "Action": "logs:*",
            "Effect": "Allow",
            "Resource": "*"
            }
        ]
    })
}

  
# IAM Role For Lambda
resource "aws_iam_role" "lambda_role" {
    name = "lambda_role"

    assume_role_policy = jsonencode({
        Version     = "2012-10-17"
        Statement   = [
        {
            Action      = "sts:AssumeRole"
            Effect      = "Allow"
            "Sid"       = ""
            Principal   = {
            Service   = "lambda.amazonaws.com"
            }
        },
        ]
    })
}
  
locals {
    lambda_zip_location = "output/index.zip"
}
  
# Zip the Lamda function
data "archive_file" "source" {
    type             = "zip"
    source_file      = "index.js"
    output_path      = "${local.lambda_zip_location}"
}
  
# AWS Lambda Function
resource "aws_lambda_function" "lambda_function" {
    function_name     = "${var.lambda_function_name}"
    handler           = "index.handler"  
    s3_bucket         = var.bucket_name
    s3_key            = "${aws_s3_bucket_object.object.key}"
    role              = "${aws_iam_role.lambda_role.arn}"
    runtime           = "nodejs14.x"
    source_code_hash  = "${base64sha256(local.lambda_zip_location)}"
}
  
# AWS API Gateway
resource "aws_apigatewayv2_api" "lambda_api" {
    name          = "upload-image"
    protocol_type = "HTTP"
}
  
resource "aws_apigatewayv2_stage" "lambda_stage" {
    api_id        = aws_apigatewayv2_api.lambda_api.id
    name          = "$default"
    auto_deploy   = true
}
  
resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id               = aws_apigatewayv2_api.lambda_api.id
    integration_type     = "AWS_PROXY"
    integration_method   = "POST"
    integration_uri      = aws_lambda_function.lambda_function.invoke_arn
    passthrough_behavior = "WHEN_NO_MATCH"
}
  
resource "aws_apigatewayv2_route" "lambda_route" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /upload-image"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
  
resource "aws_lambda_permission" "api_gw" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = "${var.lambda_function_name}"
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"

    depends_on = [
        aws_lambda_function.lambda_function
    ]
}
  
# Upload zip file to S3 bucket
resource "aws_s3_bucket_object" "object" {
    bucket    = var.bucket_name
    key       = "idex.zip"
    source    = "${data.archive_file.source.output_path}" # its mean it depended on zip
    etag      = filemd5("${data.archive_file.source.output_path}")
}