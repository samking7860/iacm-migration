
# Enable either variable to determin the source of the migtation

variable terraform_cloud_migration { 
    type = bool
    default = false
    description = "The flag that enables terraform cloud migration"
}

variable local_migration {
    type = bool
    default = false
    description = "The flag that enables local migtation"
}

########################################


# Terraform cloud specific variables

variable terraform_cloud_organization {
    type = string
    default = ""
    description = "Terraform Cloud organization ID"
}

variable terraform_cloud_project {
    type = string
    default = ""
    description = "Terraform Cloud Project ID"
}

variable terraform_cloud_token { 
    type = string
    default = "fakeapikey"
    description = "The token used to fetch the workspaces from Terraform Cloud"
}

variable terraform_cloud_migration_hostname {
    type = string
    default = "app.terraform.io"
    description = "The hostname used to fetch the workspaces from Terraform Cloud"
}

variable terraform_cloud_token_key_name { 
    type = string
    default = ""
    description = <<EOT
    The key of the env var that is added to the Harness workspace to
    enable IACM to fetch state from Terraform cloud (e.g. TF_TOKEN_app_terraform_io)
    Should include the domain as described here 
    https://developer.hashicorp.com/terraform/cli/config/config-file#environment-variable-credentials
    EOT
}

variable terraform_cloud_workspaces { 
    type = list(string)
    default = ["*"]
    description = <<EOT
    A a list of workspace names (within the provided organization) to migrate,
    defaults to all workspaces if not set.
    EOT
}

variable terraform_cloud_migrate_state {
    type = bool
    description = "A flag to determine if state is pulled locally and pushed into the created workspace"
    default = false
}

########################################


# Harness specific variables

variable harness_token {
    type = string
    description = "Harness api token"
}

variable harness_account_id {
    type = string
    description = "Harness account ID"
}

variable harness_project_id {
    type = string
    description = "Harness project ID"
}

variable harness_org_id {
    type = string
    description = "Harness org ID"
}

variable harness_default_provisioner_type {
    type = string
    description = "The default provisioner type e.g. terraform"
    default = ""
}

variable harness_default_provisioner_version {
    type = string
    description = "The default provisioner version e.g. 1.5.6"
    default = ""
}

variable harness_default_cost_estimation_enabled {
    type = bool
    default = true
    description = "The default determining if const estimation is enabled"
}

variable harness_default_provider_connector {
    type = string
    default = ""
    description = "The default prodiver connector"
}

variable harness_default_repository_connector {
    type = string
    default = ""
    description = "The default repository connector"
}

variable workspaces { # Required when the migration source is local_migration
    type = list(object({
        identifier              = string
        repository              = string                        
        repository_path         = string

        description = optional(string, "")
        repository_branch       = optional(string, "") # one of repository_branch or repository_connector must be supplied
        repository_commit       = optional(string, "") # one of  repository_branch or repository_commit must be supplied
        
        name                    = optional(string, "") # optional name, if not supplied the identifier is used
        provisioner_type        = optional(string, "") # optional provisioner, if not supplied default provisioner is used
        provisioner_version     = optional(string, "") # optional provisioner_version, if not supplied default provisioner_verision is used
        provider_connector      = optional(string, "") # optional provider_connector, if not supplied default provider_connector is used
        repository_connector    = optional(string, "") # optional repository_connector, if not supplied default repository_connector is used
        terraform_variables = optional(list(object({
            key = string
            value = string
            value_type = string
        })),null)
        environment_variables = optional(list(object({
            key = string
            value = string
            value_type = string
        })),null)
  }))
  default = []
}