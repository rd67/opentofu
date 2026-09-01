# Auth is resolved via Application Default Credentials.
# Run `gcloud auth application-default login` before `tofu apply`,
# or set GOOGLE_APPLICATION_CREDENTIALS to a service-account key file.
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
