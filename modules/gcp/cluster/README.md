<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository_iam_member.workload_repository_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_container_cluster.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |
| [google_project_iam_member.workload_cloudsql_client](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret_iam_member.workload_secret_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.node_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket_iam_member.workload_data_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.workload_logs_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_repository_name"></a> [artifact\_repository\_name](#input\_artifact\_repository\_name) | Name of the Google Artifact Repository for the CrewAI Builder | `string` | n/a | yes |
| <a name="input_cluster_authorized_networks"></a> [cluster\_authorized\_networks](#input\_cluster\_authorized\_networks) | List of CIDR blocks that can access the cluster API endpoint (for kubectl). Empty list = private-only access | `list(string)` | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster | `string` | `"crewai-cluster"` | no |
| <a name="input_data_bucket_name"></a> [data\_bucket\_name](#input\_data\_bucket\_name) | GCS data bucket name (for IAM binding) | `string` | n/a | yes |
| <a name="input_initial_node_count"></a> [initial\_node\_count](#input\_initial\_node\_count) | Number of nodes to start the cluster with | `number` | n/a | yes |
| <a name="input_logs_bucket_name"></a> [logs\_bucket\_name](#input\_logs\_bucket\_name) | GCS logs bucket name (for IAM binding) | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | VPC network ID | `string` | n/a | yes |
| <a name="input_node_machine_type"></a> [node\_machine\_type](#input\_node\_machine\_type) | Type of instance to use for cluster's nodes | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the GKE cluster | `string` | n/a | yes |
| <a name="input_secret_id"></a> [secret\_id](#input\_secret\_id) | Secret Manager secret ID (for IAM binding) | `string` | n/a | yes |
| <a name="input_subnet_self_links"></a> [subnet\_self\_links](#input\_subnet\_self\_links) | List of subnet self links | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | CA certificate for the GKE cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for the GKE cluster |
| <a name="output_cluster_location"></a> [cluster\_location](#output\_cluster\_location) | Location (region) of the GKE cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the GKE cluster |
| <a name="output_node_service_account_email"></a> [node\_service\_account\_email](#output\_node\_service\_account\_email) | Email of the GKE node service account |
<!-- END_TF_DOCS -->