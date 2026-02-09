<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

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
| <a name="input_admin_iam_principals"></a> [admin\_iam\_principals](#input\_admin\_iam\_principals) | List of IAM principal ARNs to grant cluster admin access | `list(string)` | `[]` | no |
| <a name="input_availability_zone_count"></a> [availability\_zone\_count](#input\_availability\_zone\_count) | Number of availability zones to use (minimum 2 for HA) | `number` | `2` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks that can access the EKS cluster public API endpoint. Use YOUR\_IP/32 for single IPs. Empty list = private-only access | `list(string)` | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | `"crewai-cluster"` | no |
| <a name="input_db_cluster_identifier"></a> [db\_cluster\_identifier](#input\_db\_cluster\_identifier) | Aurora PostgreSQL cluster identifier | `string` | `"crewai-db-cluster"` | no |
| <a name="input_db_database_name"></a> [db\_database\_name](#input\_db\_database\_name) | Name of the database to create in PostgreSQL | `string` | `"crewai"` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | PostgreSQL engine version for Aurora | `string` | `"16.6"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | Database instance class for Aurora PostgreSQL | `string` | `"db.t4g.medium"` | no |
| <a name="input_db_master_username"></a> [db\_master\_username](#input\_db\_master\_username) | Database master username | `string` | `"postgres"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the EKS cluster | `string` | `"1.32"` | no |
| <a name="input_network_name_prefix"></a> [network\_name\_prefix](#input\_network\_name\_prefix) | Prefix for all network resource names | `string` | `"crewai-"` | no |
| <a name="input_reader_instance_count"></a> [reader\_instance\_count](#input\_reader\_instance\_count) | Number of Aurora reader instances for high availability | `number` | `1` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the deployment | `string` | n/a | yes |
| <a name="input_s3_data_bucket_name"></a> [s3\_data\_bucket\_name](#input\_s3\_data\_bucket\_name) | Globally unique S3 bucket name for application data | `string` | n/a | yes |
| <a name="input_s3_logs_bucket_name"></a> [s3\_logs\_bucket\_name](#input\_s3\_logs\_bucket\_name) | Globally unique S3 bucket name for centralized logs | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_workload_namespace"></a> [workload\_namespace](#input\_workload\_namespace) | Kubernetes namespace for CrewAI platform workloads | `string` | `"crewai-platform"` | no |
| <a name="input_workload_service_account"></a> [workload\_service\_account](#input\_workload\_service\_account) | Kubernetes service account name for CrewAI platform workloads | `string` | `"crewai-platform-sa"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data for cluster authentication |
| <a name="output_cluster_configuration"></a> [cluster\_configuration](#output\_cluster\_configuration) | EKS cluster configuration and connection information |
| <a name="output_database_configuration"></a> [database\_configuration](#output\_database\_configuration) | Database connection information (database names managed externally) |
| <a name="output_network_configuration"></a> [network\_configuration](#output\_network\_configuration) | Complete network configuration |
| <a name="output_platform_summary"></a> [platform\_summary](#output\_platform\_summary) | Summary of key platform resources for quick reference |
| <a name="output_s3_data_bucket_arn"></a> [s3\_data\_bucket\_arn](#output\_s3\_data\_bucket\_arn) | ARN of the S3 data bucket |
| <a name="output_s3_data_bucket_name"></a> [s3\_data\_bucket\_name](#output\_s3\_data\_bucket\_name) | Name of the S3 data bucket |
| <a name="output_s3_logs_bucket_arn"></a> [s3\_logs\_bucket\_arn](#output\_s3\_logs\_bucket\_arn) | ARN of the S3 logs bucket |
| <a name="output_s3_logs_bucket_name"></a> [s3\_logs\_bucket\_name](#output\_s3\_logs\_bucket\_name) | Name of the S3 logs bucket |
| <a name="output_secrets_configuration"></a> [secrets\_configuration](#output\_secrets\_configuration) | Secrets Manager configuration |
<!-- END_TF_DOCS -->