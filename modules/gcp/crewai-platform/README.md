<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ../cluster | n/a |
| <a name="module_database"></a> [database](#module\_database) | ../database | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ../networking | n/a |
| <a name="module_repository"></a> [repository](#module\_repository) | ../repository | n/a |
| <a name="module_secrets"></a> [secrets](#module\_secrets) | ../secrets | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ../storage | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_repository_id"></a> [artifact\_repository\_id](#input\_artifact\_repository\_id) | ID of the Google Artifact Repository used by CrewAI builder | `string` | `"crewai-enterprise"` | no |
| <a name="input_cluster_authorized_networks"></a> [cluster\_authorized\_networks](#input\_cluster\_authorized\_networks) | List of CIDR blocks that can access the GKE cluster API endpoint. Use YOUR\_IP/32 for single IPs. Empty list = private-only access | `list(string)` | `[]` | no |
| <a name="input_cluster_initial_node_count"></a> [cluster\_initial\_node\_count](#input\_cluster\_initial\_node\_count) | Number of nodes to start the cluster with | `number` | `1` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster | `string` | `"crewai-cluster"` | no |
| <a name="input_cluster_node_machine_type"></a> [cluster\_node\_machine\_type](#input\_cluster\_node\_machine\_type) | Type of instance to use for cluster's nodes | `string` | `"e2-standard-4"` | no |
| <a name="input_db_database_name"></a> [db\_database\_name](#input\_db\_database\_name) | Name of the database to create | `string` | `"crewai"` | no |
| <a name="input_db_edition"></a> [db\_edition](#input\_db\_edition) | Cloud SQL edition (ENTERPRISE or ENTERPRISE\_PLUS) | `string` | `"ENTERPRISE"` | no |
| <a name="input_db_instance_name"></a> [db\_instance\_name](#input\_db\_instance\_name) | Cloud SQL instance name | `string` | `"crewai-db"` | no |
| <a name="input_db_instance_tier"></a> [db\_instance\_tier](#input\_db\_instance\_tier) | Cloud SQL instance tier (machine type). Use db-custom-<CPU>-<RAM> format or a predefined tier from GCP. | `string` | `"db-custom-2-7680"` | no |
| <a name="input_db_master_username"></a> [db\_master\_username](#input\_db\_master\_username) | Database master username | `string` | `"postgres"` | no |
| <a name="input_gcs_data_bucket_name"></a> [gcs\_data\_bucket\_name](#input\_gcs\_data\_bucket\_name) | Globally unique GCS bucket name for application data | `string` | n/a | yes |
| <a name="input_gcs_logs_bucket_name"></a> [gcs\_logs\_bucket\_name](#input\_gcs\_logs\_bucket\_name) | Globally unique GCS bucket name for centralized logs | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of the VPC network | `string` | `"crewai-network"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_reader_instance_count"></a> [reader\_instance\_count](#input\_reader\_instance\_count) | Number of Cloud SQL read replica instances for high availability | `number` | `1` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the deployment | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_zone_count"></a> [zone\_count](#input\_zone\_count) | Number of zones to use (minimum 2 for HA) | `number` | `3` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_configuration"></a> [cluster\_configuration](#output\_cluster\_configuration) | GKE cluster configuration details |
| <a name="output_database_configuration"></a> [database\_configuration](#output\_database\_configuration) | Cloud SQL database configuration details |
| <a name="output_network_configuration"></a> [network\_configuration](#output\_network\_configuration) | VPC network configuration details |
| <a name="output_platform_summary"></a> [platform\_summary](#output\_platform\_summary) | Summary of key platform resources for quick reference |
| <a name="output_secrets_configuration"></a> [secrets\_configuration](#output\_secrets\_configuration) | Secret Manager configuration details |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | GCS storage configuration details |
<!-- END_TF_DOCS -->