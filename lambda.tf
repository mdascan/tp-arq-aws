resource "aws_lambda_function" "remote_service" {
  filename         = "remoteService.zip"
  function_name    = "remoteService"
  role             = "${var.lambda_role_arn}"
  handler          = "remoteService.handler"
  source_code_hash = "${base64sha256(file("remoteService.zip"))}"
  runtime          = "nodejs8.10"
  vpc_config       = {
    subnet_ids         = ["${var.subnet_1a_id}","${var.subnet_1c_id}"]
    security_group_ids = ["${var.default_sg}"] 
  }
}