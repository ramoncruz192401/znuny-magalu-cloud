resource "mgc_dbaas_instances" "znuny_db" {

  name           = "znunydb"
  instance_type  = "DP2-8-40"
  volume_size    = 50
  engine_name    = "mysql"
  engine_version = "8.0"
  user           = var.db_user
  password       = var.db_password

}

