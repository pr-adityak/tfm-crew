<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.10.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository.repository](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | GCP region for the deployment | `string` | n/a | yes |
| <a name="input_repository_id"></a> [repository\_id](#input\_repository\_id) | ID of the repository | `string` | `"crewai-enterprise"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_registry_uri"></a> [registry\_uri](#output\_registry\_uri) | Registry URI of the Google Artifact Repository |
| <a name="output_repository_id"></a> [repository\_id](#output\_repository\_id) | ID of the Google Artifact Repository |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | Name of the Google Artifact Repository |
<!-- END_TF_DOCS -->