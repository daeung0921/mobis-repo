resource "local_file" "flow_repository_deployment" {
  for_each = { for cfg in var.config : cfg.app_name => cfg }

  content = <<-EOT
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: ${each.value.app_name}
    namespace: ${each.value.namespace}
    labels:
      app: ${each.value.app_name}
      release: ${each.value.release_name}
  spec:
    replicas: ${each.value.resource.replicas}
    selector:
      matchLabels:
        app: ${each.value.app_name}
        release: ${each.value.release_name}
    strategy:
      type: Recreate
    template:
      metadata:
        labels:
          app: ${each.value.app_name}
          release: ${each.value.release_name}
      spec:
        containers:
        - name: ${each.value.app_name}
          image: ${each.value.resource.image}
          imagePullPolicy: IfNotPresent
          env:
          - name: CBF_REPOSITORY_NAME
            value: ${each.value.repository_name}
          - name: PUBLIC_HOSTNAME
            value: ${each.value.app_name}
          - name: CBF_SERVER_HOST
            value: ${each.value.env.cbf_server_host}
          - name: CBF_SERVER_PASSWORD
            valueFrom:
              secretKeyRef:
                name: ${each.value.secret.cbf_server_secret_name}
                key: ${each.value.secret.cbf_server_secret_key}
          - name: CBF_SERVER_USER
            value: ${each.value.env.cbf_server_user}
          - name: CBF_LOCAL_RESOURCE_HOST
            value: ${each.value.env.cbf_local_resource_host}
          - name: CBF_CONFIGURE
            value: ${each.value.env.cbf_configure_memory}
          resources:
            limits:
              cpu: ${each.value.resource.cpu_limit}
              memory: ${each.value.resource.memory_limit}
            requests:
              cpu: ${each.value.resource.cpu_request}
              memory: ${each.value.resource.memory_request}
          ports:
          - containerPort: 8200
            name: p3-repository
            protocol: TCP
          livenessProbe:
            exec:
              command:
              - /opt/cbflow/health-check
            initialDelaySeconds: 120
            periodSeconds: 10
            timeoutSeconds: 5
          readinessProbe:
            initialDelaySeconds: 120
            periodSeconds: 5
            tcpSocket:
              port: 8200
            timeoutSeconds: 5
        nodeSelector:
          type: physical
          usage: sys
        serviceAccountName: default
        volumes:
        - name: repository-data-volume
          persistentVolumeClaim:
            claimName: ${each.value.claim_name}
        - name: logback-config
          configMap:
            name: flow-logging-config
  EOT

  filename = "${path.root}/debug/deployment_${each.value.app_name}.yaml"

}

resource "local_file" "flow_repository_service" {
  for_each = { for cfg in var.config : cfg.service_name => cfg }

  content = <<-EOT
  apiVersion: v1
  kind: Service
  metadata:
    name: ${each.value.service_name}
    namespace: ${each.value.namespace}
    labels:
      app: ${each.value.app_name}
      release: ${each.value.release_name}
  spec:
    selector:
      app: ${each.value.app_name}
      release: ${each.value.release_name}
    type: ClusterIP
    ports:
    - name: ef-repository
      port: 8200
      protocol: TCP
      targetPort: p3-repository
  EOT

  filename = "${path.root}/debug/service_${each.value.app_name}.yaml"
}

resource "local_file" "flow_repository_pv" {
  for_each = { for cfg in var.config : cfg.pv_name => cfg }

  content = <<-EOT
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: ${each.value.pv_name}
  spec:
    accessModes:
    - ReadWriteMany
    capacity:
      storage: ${each.value.resource.storage}
    persistentVolumeReclaimPolicy: Retain
    nfs:
      path: ${each.value.nfs.path}
      readOnly: false
      server: ${each.value.nfs.server}
    storageClassName: ${each.value.resource.storage_class}
  EOT

  filename = "${path.root}/debug/pv_${each.value.app_name}.yaml"
}

resource "local_file" "flow_repository_pvc" {
  for_each = { for cfg in var.config : cfg.claim_name => cfg }

  content = <<-EOT
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: ${each.value.claim_name}
    namespace: ${each.value.namespace}
  spec:
    accessModes:
    - ReadWriteMany
    resources:
      requests:
        storage: ${each.value.resource.storage}
    storageClassName: ${each.value.resource.storage_class}
    volumeName: ${each.value.pv_name}
    volumeMode: Filesystem
  EOT

  filename = "${path.root}/debug/pvc_${each.value.app_name}.yaml"
}

resource "local_file" "flow_repository_policy" {
  for_each = { for cfg in var.config : "${cfg.namespace}-${cfg.app_name}" => cfg }

  content = <<-EOT
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: ${each.value.policy_name}
    namespace: ${each.value.namespace}
    labels:
      app: ${each.value.app_name}
      release: ${each.value.release_name}
  spec:
    podSelector:
      matchLabels:
        app: ${each.value.app_name}
        release: ${each.value.release_name}
    ingress:
    - from:
      - podSelector:
          matchLabels:
            app: cb-flow-bound-agent-flow-agent
            release: ${each.value.release_name}
      - podSelector:
          matchLabels:
            app: flow-server
            release: ${each.value.release_name}
      - ipBlock:
          cidr: 0.0.0.0/0
      ports:
      - port: 8200
        protocol: TCP
    policyTypes:
    - Ingress
  EOT

  filename = "${path.root}/debug/policy_${each.value.app_name}.yaml"
}
