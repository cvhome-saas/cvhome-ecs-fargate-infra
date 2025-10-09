module "proxy_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.name
  handler       = "index.lambda_handler"
  runtime       = "python3.12"

  environment_variables = {
    PROXY_URL = var.proxy_url
  }

  source_path = "./common/proxy-lambda/src"
}

# API Gateway HTTP API to invoke the Lambda
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name               = "${var.name}-api"
  description        = "API Gateway for ${var.name} Lambda proxy"
  protocol_type      = "HTTP"
  create_domain_name = false
  
  # Route for the Lambda
  routes = {
    "ANY /{proxy+}" = {
      integration = {
        type = "AWS_PROXY"
        uri  = module.proxy_lambda.lambda_function_arn
      }
    }
  }
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.proxy_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

