variable "namespace" {
  type = string
}

variable "drupal_email" {
  type = string
}

variable "dns_zone" {
  type    = string
  default = "opencloudcx.internal"
}

variable "helm_chart" {
  type    = string
  default = "https://charts.bitnami.com/bitnami"
}

variable "helm_chart_name" {
  type    = string
  default = "drupal"
}

variable "helm_version" {
  type    = string
  default = "10.4.5"
}

variable "helm_timeout" {
  description = "Timeout value to wait for helm chart deployment"
  type        = number
  default     = 600
}

