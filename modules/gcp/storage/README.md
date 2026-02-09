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
| [google_storage_bucket.data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket.logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_bucket_name"></a> [data\_bucket\_name](#input\_data\_bucket\_name) | Globally unique GCS bucket name for application data | `string` | n/a | yes |
| <a name="input_logs_bucket_name"></a> [logs\_bucket\_name](#input\_logs\_bucket\_name) | Globally unique GCS bucket name for centralized logs | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for bucket location | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_bucket_name"></a> [data\_bucket\_name](#output\_data\_bucket\_name) | Name of the data GCS bucket |
| <a name="output_data_bucket_url"></a> [data\_bucket\_url](#output\_data\_bucket\_url) | URL of the data GCS bucket |
| <a name="output_logs_bucket_name"></a> [logs\_bucket\_name](#output\_logs\_bucket\_name) | Name of the logs GCS bucket |
| <a name="output_logs_bucket_url"></a> [logs\_bucket\_url](#output\_logs\_bucket\_url) | URL of the logs GCS bucket |
<!-- END_TF_DOCS -->