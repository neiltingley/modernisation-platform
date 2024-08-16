resource "random_id" "name" {
  byte_length = 4
}

resource "aws_iam_role" "firehose-to-s3" {
  assume_role_policy = data.aws_iam_policy_document.firehose-trust-policy.json
  name_prefix        = "firehose-to-s3"
  tags               = var.tags
}

resource "aws_iam_policy" "firehose-to-s3" {
  policy = data.aws_iam_policy_document.firehose-role-policy.json
  tags   = var.tags
}

resource "aws_iam_policy_attachment" "firehose-to-s3" {
  name       = "${aws_iam_role.firehose-to-s3.name}-policy"
  policy_arn = aws_iam_policy.firehose-to-s3.arn
  roles      = [aws_iam_role.firehose-to-s3.name]
}

resource "aws_iam_role" "cloudwatch-to-firehose" {
  assume_role_policy = data.aws_iam_policy_document.cloudwatch-logs-trust-policy.json
  name_prefix        = "cloudwatch-to-firehose"
  tags               = var.tags
}

resource "aws_iam_policy" "cloudwatch-to-firehose" {
  policy = data.aws_iam_policy_document.cloudwatch-logs-role-policy.json
  tags   = var.tags
}

resource "aws_iam_policy_attachment" "cloudwatch-to-firehose" {
  name       = "${aws_iam_role.cloudwatch-to-firehose.name}-policy"
  policy_arn = aws_iam_policy.cloudwatch-to-firehose.arn
  roles      = [aws_iam_role.cloudwatch-to-firehose.name]
}

resource "aws_kinesis_firehose_delivery_stream" "firehose-to-s3" {
  destination = "extended_s3"
  name        = "cloudwatch-to-s3-${random_id.name.hex}"

  extended_s3_configuration {
    bucket_arn = var.destination_bucket_arn
    role_arn   = aws_iam_role.firehose-to-s3.arn

    prefix              = "logs/!{partitionKeyFromQuery:logGroupName}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

    buffer_size     = 64
    buffer_interval = 60

    dynamic_partitioning_configuration {
      enabled = true
    }

    processing_configuration {
      enabled = true

      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{logGroupName:.logGroup}"
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-to-firehose" {
  for_each        = toset(var.cloudwatch_log_groups)
  destination_arn = aws_kinesis_firehose_delivery_stream.firehose-to-s3.arn
  filter_pattern  = "" # Left empty to stream all logs
  log_group_name  = each.key
  name            = "firehose-delivery-${each.key}"
  role_arn        = aws_iam_role.cloudwatch-to-firehose.arn
}