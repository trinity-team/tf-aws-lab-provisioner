# Configure the AWS Provider
provider "aws" {
  region = var.prod_region
}

provider "aws" {
  alias  = "prod_region"
  region = var.prod_region
}

provider "aws" {
  alias  = "dr_region"
  region = var.dr_region
}