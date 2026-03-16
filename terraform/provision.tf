resource "null_resource" "znuny_install" {
  depends_on = [
    mgc_virtual_machine_instances.znuny_vm,
    mgc_dbaas_instances.znuny_db,
    mgc_object_storage_buckets.znuny_bucket,
    data.mgc_dbaas_instance.znuny_db_info,
  ]

  triggers = {
    vm_id            = mgc_virtual_machine_instances.znuny_vm.id
    db_id            = mgc_dbaas_instances.znuny_db.id
    bucket           = mgc_object_storage_buckets.znuny_bucket.bucket
    script_hash      = filesha256("${path.module}/scripts/install_znuny.sh")
    znuny_version    = var.znuny_version
    admin_user       = var.znuny_admin_user
    admin_pass_hash  = sha256(var.znuny_admin_password)
    db_pass_hash     = sha256(var.db_password)
  }

  connection {
    type        = "ssh"
    host        = mgc_virtual_machine_instances.znuny_vm.ipv4
    user        = "ubuntu"
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_znuny.sh"
    destination = "/tmp/install_znuny.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_znuny.sh",
      "sudo DB_HOST='${data.mgc_dbaas_instance.znuny_db_info.addresses[0].address}' DB_NAME='${var.db_name}' DB_USER='${var.db_user}' DB_PASS='${var.db_password}' BUCKET_NAME='${mgc_object_storage_buckets.znuny_bucket.bucket}' OBJ_KEY_ID='${var.key_pair_id}' OBJ_KEY_SECRET='${var.key_pair_secret}' ZNUNY_VERSION='${var.znuny_version}' ZNUNY_ADMIN_USER='${var.znuny_admin_user}' ZNUNY_ADMIN_PASS='${var.znuny_admin_password}' /tmp/install_znuny.sh"
    ]
  }
}
