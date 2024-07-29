resource "kubernetes_persistent_volume_claim" "mysql-pvc" {
  metadata {
    name = "mysql-pvc"
    namespace = "desafio-devops"
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

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
    namespace = "desafio-devops"
  }
  spec {
    selector = {
      app = "mysql"
    }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"
    namespace = "desafio-devops"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        init_container {
          name  = "init-mysql"
          image = "busybox"
          command = ["/bin/sh", "-c"]
          args = ["rm -rf /var/lib/mysql/*"]
          volume_mount {
            name       = "mysql-storage"
            mount_path = "/var/lib/mysql"
          }
        }
        container {
          name  = "mysql"
          image = "mysql:5.7"
          port {
            container_port = 3306
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "keycloak"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "keycloak"
          }
          env {
            name  = "MYSQL_USER"
            value = "keycloak"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = "keycloak"
          }
          volume_mount {
            mount_path = "/var/lib/mysql"
            name       = "mysql-storage"
          }
          command = ["/bin/bash", "-c"]
          args = ["if [ ! -d /var/lib/mysql/mysql ]; then echo 'Initializing database'; mysqld --initialize-insecure; fi; exec mysqld"]
        }
        volume {
          name = "mysql-storage"
          persistent_volume_claim {
            claim_name = "mysql-pvc"
          }
        }
      }
    }
  }
}
