resource "kubernetes_namespace" "desafio_devops" {
  metadata {
    name = "desafio-devops"
  }
}
resource "kubernetes_service" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.desafio_devops.metadata[0].name
  }
  spec {
    selector = {
      app = "keycloak"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.desafio_devops.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "keycloak"
      }
    }
    template {
      metadata {
        labels = {
          app = "keycloak"
        }
      }
      spec {
        container {
          image = "quay.io/keycloak/keycloak:25.0.0"
          name  = "keycloak"
          env {
            name  = "KEYCLOAK_ADMIN"
            value = "admin"
          }
          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = "admin"
          }          
          env {
            name  = "DB_VENDOR"
            value = "mysql"
          }
          env {
            name  = "DB_ADDR"
            value = "mysql.default.svc.cluster.local"
          }
          env {
            name  = "DB_DATABASE"
            value = "keycloak"
          }
          env {
            name  = "DB_USER"
            value = "keycloak"
          }
          env {
            name  = "DB_PASSWORD"
            value = "keycloak"
          }
          port {
            container_port = 8080
          }
          command = ["/opt/keycloak/bin/kc.sh"]
          args = ["start-dev"]
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "keycloak" {
  metadata {
    name      = "keycloak-hpa"
    namespace = kubernetes_namespace.desafio_devops.metadata[0].name
  }
  spec {
    max_replicas = 5
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v2"
      kind        = "Deployment"
      name        = kubernetes_deployment.keycloak.metadata[0].name
    }
    metric {
      type = "Resource"
      resource {
        name  = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}
