# Define the provider
provider "google" {
  project = "terraform-project-450717"
  region  = "us-central1" # Change as needed
}

# Create a Google Cloud Storage bucket
resource "google_storage_bucket" "my_bucket" {
  name          = "my-terraformProject-bucket-${random_id.bucket_suffix.hex}"
  location      = "US"
  force_destroy = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }
}

# Generate a random suffix for unique resource naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Assign IAM role to a user/service account for the bucket
resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_storage_bucket.my_bucket.name
  role   = "roles/storage.objectViewer"
  member = "user:vismayparikh1112@gmail.com" # Change to your user/service account
}

# Create a firewall rule to allow SSH, HTTP, and HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a VM instance
resource "google_compute_instance" "vm_instance" {
  name         = "secure-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {
      # This assigns a public IP
    }
  }

  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Create a Service Account for the VM
resource "google_service_account" "vm_service_account" {
  account_id   = "secure-vm-sa"
  display_name = "VM Service Account"
}

# Assign IAM role to the VM service account
resource "google_project_iam_member" "vm_role" {
  project = "terraform-project-450717"
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Create a KMS Key Ring and Key for encryption
resource "google_kms_key_ring" "bucket_keyring" {
  name     = "my-keyring"
  location = "us"
}

resource "google_kms_crypto_key" "bucket_key" {
  name     = "my-crypto-key"
  key_ring = google_kms_key_ring.bucket_keyring.id
}
