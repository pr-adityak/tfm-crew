<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.4 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.11 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.11 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.23 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.platform](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.database](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_controller_role_arn"></a> [alb\_controller\_role\_arn](#input\_alb\_controller\_role\_arn) | IAM role ARN for AWS Load Balancer Controller | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_database_secret_name"></a> [database\_secret\_name](#input\_database\_secret\_name) | Name of the Kubernetes secret for database credentials | `string` | `"crewai-database"` | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | Database host (Aurora cluster endpoint) | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | n/a | yes |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Database password | `string` | n/a | yes |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | Database port | `number` | `5432` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Database username | `string` | n/a | yes |
| <a name="input_platform_namespace"></a> [platform\_namespace](#input\_platform\_namespace) | Namespace for platform resources (secrets, workloads, etc.) | `string` | `"crewai-platform"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for ALB controller | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_controller_status"></a> [alb\_controller\_status](#output\_alb\_controller\_status) | Status of AWS Load Balancer Controller installation |
| <a name="output_database_secret_name"></a> [database\_secret\_name](#output\_database\_secret\_name) | Name of the database Kubernetes secret |
| <a name="output_database_secret_namespace"></a> [database\_secret\_namespace](#output\_database\_secret\_namespace) | Namespace of the database Kubernetes secret |
<!-- END_TF_DOCS -->