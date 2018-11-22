provider "aws" {
  region = "${var.region}"

  profile = "${var.profile}"
  version = "1.46.0"
}
