
##
## GLOBAL
##


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.8.0"
    }

  }
}
provider "aws" {
  region  = "eu-central-1"
}
provider "archive" {
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


##
## LAMBDA
##


resource "aws_iam_role" "role_lambda_book" {
  name = "role_lambda_book"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: "lambda.amazonaws.com"
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "role_lambda_book_policy" {
  name = "role_lambda_book_policy"
  role = aws_iam_role.role_lambda_book.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        Effect: "Allow",
        Action: "logs:CreateLogGroup",
        Resource: "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/book-res:*"
        ]
      },
      {
        Effect: "Allow",
        Action: [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ],
        Resource: [
          aws_dynamodb_table.book_dynamodb_table.arn
        ]
      }
    ]
  })
}

## read endpoint

data "archive_file" "book_read_lambda_zip" {
  type = "zip"
  output_path = "book-read-lambda.zip"
  source_file = "lambda-read.js"

}

resource "aws_lambda_function" "book_read_lambda" {
  filename            = "book-read-lambda.zip"
  source_code_hash    = data.archive_file.book_read_lambda_zip.output_base64sha256
  function_name       = "book-read"
  role                = aws_iam_role.role_lambda_book.arn
  handler             = "lambda-read.handler"
  runtime             = "nodejs14.x"

  depends_on = [
    data.archive_file.book_read_lambda_zip
  ]
}


## write endpoint

data "archive_file" "book_write_lambda_zip" {
  type = "zip"
  output_path = "book-write-lambda.zip"
  source_file = "lambda-write.js"

}

resource "aws_lambda_function" "book_write_lambda" {
  filename            = "book-write-lambda.zip"
  source_code_hash    = data.archive_file.book_write_lambda_zip.output_base64sha256
  function_name       = "book-write"
  role                = aws_iam_role.role_lambda_book.arn
  handler             = "lambda-write.handler"
  runtime             = "nodejs14.x"

  depends_on = [
    data.archive_file.book_write_lambda_zip
  ]
}


##
## API GATEWAY
##


resource "aws_api_gateway_rest_api" "book_api_gateway" {
  name = "book_api_gateway"
}

resource "aws_api_gateway_resource" "book_api_gateway_resource" {
  parent_id   = aws_api_gateway_rest_api.book_api_gateway.root_resource_id
  path_part   = "book"
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id
}


## GET

resource "aws_api_gateway_method" "book_api_gateway_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.book_api_gateway_resource.id
  rest_api_id   = aws_api_gateway_rest_api.book_api_gateway.id
  request_parameters = {
    "method.request.querystring.userid" = true
  }
}

resource "aws_api_gateway_integration" "book_api_gateway_get_integration" {
  http_method = aws_api_gateway_method.book_api_gateway_get.http_method
  resource_id = aws_api_gateway_resource.book_api_gateway_resource.id
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.book_read_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" = <<EOF
##  See http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html
##  This template will pass through all parameters including path, querystring, header, stage variables, and context through to the integration endpoint via the body/payload
#set($allParams = $input.params())
{
"body-json" : $input.json('$'),
"params" : {
#foreach($type in $allParams.keySet())
    #set($params = $allParams.get($type))
"$type" : {
    #foreach($paramName in $params.keySet())
    "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
        #if($foreach.hasNext),#end
    #end
}
    #if($foreach.hasNext),#end
#end
},
"stage-variables" : {
#foreach($key in $stageVariables.keySet())
"$key" : "$util.escapeJavaScript($stageVariables.get($key))"
    #if($foreach.hasNext),#end
#end
},
"context" : {
    "account-id" : "$context.identity.accountId",
    "api-id" : "$context.apiId",
    "api-key" : "$context.identity.apiKey",
    "authorizer-principal-id" : "$context.authorizer.principalId",
    "caller" : "$context.identity.caller",
    "cognito-authentication-provider" : "$context.identity.cognitoAuthenticationProvider",
    "cognito-authentication-type" : "$context.identity.cognitoAuthenticationType",
    "cognito-identity-id" : "$context.identity.cognitoIdentityId",
    "cognito-identity-pool-id" : "$context.identity.cognitoIdentityPoolId",
    "http-method" : "$context.httpMethod",
    "stage" : "$context.stage",
    "source-ip" : "$context.identity.sourceIp",
    "user" : "$context.identity.user",
    "user-agent" : "$context.identity.userAgent",
    "user-arn" : "$context.identity.userArn",
    "request-id" : "$context.requestId",
    "resource-id" : "$context.resourceId",
    "resource-path" : "$context.resourcePath"
    }
}
EOF
  }
}

resource "aws_lambda_permission" "apigw_read_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.book_read_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.book_api_gateway.id}/*/${aws_api_gateway_method.book_api_gateway_get.http_method}${aws_api_gateway_resource.book_api_gateway_resource.path}"
}

resource "aws_api_gateway_method_response" "book_api_gateway_get_method_response" {
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id
  resource_id = aws_api_gateway_resource.book_api_gateway_resource.id
  http_method = aws_api_gateway_method.book_api_gateway_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "book_api_gateway_get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id
  resource_id = aws_api_gateway_resource.book_api_gateway_resource.id
  http_method = aws_api_gateway_method.book_api_gateway_get.http_method
  status_code = aws_api_gateway_method_response.book_api_gateway_get_method_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.book_api_gateway_get_integration
  ]
}

## POST

resource "aws_api_gateway_method" "book_api_gateway_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.book_api_gateway_resource.id
  rest_api_id   = aws_api_gateway_rest_api.book_api_gateway.id
}

resource "aws_api_gateway_integration" "book_api_gateway_post_integration" {
  http_method = aws_api_gateway_method.book_api_gateway_post.http_method
  resource_id = aws_api_gateway_resource.book_api_gateway_resource.id
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.book_write_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" = <<EOF
##  See http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html
##  This template will pass through all parameters including path, querystring, header, stage variables, and context through to the integration endpoint via the body/payload
#set($allParams = $input.params())
{
"body-json" : $input.json('$'),
"params" : {
#foreach($type in $allParams.keySet())
    #set($params = $allParams.get($type))
"$type" : {
    #foreach($paramName in $params.keySet())
    "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
        #if($foreach.hasNext),#end
    #end
}
    #if($foreach.hasNext),#end
#end
},
"stage-variables" : {
#foreach($key in $stageVariables.keySet())
"$key" : "$util.escapeJavaScript($stageVariables.get($key))"
    #if($foreach.hasNext),#end
#end
},
"context" : {
    "account-id" : "$context.identity.accountId",
    "api-id" : "$context.apiId",
    "api-key" : "$context.identity.apiKey",
    "authorizer-principal-id" : "$context.authorizer.principalId",
    "caller" : "$context.identity.caller",
    "cognito-authentication-provider" : "$context.identity.cognitoAuthenticationProvider",
    "cognito-authentication-type" : "$context.identity.cognitoAuthenticationType",
    "cognito-identity-id" : "$context.identity.cognitoIdentityId",
    "cognito-identity-pool-id" : "$context.identity.cognitoIdentityPoolId",
    "http-method" : "$context.httpMethod",
    "stage" : "$context.stage",
    "source-ip" : "$context.identity.sourceIp",
    "user" : "$context.identity.user",
    "user-agent" : "$context.identity.userAgent",
    "user-arn" : "$context.identity.userArn",
    "request-id" : "$context.requestId",
    "resource-id" : "$context.resourceId",
    "resource-path" : "$context.resourcePath"
    }
}
EOF
  }
}

resource "aws_lambda_permission" "apigw_write_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.book_write_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.book_api_gateway.id}/*/${aws_api_gateway_method.book_api_gateway_post.http_method}${aws_api_gateway_resource.book_api_gateway_resource.path}"
}

resource "aws_api_gateway_method_response" "book_api_gateway_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id
  resource_id = aws_api_gateway_resource.book_api_gateway_resource.id
  http_method = aws_api_gateway_method.book_api_gateway_post.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "book_api_gateway_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id
  resource_id = aws_api_gateway_resource.book_api_gateway_resource.id
  http_method = aws_api_gateway_method.book_api_gateway_post.http_method
  status_code = aws_api_gateway_method_response.book_api_gateway_post_method_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.book_api_gateway_post_integration
  ]
}

resource "aws_api_gateway_deployment" "book_api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.book_api_gateway.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.book_api_gateway_resource.id,
      aws_api_gateway_method.book_api_gateway_get.id,
      aws_api_gateway_integration.book_api_gateway_get_integration.id,
      aws_api_gateway_method.book_api_gateway_post.id,
      aws_api_gateway_integration.book_api_gateway_post_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_resource.book_api_gateway_resource,
    aws_api_gateway_method.book_api_gateway_get,
    aws_api_gateway_integration.book_api_gateway_get_integration,
    aws_api_gateway_method_response.book_api_gateway_get_method_response,
    aws_api_gateway_integration_response.book_api_gateway_get_integration_response,
    aws_api_gateway_method.book_api_gateway_post,
    aws_api_gateway_integration.book_api_gateway_post_integration,
    aws_api_gateway_method_response.book_api_gateway_post_method_response,
    aws_api_gateway_integration_response.book_api_gateway_post_integration_response
  ]
}

resource "aws_api_gateway_stage" "book_api_gateway_state" {
  deployment_id = aws_api_gateway_deployment.book_api_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.book_api_gateway.id
  stage_name    = "prod"
}

##
## CORS
##

module "cors" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.book_api_gateway.id
  api_resource_id = aws_api_gateway_resource.book_api_gateway_resource.id

  allow_methods = ["GET", "POST"]
}

##
## DYNAMODB
##

resource "aws_dynamodb_table" "book_dynamodb_table" {
  name           = "book"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userid"

  attribute {
    name = "userid"
    type = "S"
  }

}

##
##
##

resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "example" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

data "aws_acm_certificate" "amazon_issued_oglimmer_cert" {
  domain      = "*.oglimmer.de"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}


resource "aws_api_gateway_domain_name" "book_api_gateway_domainname" {
  domain_name              = "mega-api.oglimmer.de"
  regional_certificate_arn = data.aws_acm_certificate.amazon_issued_oglimmer_cert.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "book_api_gateway_domainname_mapping" {
  api_id      = aws_api_gateway_rest_api.book_api_gateway.id
  stage_name  = aws_api_gateway_stage.book_api_gateway_state.stage_name
  domain_name = aws_api_gateway_domain_name.book_api_gateway_domainname.domain_name
}


##
## OUTPUTS
##


output "book-rest-api-endpoint" {
  value = aws_api_gateway_stage.book_api_gateway_state.invoke_url
}

output "book-rest-api-endpoint-domain" {
  value = aws_api_gateway_domain_name.book_api_gateway_domainname.regional_domain_name
}


##
## DIGITAL OCEAN - DNS
##

variable "do_api_token" {}

provider "digitalocean" {
  token = var.do_api_token
}

data "digitalocean_domain" "do_domain_oglimmer" {
  name = "oglimmer.de"
}

resource "digitalocean_record" "do_domain_oglimmer_megaapi" {
  domain = data.digitalocean_domain.do_domain_oglimmer.name
  type   = "CNAME"
  name   = "mega-api"
  value  = "${aws_api_gateway_domain_name.book_api_gateway_domainname.regional_domain_name}."
  ttl = 60
}
