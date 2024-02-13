data "aws_iam_policy" "fleet_manager" {
  name = "fleet_manager_policy"
}

# fleet-manager role for collaborators
module "collaborator_fleet_manager_role" {
  # checkov:skip=CKV_TF_1:
  count   = local.account_data.account-type == "member" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5"
  trusted_role_arns = [
    local.modernisation_platform_account.id
  ]

  create_role       = true
  role_name         = "fleet-manager"
  role_requires_mfa = true

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    data.aws_iam_policy.fleet_manager.arn
  ]
  number_of_custom_role_policy_arns = 2
}

# read only role for collaborators
module "collaborator_readonly_role" {
  # checkov:skip=CKV_TF_1:
  count   = local.account_data.account-type == "member" || local.account_data.account-type == "core" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-roles"
  version = "~> 5"
  max_session_duration = 43200

  # Read-only role
  create_readonly_role       = true
  readonly_role_name         = "read-only"
  readonly_role_requires_mfa = true

  # Allow created users to assume these roles
  trusted_role_arns = [
    local.modernisation_platform_account.id
  ]
}

# security audit role for collaborators
module "collaborator_security_audit_role" {
  # checkov:skip=CKV_TF_1:
  count   = local.account_data.account-type == "member" || local.account_data.account-type == "core" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5"
  max_session_duration = 43200

  create_role       = true
  role_name         = "security-audit"
  role_requires_mfa = true

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/SecurityAudit"
  ]

  # Allow created users to assume these roles
  trusted_role_arns = [
    local.modernisation_platform_account.id
  ]
}

# Collaborator Migration role
module "collaborator_migration_role" {
  # checkov:skip=CKV_TF_1:
  count   = local.account_data.account-type == "member" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5"
  trusted_role_arns = [
    local.modernisation_platform_account.id
  ]

  create_role       = true
  role_name         = "migration"
  role_requires_mfa = true

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSApplicationMigrationFullAccess",
    "arn:aws:iam::aws:policy/AWSDataSyncFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/ServerMigrationConnector",
    "arn:aws:iam::aws:policy/AWSApplicationMigrationEC2Access",
    data.aws_iam_policy.migration.arn,
  ]
  number_of_custom_role_policy_arns = 7
}

data "aws_iam_policy" "migration" {
  name = "migration_policy"
}
