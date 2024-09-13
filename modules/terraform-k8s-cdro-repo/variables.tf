variable "config" {
  description = "List of grouped application and resource configurations"

  type = list(object({
    namespace       = optional(string, "cloudbees")
    app_name        = string
    claim_name      = string
    service_name    = string
    policy_name     = string
    repository_name = string
    pv_name         = string
    release_name    = optional(string, "cdro")

    resource = object({
      replicas       = optional(string, "2")
      cpu_limit      = optional(string, "2")
      memory_limit   = optional(string, "32Gi")
      cpu_request    = optional(string, "2")
      memory_request = optional(string, "32Gi")
      storage        = optional(string, "20Gi")
      storage_class  = optional(string, "repo-artifacts")
      image          = optional(string, "docker.io/cloudbees/cbflow-repository:2023.10.0.169425_3.2.54_20231002")
    })

    nfs = object({
      path      = string
      server    = optional(string, "cicdfas.mobis.com")
      read_only = optional(bool, false)
    })

    env = object({
      cbf_server_host         = optional(string, "flow-server")
      cbf_server_user         = optional(string, "admin")
      cbf_local_resource_host = optional(string, "cb-flow-bound-agent")
      cbf_configure_memory    = optional(string, "--repositoryInitMemoryMB=4096 --repositoryMaxMemoryMB=4096")
    })

    secret = object({
      cbf_server_secret_name = optional(string, "cdro-cloudbees-flow-credentials")
      cbf_server_secret_key  = optional(string, "CBF_SERVER_ADMIN_PASSWORD")
    })
  }))

  default = [
    {
      app_name        = "flow-repository-1"
      claim_name      = "flow-repo-artifacts-1"
      pv_name         = "flow-repo-artifacts-1"
      service_name    = "flow-repository-1"
      policy_name     = "repository-policy-1"
      repository_name = "default-1"
      
      env             = {}
      resource        = {}
      secret          = {}
      nfs = {
        path = "/RND_Cloud/sbas_stg/build/kube_artifacts"
      }
    }
  ]
}
