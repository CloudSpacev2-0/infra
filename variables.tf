variable "dockerhub_user" {
  description = "Docker Hub username that owns the public images"
  type        = string
}

variable "image_tag" {
  description = "Image tag to deploy (commit SHA from GitHub Actions, or latest)"
  type        = string
  default     = "latest"
}

variable "prefix" {
  description = "Name prefix for all resources (lowercase letters/digits/hyphens)"
  type        = string
  default     = "beyondlocalhost"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "northeurope"
}

variable "subscription_id" {
  description = "Azure subscription ID (optional if set by az login / ARM_SUBSCRIPTION_ID)"
  type        = string
  default     = null
}
