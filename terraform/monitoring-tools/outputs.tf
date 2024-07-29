output "prometheus_service_ip" {
  value = element(kubernetes_service.prometheus.status[0].load_balancer[0].ingress, 0).ip
}
