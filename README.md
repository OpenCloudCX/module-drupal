# OpenCloudCX Drupal Module

Using this module within OpenCloudCX will provision a drupal instance. This module can be used in multiple environments depending on the providers and DNS zones being defined. It is a good idea to have all modules, providers, and namespace creation in the same file.

# Setup

Add the following module definition to the bootstrap project

```
module "drupal" {
  <source block>

  dns_zone     = "<dns zone>"
  namespace    = "<namespace>"
  drupal_email = "<drupal email>"

  providers = {
    kubernetes = <kubernetes provider reference>,
    helm       = <helm provider reference>
  }

  depends_on = [
    <eks module reference>,
  ]
}
```

# Source block

The source block will be in either of these formats

## Local filesystem

```
source = "<path to module>"
```

## Git repository

```
source = "git::ssh://git@github.com/<account or organization>/<repository>?ref=<branch>"
```

Note: If pulling from `main` branch, `?ref=<branch>` is not necessary.

## Terraform module

```
source  = "<url to terraform module>"
version = "<version>"
```

Verion formatting of the terraform source block [explained](https://www.terraform.io/docs/language/expressions/version-constraints.html)

# Providers

Provider references should be supplied through the `providers` configuration of the module. The main OpenCloudCX module will return all of the necessary information

```
provider "kubernetes" {
  host                   = module.<opencloudcx-module>.aws_eks_cluster_endpoint
  token                  = module.<opencloudcx-module>.aws_eks_cluster_auth_token
  cluster_ca_certificate = module.<opencloudcx-module>.aws_eks_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.<opencloudcx-module>.aws_eks_cluster_endpoint
    token                  = module.<opencloudcx-module>.aws_eks_cluster_auth_token
    cluster_ca_certificate = module.<opencloudcx-module>.aws_eks_cluster_ca_certificate
  }
}
```

Note: When multiple environments or cloud-providers are in use, the named module reference will need to be changed per environment.

## Module example with Git repository reference

This example also adds a `kubernetes_namespace` definition to create the namespace if one does not already exist.

```terraform
provider "kubernetes" {
  host                   = module.opencloudcx-aws-dev.aws_eks_cluster_endpoint
  token                  = module.opencloudcx-aws-dev.aws_eks_cluster_auth_token
  cluster_ca_certificate = module.opencloudcx-aws-dev.aws_eks_cluster_ca_certificate
}

resource "kubernetes_namespace" "develop" {
  metadata {
    name = "develop"
  }

  depends_on = [
    module.opencloudcx-aws-dev
  ]
}

provider "helm" {
  kubernetes {
    host                   = module.opencloudcx-aws-dev.aws_eks_cluster_endpoint
    token                  = module.opencloudcx-aws-dev.aws_eks_cluster_auth_token
    cluster_ca_certificate = module.opencloudcx-aws-dev.aws_eks_cluster_ca_certificate
  }
}

module "drupal" {
source = "git::ssh://git@github.com/OpenCloudCX/module-drupal?ref=develop"


  dns_zone     = var.dns_zone
  namespace    = "develop"
  drupal_email = "anorris@rivasolutionsinc.com"

  providers = {
    kubernetes = kubernetes,
    helm       = helm
  }

  depends_on = [
    module.opencloudcx-aws-dev,
  ]
}

```

# Credentials

|Name|URL|Username|Password Location|
|---|---|---|---|
|Drupal| ```https://drupal.[DNS ZONE]```|None|AWS Secrets Manager [```drupal```]|
|MariaDB root|N/A|None|AWS Secrets Manager [```drupal_mariadb_root```]|
|MariaDB user|N/A|bn_drupal|AWS Secrets Manager [```drupal_mariadb_user```]|

