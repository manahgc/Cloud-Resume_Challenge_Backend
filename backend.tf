#------------------------------------------------
# Dynamo DB
#------------------------------------------------

resource "aws_dynamodb_table" "cloud_resume_views_counter" {
  name           = "Cloudresumeviews"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"
  

  attribute {
    name = "Id"
    type = "N"
  }

}

resource "aws_dynamodb_table_item" "views_item" {
  table_name = aws_dynamodb_table.cloud_resume_views_counter.name
  hash_key   = aws_dynamodb_table.cloud_resume_views_counter.hash_key

item = <<ITEM
{
  "Id": {"N": "0"},
  "views": {"N": "0"}
}
ITEM
}


#--------------------------------------------------------------------
# Lambda Views Counter Function
#-----------------------------------------------------------------

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "LambdaRoleTrustPolicy"
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        }
        "Action": "sts:AssumeRole"

      }
    ]
  })
}

resource "aws_iam_policy" "lambda_role_policy_for_resume_project" {
  name = "lambda_execution_role_policy"
  description = "Policy for lambda execution role"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
			      "dynamodb:GetItem",
            "dynamodb:PutItem"
          ],
          "Resource" : "arn:aws:dynamodb:*:*:table/Cloudresumeviews"
        },
      ]
  })
}


resource "aws_iam_role_policy_attachment" "cloud_resume_lambda_policy_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_role_policy_for_resume_project.arn
}

resource "aws_lambda_function" "cloud_resume_vist_counter" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.archive_file.lambda.output_path
  function_name = "resume_views_counter"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "viewscounter.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime = "python3.8"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/viewscounter.py"
  output_path = "${path.module}/lambda/viewscounter.zip"
}

resource "aws_lambda_function_url" "url1" {
  function_name      = aws_lambda_function.cloud_resume_vist_counter.function_name
  authorization_type = "NONE"

  # cors {
  #   allow_credentials = true
  #   allow_origins     = ["*"]
  #   allow_methods     = ["*"]
  #   allow_headers     = ["date", "keep-alive"]
  #   expose_headers    = ["keep-alive", "date"]
  #   max_age           = 86400
  # }
}

#---------------------------------------------------------------------------------
# Lambda contact form email function
#--------------------------------------------------------------------------------

resource "aws_iam_role" "send_email_function" {
  name = "send_email_function_role"
  assume_role_policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement": [
        {
          "Sid": "RoleTrustPolicy",
          "Effect": "Allow",
          "Principal": {
            "Service" : "lambda.amazonaws.com"
          }
          "Action" : "sts:AssumeRole"
        }

      ]
  })
}

resource "aws_iam_policy" "send_email_function_role_policy" {
  name = "send_email_function_policy"
  description = "send email lambda function role policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "LoggingPolicy",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Sid" : "SendEmailLambdaPolicy",
        "Effect" : "Allow",
        "Action": [
          "ses:SendEmail"
        ],
        "Resource" : "arn:aws:ses:*:*:identity/charlesmanah.gc@gmail.com"

      },
       {
        "Sid" : "SendEmailLambdaPolicy2",
        "Effect" : "Allow",
        "Action": [
          "ses:SendEmail"
        ],
        "Resource" : "arn:aws:ses:*:*:identity/manahcharles@yahoo.com"

      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "name" {
  role = aws_iam_role.send_email_function.name
  policy_arn = aws_iam_policy.send_email_function_role_policy.arn
}

data "archive_file" "lambda_send_email" {
  type        = "zip"
  source_file = "${path.module}/lambda/email.py"
  output_path = "${path.module}/lambda/email.zip"
}

resource "aws_lambda_function" "contact_form_send_email" {
  filename      = data.archive_file.lambda_send_email.output_path
  function_name = "contact_form_send_email"
  role          = aws_iam_role.send_email_function.arn
  handler       = "email.lambda_handler"
  source_code_hash = data.archive_file.lambda_send_email.output_base64sha256
  runtime = "python3.8"
}

resource "aws_lambda_function_url" "name" {
  function_name      = aws_lambda_function.contact_form_send_email.function_name
  authorization_type = "NONE"

  # cors {
  # allow_credentials = true
  # allow_origins     = ["*"]
  # allow_methods     = ["POST", "OPTIONS"]
  # allow_headers     = ["date", "keep-alive"]
  # expose_headers    = ["keep-alive", "date"]
  # max_age           = 86400
  # }
}
#------------------------------------------------------------------------
# Simple Email Service
#----------------------------------------------------------------------

resource "aws_ses_email_identity" "my_yahoomail" {
  email = "manahcharles@yahoo.com"
}

resource "aws_ses_email_identity" "my_gmail" {
  email = "charlesmanah.gc@gmail.com"
  
}

#----------------------------------------------------------------------
# API GATEWAY ACCOUNT
#---------------------------------------------------------------------
resource "aws_iam_role" "cloudwatch_role" {
  name = "Cloud_watch_role"
  description = "I am role for cloudwatch actions"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
      "Sid" : "CloudWatchRoleTrustPolicy",
      "Effect" : "Allow",
      "Principal" : {
        "Service": "apigateway.amazonaws.com"
        },
      "Action" : "sts:AssumeRole"
    }
    ]
  })
  
}

resource "aws_iam_policy" "cloudwatch_role_policy" {
  name = "Cloud_watch_role"
  description = "Cloudwatch role policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "CloudWatchRolePolicy",
        "Effect" : "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
        ],
        "Resource" : "*"
      }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "cloud_watch_role" {
  role = aws_iam_role.cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_role_policy.arn
  
}

resource "aws_api_gateway_account" "cloud_resume" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch_role.arn

  
}

resource "aws_cloudwatch_log_group" "api_gateway_prod_stage" {
    name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.views_counter.id}/prod"
    retention_in_days = 7

}
#--------------------------------------------------------------------------
# API Gateway
#----------------------------------------------------------------------

# API Gateway
resource "aws_api_gateway_rest_api" "views_counter" {
  name = "views"
  description = "cloud resume views counter api"
}

resource "aws_api_gateway_resource" "views_resource" {
  path_part   = "views"
  parent_id   = aws_api_gateway_rest_api.views_counter.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.views_counter.id
}

resource "aws_api_gateway_resource" "email_resource" {
  path_part = "send_email"
  parent_id = aws_api_gateway_rest_api.views_counter.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.views_counter.id
  
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.views_counter.id
  resource_id   = aws_api_gateway_resource.views_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "send_email_method" {
  rest_api_id = aws_api_gateway_rest_api.views_counter.id
  resource_id = aws_api_gateway_resource.email_resource.id
  http_method = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "views_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.views_counter.id
  resource_id             = aws_api_gateway_resource.views_resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cloud_resume_vist_counter.invoke_arn
}

resource "aws_api_gateway_integration" "send_email_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.views_counter.id
  resource_id             = aws_api_gateway_resource.email_resource.id
  http_method             = aws_api_gateway_method.send_email_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form_send_email.invoke_arn
}



# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloud_resume_vist_counter.function_name
  principal     = "apigateway.amazonaws.com"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.accountId}:${aws_api_gateway_rest_api.views_counter.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.views_resource.path}"
}

resource "aws_lambda_permission" "apigw_lambda_send_email_function" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form_send_email.function_name
  principal     = "apigateway.amazonaws.com"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.accountId}:${aws_api_gateway_rest_api.views_counter.id}/*/${aws_api_gateway_method.send_email_method.http_method}${aws_api_gateway_resource.email_resource.path}"
}


resource "aws_api_gateway_deployment" "viewscounterapi_deployment" {
  rest_api_id = aws_api_gateway_rest_api.views_counter.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.views_resource,
      aws_api_gateway_method.method, 
      aws_api_gateway_integration.views_lambda_integration,
      aws_api_gateway_resource.email_resource, 
      aws_api_gateway_method.send_email_method,
      aws_api_gateway_integration.send_email_lambda_integration
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [ 
    aws_api_gateway_resource.views_resource,
    aws_api_gateway_method.method, 
    aws_api_gateway_integration.views_lambda_integration,
    aws_api_gateway_resource.email_resource, 
    aws_api_gateway_method.send_email_method,
    aws_api_gateway_integration.send_email_lambda_integration ]
  
}

resource "aws_api_gateway_stage" "viewscounter_stage" {
  deployment_id = aws_api_gateway_deployment.viewscounterapi_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.views_counter.id
  stage_name    = "prod"

  depends_on = [
    aws_api_gateway_deployment.viewscounterapi_deployment,
    aws_cloudwatch_log_group.api_gateway_prod_stage
  ]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_prod_stage.arn
    format = jsonencode({
    "requestId":"$context.requestId", 
    "extendedRequestId":"$context.extendedRequestId", 
    "ip": "$context.identity.sourceIp", 
    "caller":"$context.identity.caller", 
    "user":"$context.identity.user", 
    "requestTime":"$context.requestTime", 
    "httpMethod":"$context.httpMethod", 
    "resourcePath":"$context.resourcePath", 
    "status":"$context.status", 
    "protocol":"$context.protocol", 
    "responseLength":"$context.responseLength" 
    })
  }
  
}

resource "aws_api_gateway_method_settings" "viewscounter_settings" {
  rest_api_id = aws_api_gateway_rest_api.views_counter.id
  stage_name  = aws_api_gateway_stage.viewscounter_stage.stage_name
  method_path = "*/*"
  settings {
    logging_level = "INFO"
    data_trace_enabled = true
    metrics_enabled = true
  }
}

resource "aws_api_gateway_usage_plan" "cloud_resume" {
  name         = "could_resume"
  description  = "usuage plan for cloud resume api"
  product_code = "MYCODE"

  api_stages {
    api_id = aws_api_gateway_rest_api.views_counter.id
    stage  = aws_api_gateway_stage.viewscounter_stage.stage_name
  }

  # quota_settings {
  #   limit  = 20
  #   offset = 2
  #   period = "WEEK"
  # }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 2
  }
}
