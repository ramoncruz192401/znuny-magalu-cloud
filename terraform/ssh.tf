resource "mgc_ssh_keys" "znuny_key" {
  name = "znuny-lab-key"
  key  = trimspace(file(pathexpand(var.ssh_public_key_path)))
}
