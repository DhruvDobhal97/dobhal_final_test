provider "google" {
  project = "dobhal-filestore-project" # Replaced with your project ID
  region  = "us-central1"
}

# Create a custom-mode VPC (no default subnets)
resource "google_compute_network" "vpc" {
  name                    = "flask-vpc"
  auto_create_subnetworks = false # Disable default subnets
}

# Create a Public Subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# Create a Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

# Create a Compute Engine Instance with the Container in Public Subnet
resource "google_compute_instance" "flask_instance" {
  name         = "flask-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/family/cos-stable" # Container-Optimized OS
    }
  }

  network_interface {
    subnetwork   = google_compute_subnetwork.public_subnet.id
    access_config {} # Assign a Public IP
  }

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"] # Full access to GCP resources
  }

  metadata = {
    gce-container-declaration = <<EOF
    spec:
      containers:
        - name: flask-app
          image: gcr.io/dobhal-filestore-project/dobhalapp:latest
          ports:
            - containerPort: 5000
      restartPolicy: Always
    EOF
  }

  tags = ["flask-app", "allow-ssh"]
}

# Create Firewall Rules to Allow Access to Port 5000
resource "google_compute_firewall" "allow_flask" {
  name    = "allow-flask"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = ["0.0.0.0/0"] # Allow traffic from any IP
  target_tags   = ["flask-app"]
}

# Create Firewall Rules to Allow SSH Access
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Allow SSH from any IP (Restrict in production)
  target_tags   = ["allow-ssh"]
}
