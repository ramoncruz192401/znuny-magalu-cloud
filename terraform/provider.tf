terraform {
  required_providers {
    mgc = {
      source  = "magalucloud/mgc"
      version = ">= 0.45.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
  }
}

provider "mgc" {
  region          = var.region
  api_key         = var.api_key
  key_pair_id     = var.key_pair_id
  key_pair_secret = var.key_pair_secret
}

