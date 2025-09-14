# Create ClusterSecretStore
resource "kubernetes_manifest" "cluster_secret_store_ssm" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-ssm"
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = var.region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = var.eso_service_account_name
                namespace = var.eso_namespace
              }
            }
          }
        }
      }
    }
  }
}

# Create ExternalSecret
resource "kubernetes_manifest" "external_secret_django_db" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "django-db"
      namespace = var.eso_namespace
    }
    spec = {
      refreshInterval = "1m"
      secretStoreRef = {
        name = "aws-ssm"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "django-db"
        creationPolicy = "Owner"
        template = {
          type = "Opaque"
        }
      }
      data = [
        {
          secretKey = "POSTGRES_HOST"
          remoteRef = { key = "${var.ssm_prefix}/host" }
        },
        {
          secretKey = "POSTGRES_USER"
          remoteRef = { key = "${var.ssm_prefix}/username" }
        },
        {
          secretKey = "POSTGRES_PASSWORD"
          remoteRef = { key = "${var.ssm_prefix}/password" }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.cluster_secret_store_ssm
  ]
}