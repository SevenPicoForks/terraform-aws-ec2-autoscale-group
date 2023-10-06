#------------------------------------------------------------------------------
# Kms Key
#------------------------------------------------------------------------------
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
  policy                   = ""
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