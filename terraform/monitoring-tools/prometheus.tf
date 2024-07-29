resource "kubernetes_namespace" "monitoring_tools" {
  metadata {
    name = "monitoring-tools"
  }
}

resource "kubernetes_persistent_volume_claim" "prometheus-pvc" {
  metadata {
    name      = "prometheus-pvc"
    namespace = kubernetes_namespace.monitoring_tools.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring_tools.metadata[0].name
  }
  spec {
    selector = {
      app = "prometheus"
    }
    port {
      port        = 9090
      target_port = 9090
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring_tools.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }
      spec {
        init_container {
          name  = "init-prometheus"
          image = "busybox"
          command = ["/bin/sh", "-c"]
          args = ["chown -R 65534:65534 /prometheus"]
          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }
        }
        container {
          name  = "prometheus"
          image = "prom/prometheus:latest"
          port {
            container_port = 9090
          }
          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }
          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus"
          ]
        }
        volume {
          name = "prometheus-storage"
          persistent_volume_claim {
            claim_name = "prometheus-pvc"
          }
        }
      }
    }
  }
}
