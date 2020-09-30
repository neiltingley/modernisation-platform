data "aws_organizations_organization" "root_account" {}

locals {
  global_resources = {
    business-unit = "Platforms"
    application   = "Modernisation Platform"
    is-production = true
    owner         = "Modernisation Platform: modernisation-platform@digital.justice.gov.uk"
  }
  root_account = data.aws_organizations_organization.root_account
}
