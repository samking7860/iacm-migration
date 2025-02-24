local_cloud_migration = true
harness_account_id = "ucHySz2jQKKWQweZdXyCog"
harness_org        = "default"
harness_project    = "ORCA_onedev"
harness_default_provisioner_type = "terraform"
harness_default_provisioner_version = "1.5.6"
harness_default_cost_estimation_enabled = true
(* harness_default_provider_connector = "<your harness provider connector id>" *)
harness_default_repository_connector = "Samadgitconnector"
workspaces = [
  {
    identifier = "Samadworkspace"
    repository = "https://github.com/samking7860/terraform.git"
    repository_path = "."
    repository_branch = "main"
    terraform_variables = [ 
      {
        key = "key"
        value = "val"
        value_type = "string"
      } 
    ]
  }
]
