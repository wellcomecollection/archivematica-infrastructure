resource "aws_ecr_repository" "archivematica-ecr-dashboard-repository" {
  name = "uk.ac.wellcome/archivematica_dashboard"
}


resource "aws_ecr_repository" "archivematica-ecr-storage-service-repository" {
  name = "uk.ac.wellcome/archivematica_storage_service"
}