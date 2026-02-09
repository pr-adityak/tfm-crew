<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 7.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_global_address.private_ip_address](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_service_networking_connection.private_vpc_connection](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_sql_database.database](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
| [google_sql_database_instance.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_database_instance.read_replica](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_user.db_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [random_password.db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_database_name"></a> [db\_database\_name](#input\_db\_database\_name) | Name of the database to create | `string` | `"crewai"` | no |
| <a name="input_db_edition"></a> [db\_edition](#input\_db\_edition) | Cloud SQL edition (ENTERPRISE or ENTERPRISE\_PLUS) | `string` | `"ENTERPRISE"` | no |
| <a name="input_db_instance_name"></a> [db\_instance\_name](#input\_db\_instance\_name) | Cloud SQL instance name | `string` | `"crewai-db"` | no |
| <a name="input_db_instance_tier"></a> [db\_instance\_tier](#input\_db\_instance\_tier) | Cloud SQL instance tier (machine type). Use db-custom-<CPU>-<RAM> format or a predefined tier from GCP. | `string` | `"db-custom-2-7680"` | no |
| <a name="input_db_master_username"></a> [db\_master\_username](#input\_db\_master\_username) | Database master username | `string` | `"postgres"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Prevent Terraform from destroying the database instance | `bool` | `false` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | VPC network ID for private IP configuration | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_reader_instance_count"></a> [reader\_instance\_count](#input\_reader\_instance\_count) | Number of read replica instances | `number` | `1` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for Cloud SQL instance | `string` | n/a | yes |
| <a name="input_replica_availability_type"></a> [replica\_availability\_type](#input\_replica\_availability\_type) | Availability type for read replicas (ZONAL or REGIONAL) | `string` | `"ZONAL"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection_name"></a> [connection\_name](#output\_connection\_name) | Connection name for Cloud SQL instance (used for Cloud SQL Proxy) |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the created database |
| <a name="output_db_password"></a> [db\_password](#output\_db\_password) | Generated database password |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | Name of the Cloud SQL instance |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | Private IP address of the Cloud SQL instance |
| <a name="output_replica_connection_names"></a> [replica\_connection\_names](#output\_replica\_connection\_names) | Connection names for read replicas |
<!-- END_TF_DOCS -->