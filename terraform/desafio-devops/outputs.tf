output "keycloak_service_ip" {
  value = kubernetes_service.keycloak.status[0].load_balancer[0].ingress[0].ip
}
