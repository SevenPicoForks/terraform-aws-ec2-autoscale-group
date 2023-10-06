#------------------------------------------------------------------------------
# Kms Key
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "kms_key_policy_document" {
  count = module.context.enabled && var.create_sns_notifications ? 1 : 0
  statement {
    sid    = "RootUserPermission"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["${local.arn_prefix}:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchToDecryptDataKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
  }
}


module "sns_kms_key" {
  source     = "registry.terraform.io/SevenPicoForks/kms-key/aws"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.create_sns_notifications
  attributes = ["kms", "key"]

  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 10
  description              = "KMS key for ${module.context.id}"
  enable_key_rotation      = true
  key_usage                = "ENCRYPT_DECRYPT"
  multi_region             = false
  policy                   = data.aws_iam_policy_document.kms_key_policy_document[0].json
}


#------------------------------------------------------------------------------
# SNS Topic
#------------------------------------------------------------------------------
module "sns" {
  source     = "SevenPico/sns/aws"
  version    = "2.0.2"
  context    = module.context.self
  enabled    = module.context.enabled && var.create_sns_notifications
  attributes = ["sns"]

  kms_master_key_id = module.sns_kms_key.key_id
  pub_principals    = {}
  sub_principals    = {}
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  for_each  = module.context.enabled && var.create_sns_notifications ? var.sns_subscriptions : {}
  topic_arn = module.sns.topic_arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}