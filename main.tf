terraform {
  required_providers {
    kubernetes = {}
    helm       = {}
  }
}

# Kubernetes nginx ingress
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [
    helm_release.drupal,
  ]
}

# Route53 dns zone
data "aws_route53_zone" "vpc" {
  name = var.dns_zone
}

## Secrets

# User
resource "aws_secretsmanager_secret" "drupal_secret" {
  name                    = "drupal"
  recovery_window_in_days = 0
}

resource "random_password" "drupal_password" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret_version" "drupal_secret_version" {
  secret_id     = aws_secretsmanager_secret.drupal_secret.id
  secret_string = "{\"username\": \"user\", \"password\": \"${random_password.drupal_password.result}\"}"
}

resource "kubernetes_secret" "drupal_secret" {
  metadata {
    name      = "drupal-password"
    namespace = "develop"
  }

  data = {
    password = random_password.drupal_password.result
  }

  type = "kubernetes.io/basic-auth"
}

# Database
resource "aws_secretsmanager_secret" "mariadb_root_secret" {
  name                    = "drupal_mariadb_root"
  recovery_window_in_days = 0
}

resource "random_password" "mariadb_root_password" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret_version" "mariadb_root_secret_version" {
  secret_id     = aws_secretsmanager_secret.mariadb_root_secret.id
  secret_string = "{\"password\": \"${random_password.mariadb_root_password.result}\"}"
}

resource "kubernetes_secret" "drupal_mariadb_root_secret" {
  metadata {
    name      = "drupal-mariadb-root-password"
    namespace = "develop"
  }

  data = {
    password = random_password.mariadb_root_password.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "aws_secretsmanager_secret" "mariadb_secret" {
  name                    = "drupal_mariadb_user"
  recovery_window_in_days = 0
}

resource "random_password" "mariadb_password" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret_version" "mariadb_secret_version" {
  secret_id     = aws_secretsmanager_secret.mariadb_secret.id
  secret_string = "{\"username\": \"bn_drupal\", \"password\": \"${random_password.mariadb_password.result}\"}"
}

## Helm chart
resource "helm_release" "drupal" {
  name             = "drupal"
  chart            = var.helm_chart_name
  namespace        = var.namespace
  repository       = var.helm_chart
  timeout          = var.helm_timeout
  version          = var.helm_version
  create_namespace = false
  reset_values     = false

  set {
    name  = "drupalPassword"
    value = random_password.drupal_password.result
  }

  set {
    name  = "drupalEmail"
    value = var.drupal_email
  }

}

## Ingress
resource "kubernetes_ingress" "ingress" {

  wait_for_load_balancer = true

  metadata {
    name      = "drupal"
    namespace = "develop"

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = "cert-manager"
    }
  }
  spec {
    rule {

      host = "drupal.${var.dns_zone}"

      http {
        path {
          path = "/"
          backend {
            service_name = "drupal"
            service_port = 80
          }
        }
      }
    }

    tls {
      secret_name = "drupal-tls-secret"
    }
  }

  depends_on = [
    helm_release.drupal,
  ]
}

## DNS record
resource "aws_route53_record" "drupal_cname" {
  zone_id = data.aws_route53_zone.vpc.zone_id
  name    = "drupal.${var.dns_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [
    helm_release.drupal
  ]
}
