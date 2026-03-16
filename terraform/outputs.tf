output "vm_ip" {
  value = mgc_virtual_machine_instances.znuny_vm.ipv4
}

output "database_id" {
  value = mgc_dbaas_instances.znuny_db.id
}

output "database_host" {
  value = try(data.mgc_dbaas_instance.znuny_db_info.addresses[0].address, "pending")
}

output "bucket_url" {
  value = mgc_object_storage_buckets.znuny_bucket.url
}

output "znuny_url" {
  value = "http://${mgc_virtual_machine_instances.znuny_vm.ipv4}/znuny/index.pl"
}

output "znuny_admin_user" {
  value = var.znuny_admin_user
}

output "znuny_admin_password" {
  value     = var.znuny_admin_password
  sensitive = true
}

