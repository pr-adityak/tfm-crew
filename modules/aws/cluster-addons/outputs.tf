output "alb_controller_status" {
  description = "Status of AWS Load Balancer Controller installation"
  value = {
    name      = helm_release.aws_load_balancer_controller.name
    namespace = helm_release.aws_load_balancer_controller.namespace
    version   = helm_release.aws_load_balancer_controller.version
    status    = helm_release.aws_load_balancer_controller.status
  }
}

output "database_secret_name" {
  description = "Name of the database Kubernetes secret"
  value       = kubernetes_secret.database.metadata[0].name
}

output "database_secret_namespace" {
  description = "Namespace of the database Kubernetes secret"
  value       = kubernetes_secret.database.metadata[0].namespace
}
