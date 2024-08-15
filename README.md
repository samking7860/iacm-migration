# Harness Infrastructure as Code migration tool
The tool works by generating Terraform code to provision Harness IACM workspaces and a pipeline which will fetch the Terraform state for each workspace and store it in Harness IACM. All workspaces are created inside the same account, organization and project. To use the migration pipeline your Terraform code must be configured to use remote backend. 


## Getting Started
### Prerequisites
1. Clone this repo
2. Install Terraform
3. Generate a Harness [API key](https://developer.harness.io/docs/platform/automation/api/add-and-manage-api-keys/)
4. Export the API key ```export  HARNESS_PLATFORM_API_KEY=.....```

### Migrating from local Terraform
When migrating from local Terraform the tool will create a workspace for each workspace defined in the ```workspaces``` tfvar.

#### Variables
Variables are defined inside each workspace in the ```workspaces``` tfvar. For variables of type secret, each secret will need created manually as a Harness secret. This secret identifier can then be used to update the Harness workspace variable.

#### Connectors
Connector values can be set using the ```harness_default_provider_connector``` and ```harness_default_repository_connector``` tfvars. If you do not wish to use the same connectors for every workspace then omit the default connector values and add the connector values inside each workspace in the ```workspaces``` tfvar. 

#### Example tfvar file values
```
local_cloud_migration = true
harness_account_id = "<your harness account id>"
harness_org        = "<your harness org id>"
harness_project    = "<your harness project id>"
harness_default_provisioner_type = "terraform"
harness_default_provisioner_version = "1.5.6"
harness_default_cost_estimation_enabled = true
harness_default_provider_connector = "<your harness provider connector id>"
harness_default_repository_connector = "<your harness repository connector id>"
workspaces = [
  {
    identifier = "workspace1"
    repository = "repo1"
    repository_path = "tf1"
    repository_branch = "branch1"
    terraform_variables = [ 
      {
        key = "key"
        value = "val"
        value_type = "string"
      } 
    ]
  },
  {
    identifier = "workspace2"
    repository = "repo2"
    repository_path = "tf2"
    repository_branch = "branch2"
    terraform_variables = [ 
      {
        key = "key"
        value = "val"
        value_type = "string"
      } 
    ]
  }
]

```
#### Steps
1. Create a ```.tfvar``` file using ```local.example.tfvars``` as a reference
2. Run ```terraform init``` in the root of the project
3. Run ```terraform apply  -var-file=....``` specifying the correct ```.tfvar``` file. This will generate the Terraform code inside the ```/out``` folder.
4. Navigate to the out folder ```cd ./out```
5. Run ```terraform init``` 
6. Run ```terraform apply``` to create your new harness resources

### Migrating from Terraform Cloud
When migrating from Terraform Cloud the tool will fetch all of the workspaces inside the provided ```terraform_cloud_project``` and create a corresponding Harness workspace.

#### Variables
The tool will fetch the variables for each Terraform Cloud workspace and create environment or Terraform variables inside the corresponding Harness workspace. Any sensitive Terraform Cloud variable will be set as type secret in the Harness workspace. Any sensitive variable in Terraform Cloud will need to be recreated manually as a Harness secret and this secret identifier can then be used to update any Harness workspace variable where the secret should be used. **Migration of Terraform Cloud variable sets is not currently supported**

The tool will also set an environment variable in each Harness workspace named with the value of the ```terraform_cloud_token_key_name``` tfvar. The value will be set as the provided Terraform Cloud API key. This allows the migration pipeline to fetch the state if Terraform Cloud is the configured backend.

### Connectors
Connector values can be set using the ```harness_default_provider_connector``` and ```harness_default_repository_connector``` tfvars. If you do not wish to use the same connectors for every workspace then omit the default connector values and update the connectors either in the Terraform post generation or in the UI post Terraform apply.


#### Example tfvar file values

```
terraform_cloud_token_key_name = "TF_TOKEN_app_terraform_io"
terraform_cloud_migration = true
terraform_cloud_organization = "<your terraform cloud organization>"
terraform_cloud_project = "<your terraform cloud project>"
terraform_cloud_migrate_state = false
terraform_cloud_token = "<your terraform cloud api key>"
terraform_cloud_workspaces = ["<your terraform cloud workspaces>"]
harness_account_id = "<your harness account id>"
harness_org_id        = "<your harness org id>"
harness_project_id    = "<your harness project id>"
harness_default_provisioner_version = "1.5.6"
harness_default_cost_estimation_enabled = true
harness_default_provider_connector = "<your harness provider connector id>"
harness_default_repository_connector = "<your harness repository connector id>"
```
#### Steps
1. Export your Terraform Cloud API Key ```export TFE_TOKEN=....```
1. Create a ```.tfvar``` file using ```tfc.example.tfvars``` as a reference
2. Run ```terraform init``` in the root of the project
3. Run ```terraform apply  -var-file=....``` specifying the correct ```.tfvar``` file. This will generate the Terraform code inside the ```/out``` folder.
4. Navigate to the out folder ```cd ./out```
5. Run ```terraform init``` 
6. Run ```terraform apply -var="terraform_cloud_token=..." -var="harness_token=..."``` -var= to create your new harness resources