<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_subnet_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_rds_cluster.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_rds_cluster_instance.writer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_security_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.database_egress_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.database_ingress_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [null_resource.validate_subnets](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_cluster_identifier"></a> [db\_cluster\_identifier](#input\_db\_cluster\_identifier) | Aurora PostgreSQL cluster identifier for the main database | `string` | `"crewai-cluster"` | no |
| <a name="input_db_database_name"></a> [db\_database\_name](#input\_db\_database\_name) | Name of the initial database to create in PostgreSQL | `string` | `"crewai"` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | PostgreSQL engine version for Aurora compatibility (minimum 15.10) | `string` | `"16.6"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | Database instance class for Aurora PostgreSQL instances | `string` | `"db.t4g.medium"` | no |
| <a name="input_db_master_username"></a> [db\_master\_username](#input\_db\_master\_username) | Database master username for administrative access | `string` | `"postgres"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for all resource names | `string` | `"crewai-"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs for the database subnet group | `list(string)` | n/a | yes |
| <a name="input_reader_instance_count"></a> [reader\_instance\_count](#input\_reader\_instance\_count) | Number of Aurora reader instances for high availability and read scaling | `number` | `1` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block of the VPC (for security group rules) | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where database will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the Aurora cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Writer endpoint for the Aurora cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the Aurora cluster |
| <a name="output_cluster_port"></a> [cluster\_port](#output\_cluster\_port) | Port number for the database |
| <a name="output_cluster_reader_endpoint"></a> [cluster\_reader\_endpoint](#output\_cluster\_reader\_endpoint) | Reader endpoint for the Aurora cluster |
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Database connection information for applications (database names managed externally) |
| <a name="output_db_password"></a> [db\_password](#output\_db\_password) | Generated database password |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Name of the DB subnet group |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | Master username for the database |
| <a name="output_reader_instance_count"></a> [reader\_instance\_count](#output\_reader\_instance\_count) | Number of reader instances deployed |
| <a name="output_reader_instance_endpoints"></a> [reader\_instance\_endpoints](#output\_reader\_instance\_endpoints) | Endpoints of the reader instances |
| <a name="output_reader_instance_ids"></a> [reader\_instance\_ids](#output\_reader\_instance\_ids) | IDs of the reader instances |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the database security group |
| <a name="output_writer_instance_endpoint"></a> [writer\_instance\_endpoint](#output\_writer\_instance\_endpoint) | Endpoint of the writer instance |
| <a name="output_writer_instance_id"></a> [writer\_instance\_id](#output\_writer\_instance\_id) | ID of the writer instance |
<!-- END_TF_DOCS -->