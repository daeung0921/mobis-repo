module "cdro-repos" {
  source = "./modules/terraform-k8s-cdro-repo"
  # [TODO] : 여기에서 Repository Resource 정보를 변경하세요
  config = [
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
        path = "/RND_Cloud/sbas_stg/build/kube_artifacts-1" # 유효한 경로로 변경하세요.
      }
    }, 
    # 하나만 추가하는 경우 아래 {} 을 삭제하세요.
    {
      app_name        = "flow-repository-2"
      claim_name      = "flow-repo-artifacts-2"
      pv_name         = "flow-repo-artifacts-2"
      service_name    = "flow-repository-2"
      policy_name     = "repository-policy-2"
      repository_name = "default-2"
      
      env             = {}
      resource        = {}
      secret          = {}
      nfs = {
        path = "/RND_Cloud/sbas_stg/build/kube_artifacts-2" # 유효한 경로로 변경하세요.
      }
    }
  ]
}
 
