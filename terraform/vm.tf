resource "mgc_virtual_machine_instances" "znuny_vm" {

  name                 = var.vm_name
  machine_type         = "BV1-1-40"
  image                = "cloud-ubuntu-24.04 LTS"
  ssh_key_name         = mgc_ssh_keys.znuny_key.name
  allocate_public_ipv4 = true

}

