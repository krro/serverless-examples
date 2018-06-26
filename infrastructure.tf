provider "aws" {
  profile = "krro"
  region  = "eu-west-1"
}

resource "aws_lambda_function" "serverless-lambda" {
  filename         = "build/libs/serverless-all.jar"
  function_name    = "serverless"
  role             = "${aws_iam_role.serverless-role.arn}"
  handler          = "pl.krro.Handler::handleRequest"
  source_code_hash = "${base64sha256(file("build/libs/serverless-all.jar"))}"
  runtime          = "java8"
}

resource "aws_iam_role" "serverless-role" {
  name = "serverless-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "serverless-rest-api" {
  name        = "ServerlessRestAPI"
  description = "Serverless Application Example"
}

resource "aws_api_gateway_resource" "serverless-proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-rest-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.serverless-rest-api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "serverless-proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.serverless-rest-api.id}"
  resource_id   = "${aws_api_gateway_resource.serverless-proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "serverless-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-rest-api.id}"
  resource_id = "${aws_api_gateway_method.serverless-proxy.resource_id}"
  http_method = "${aws_api_gateway_method.serverless-proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.serverless-lambda.invoke_arn}"
}

resource "aws_api_gateway_method" "serverless-proxy-root" {
  rest_api_id   = "${aws_api_gateway_rest_api.serverless-rest-api.id}"
  resource_id   = "${aws_api_gateway_rest_api.serverless-rest-api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "serverless-integration-root" {
  rest_api_id = "${aws_api_gateway_rest_api.serverless-rest-api.id}"
  resource_id = "${aws_api_gateway_method.serverless-proxy-root.resource_id}"
  http_method = "${aws_api_gateway_method.serverless-proxy-root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.serverless-lambda.invoke_arn}"
}

resource "aws_api_gateway_deployment" "serverless-deployment" {
  depends_on = [
    "aws_api_gateway_integration.serverless-integration",
    "aws_api_gateway_integration.serverless-integration-root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.serverless-rest-api.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "serverless-permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.serverless-lambda.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.serverless-deployment.execution_arn}/*/*"
}
