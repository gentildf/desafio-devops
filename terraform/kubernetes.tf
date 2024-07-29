provider "kubernetes" {
  host                   = var.host
  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

module "desafio-devops" {
  source = "./desafio-devops"
}

module "monitoring-tools" {
  source = "./monitoring-tools"
}
resource "null_resource" "install_metrics_server" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./components.yaml"
  }
}
output "keycloak_service_ip" {
  value = module.desafio-devops.keycloak_service_ip
}
