// Copyright 2024 Harness, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


terraform {
  required_version = "~> 1.5.4"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    tfe = {
        version = "~> 0.51.1"
    }
  }
}

provider "tfe" {
    token = var.terraform_cloud_token
    hostname = var.terraform_cloud_migration_hostname
}

locals {
  template_file       = "workspaces.tfpl"
  tfe_workspace_ids   = var.terraform_cloud_migration ? [for i, v in data.tfe_workspace_ids.all["all"].ids : v] : []
  tfe_workspace_names = var.terraform_cloud_migration ? [for i, v in data.tfe_workspace_ids.all["all"].ids : i] : []
  tfe_workspaces_project_filtered = var.terraform_cloud_migration ? [for v in data.tfe_workspace.all : v if v.project_id == data.tfe_project.project[0].id] : []
  harness_workspaces      = var.terraform_cloud_migration ? [for workspace in local.tfe_workspaces_project_filtered : {
    identifier           = replace(workspace.id, "-", "_")
    name                 = workspace.name
    repository           = length(workspace.vcs_repo) > 0 ? split("/", workspace.vcs_repo[0].identifier)[1] : "placeholder"
    repository_path      = workspace.working_directory
    repository_branch    = length(workspace.vcs_repo) > 0 ? workspace.vcs_repo[0].branch != "" ? workspace.vcs_repo[0].branch : "placeholder" : "placeholder"
    provisioner_version  = var.harness_default_provisioner_version
    provider_connector   = var.harness_default_provider_connector != null ? var.harness_default_provider_connector : "placeholder"
    repository_connector = var.harness_default_repository_connector != null ? var.harness_default_repository_connector : "placeholder"
    provisioner_version  = var.harness_default_provisioner_version
    repository_commit    = ""
    provisioner_type     = "terraform"
    description          = "Migrated from Terraform Cloud workspace: ${workspace.html_url}"
    terraform_variables  = [
      for i, v in data.tfe_variables.all[workspace.id].variables :  {
        key        = v.name
        value      = v.value
        value_type = v.sensitive ? "secret" : "string"
      } if v.category == "terraform"
    ]
    environment_variables = [
      for i, v in data.tfe_variables.all[workspace.id].variables :  {
        key        = v.name
        value      = v.value
        value_type = v.sensitive ? "secret" : "string"
      } if v.category == "env" 
    ]
  }] : []
  tfe_workspaces_project_filtered_names =  var.terraform_cloud_migration ? [for v in local.tfe_workspaces_project_filtered: v.name] : []
}



data "tfe_workspace_ids" "all" {
  for_each     = var.terraform_cloud_migration ? toset(["all"]) : toset([])
  names        = var.terraform_cloud_workspaces
  organization = var.terraform_cloud_organization
}

data "tfe_workspace" "all" {
  for_each     = var.terraform_cloud_migration ? toset(local.tfe_workspace_names) : toset([])
  name         = each.key
  organization = var.terraform_cloud_organization
}

data "tfe_variables" "all" {
  for_each     = var.terraform_cloud_migration ? toset(local.tfe_workspace_ids) : toset([])
  workspace_id = each.key
}

data "tfe_project" "project" {
  count    = var.terraform_cloud_migration ? 1 : 0
  name = var.terraform_cloud_project
  organization = var.terraform_cloud_organization
}

resource "local_file" "local_migration" {
  count    = var.local_migration ? 1 : 0
  content  = templatefile(local.template_file, {
    workspaces = var.workspaces,
    account_id = var.harness_account_id,
    project = var.harness_project_id,
    org = var.harness_org_id,
    default_provisioner_type = var.harness_default_provisioner_type,
    default_provisioner_version = var.harness_default_provisioner_version,
    default_cost_estimation_enabled = var.harness_default_cost_estimation_enabled
    default_provider_connector = var.harness_default_provider_connector,
    default_repository_connector = var.harness_default_repository_connector,
    terraform_cloud_migration = false,
    terraform_cloud_migrate_state = false,
    terraform_cloud_token_key_name = ""
  })
  filename = "out/main.tf"

  provisioner "local-exec" {
    command = "terraform fmt ${self.filename}"
  }
}

resource "local_file" "terraform_cloud_migration" {
  count    = var.terraform_cloud_migration ? 1 : 0
  content  = templatefile(local.template_file, {
    workspaces = local.harness_workspaces,
    account_id = var.harness_account_id,
    project = var.harness_project_id,
    org = var.harness_org_id,
    default_provisioner_type = var.harness_default_provisioner_type,
    default_provisioner_version = var.harness_default_provisioner_version,
    default_cost_estimation_enabled = var.harness_default_cost_estimation_enabled
    default_provider_connector = var.harness_default_provider_connector,
    default_repository_connector = var.harness_default_repository_connector,
    terraform_cloud_migration = true,
    terraform_cloud_migrate_state = var.terraform_cloud_migrate_state,
    terraform_cloud_token_key_name = var.terraform_cloud_token_key_name
  })
  filename = "out/main.tf"

  provisioner "local-exec" {
    command = "terraform fmt ${self.filename}"
  }
}

// migrate terraform cloud state
resource "null_resource" "create_state_folder" {
  count = var.terraform_cloud_migrate_state?  1 : 0

  provisioner "local-exec" {
    command     = "mkdir -p out/state"
    working_dir = "${path.module}"
  }

  depends_on = [local_file.terraform_cloud_migration]
}

resource "null_resource" "create_workspace_folders" {
  for_each = var.terraform_cloud_migrate_state? toset(local.tfe_workspaces_project_filtered_names) : toset([])

  provisioner "local-exec" {
    command     =  "mkdir -p out/state/${each.key}"
    working_dir = "${path.module}"
  }

  depends_on = [null_resource.create_state_folder]
}

resource "null_resource" "create_cloud_main_tf" {
  for_each = var.terraform_cloud_migrate_state? toset(local.tfe_workspaces_project_filtered_names) : toset([])

  provisioner "local-exec" {
    command     = "echo \"terraform { \n cloud{} \n}\" > out/state/${each.key}/main.tf"
    working_dir = "${path.module}"
  }
  depends_on = [null_resource.create_workspace_folders]
}

resource "null_resource" "import_cloud_state" {
  for_each = var.terraform_cloud_migrate_state? toset(local.tfe_workspaces_project_filtered_names) : toset([])

  provisioner "local-exec" {
    command     = "terraform init && terraform state pull > ${each.key}.tfstate"
    working_dir = "${path.module}/out/state/${each.key}"
    environment = {
      "${var.terraform_cloud_token_key_name}" = "${var.terraform_cloud_token}" 
      TF_CLOUD_ORGANIZATION = "${var.terraform_cloud_organization}"
      TF_WORKSPACE = "${each.key}"
    }
  }
  
  depends_on = [null_resource.create_cloud_main_tf]
}


resource "null_resource" "cloud_cleanup_backend_state" {
  for_each = var.terraform_cloud_migrate_state? toset(local.tfe_workspaces_project_filtered_names) : toset([])

  provisioner "local-exec" {
    command     = "rm -rf .terraform/ && rm -f .terraform.lock.hcl"
    working_dir = "${path.module}/out/state/${each.key}"
  }
  
  depends_on = [null_resource.import_cloud_state]
}

resource "null_resource" "create_http_main_tf" {
  for_each = var.terraform_cloud_migrate_state? toset(local.tfe_workspaces_project_filtered_names) : toset([])

  provisioner "local-exec" {
    command     = "echo \"terraform { \n backend \"http\"{}\n}\" > out/state/${each.key}/main.tf"
    working_dir = "${path.module}"
  }
  depends_on = [null_resource.cloud_cleanup_backend_state]
}