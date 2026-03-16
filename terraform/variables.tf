variable "region" {
  default = "br-se1"
}

variable "api_key" {
  sensitive = true
}

variable "key_pair_id" {
  sensitive = true
}

variable "key_pair_secret" {
  sensitive = true
}

variable "db_password" {
  sensitive = true
}

variable "db_user" {
  default = "dbadmin"
}

variable "db_name" {
  default = "znuny"
}

variable "bucket_name" {
  default = "znuny-backup-lab"
}

variable "vm_name" {
  default = "znuny-lab-server"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  default = "~/.ssh/id_ed25519"
}

variable "znuny_version" {
  default = "7.1.3"
}

variable "znuny_admin_user" {
  default = "root@localhost"
}

variable "znuny_admin_password" {
  sensitive = true
}

