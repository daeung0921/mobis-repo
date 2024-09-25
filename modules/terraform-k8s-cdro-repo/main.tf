
resource "kubernetes_service_v1" "flow_repository" {
  for_each = var.enable_create_resources ? { for cfg in var.config : cfg.service_name => cfg } : {}

  metadata {
    name      = each.value.service_name
    namespace = each.value.namespace
    labels = {
      app     = each.value.app_name
      release = each.value.release_name
    }
  }

  spec {
    selector = {
      app     = each.value.app_name
      release = each.value.release_name
    }

    type = "ClusterIP"

    port {
      name        = "ef-repository"
      port        = 8200
      protocol    = "TCP"
      target_port = "p3-repository"
    }
  }
}

resource "kubernetes_network_policy_v1" "repository_policy" {
  for_each = var.enable_create_resources ? { for cfg in var.config : "${cfg.namespace}-${cfg.app_name}" => cfg } : {}

  metadata {
    name      = each.value.policy_name
    namespace = each.value.namespace
    labels = {
      app     = each.value.app_name
      release = each.value.release_name
    }
  }

  spec {
    pod_selector {
      match_labels = {
        app     = each.value.app_name
        release = each.value.release_name
      }
    }

    ingress {
      from {
        pod_selector {
          match_labels = {
            app     = "cb-flow-bound-agent-flow-agent"
            release = each.value.release_name
          }
        }
      }

      from {
        pod_selector {
          match_labels = {
            app     = "flow-server"
            release = each.value.release_name
          }
        }
      }

      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }

      ports {
        port     = 8200
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_deployment_v1" "flow_repository" {
  for_each = var.enable_create_resources ? { for cfg in var.config : cfg.app_name => cfg } : {}

  metadata {
    name      = each.value.app_name
    namespace = each.value.namespace
    labels = {
      app     = each.value.app_name
      release = each.value.release_name
    }
  }

  spec {
    replicas = each.value.resource.replicas

    selector {
      match_labels = {
        app     = each.value.app_name
        release = each.value.release_name
      }
    }

    template {
      metadata {
        labels = {
          app     = each.value.app_name
          release = each.value.release_name
        }
      }

      spec {
        container {
          name              = each.value.app_name
          image             = each.value.resource.image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "CBF_REPOSITORY_NAME"
            value = each.value.repository_name
          }
          env {
            name  = "PUBLIC_HOSTNAME"
            value = each.value.app_name
          }
          env {
            name  = "CBF_SERVER_HOST"
            value = each.value.env.cbf_server_host
          }
          env {
            name = "CBF_SERVER_PASSWORD"
            value_from {
              secret_key_ref {
                name = each.value.secret.cbf_server_secret_name
                key  = each.value.secret.cbf_server_secret_key
              }
            }
          }
          env {
            name  = "CBF_SERVER_USER"
            value = each.value.env.cbf_server_user
          }
          env {
            name  = "CBF_LOCAL_RESOURCE_HOST"
            value = each.value.env.cbf_local_resource_host
          }
          env {
            name  = "CBF_CONFIGURE"
            value = each.value.env.cbf_configure_memory
          }

          resources {
            limits = {
              cpu    = each.value.resource.cpu_limit
              memory = each.value.resource.memory_limit
            }
            requests = {
              cpu    = each.value.resource.cpu_request
              memory = each.value.resource.memory_request
            }
          }

          volume_mount {
            name       = "repository-data-volume"
            mount_path = "/repository-data"
          }

          volume_mount {
            name       = "logback-config"
            mount_path = "/custom-config/repository/logging-local.properties"
            sub_path   = "repository-logback-config"
          }

          liveness_probe {
            exec {
              command = ["/opt/cbflow/health-check"]
            }
            initial_delay_seconds = 120
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            tcp_socket {
              port = 8200
            }
            initial_delay_seconds = 120
            period_seconds        = 5
            timeout_seconds       = 5
          }

          port {
            container_port = 8200
            name           = "p3-repository"
            protocol       = "TCP"
          }
        }

        volume {
          name = "repository-data-volume"
          persistent_volume_claim {
            claim_name = each.value.claim_name
          }
        }

        volume {
          name = "logback-config"
          config_map {
            name = "flow-logging-config"
          }
        }

        node_selector = {
          "type"  = "physical"
          "usage" = "sys"
        }

        service_account_name = "default"
      }
    }

    strategy {
      type = "Recreate"
    }
  }
}

resource "kubernetes_persistent_volume_v1" "cdro_repo_pv" {
  for_each = var.enable_create_resources ? { for cfg in var.config : cfg.pv_name => cfg } : {}
  metadata {
    name = each.value.pv_name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    capacity = {
      storage = each.value.resource.storage
    }
    persistent_volume_source {
      nfs {
        path      = each.value.nfs.path
        server    = each.value.nfs.server
        read_only = each.value.nfs.read_only
      }
    }
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = each.value.resource.storage_class
  }
}


resource "kubernetes_persistent_volume_claim_v1" "cdro_repo_pvc" {
  for_each = var.enable_create_resources ? { for cfg in var.config : cfg.claim_name => cfg } : {}

  metadata {
    name      = each.value.claim_name
    namespace = each.value.namespace
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = each.value.resource.storage
      }
    }
    storage_class_name = each.value.resource.storage_class
    volume_mode = "Filesystem"
    volume_name = each.value.pv_name
  }
}