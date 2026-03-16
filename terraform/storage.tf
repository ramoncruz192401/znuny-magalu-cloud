resource "mgc_object_storage_buckets" "znuny_bucket" {

  bucket     = var.bucket_name
  versioning = true

}

