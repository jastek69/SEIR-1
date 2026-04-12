module "vpc" {
  source = "./modules/vpc"

  network_name = local.network_name
  subnet_name  = local.subnet_name
  region       = var.region
}

module "gke" {
  source = "./modules/gke"

  cluster_name = local.cluster_name
  zone         = var.zone
  project_id   = var.project_id

  network    = module.vpc.network_id
  subnetwork = module.vpc.subnet_id
}

module "lb" {
  source = "./modules/lb"

  name           = "${local.prefix}-${var.environment}-lb"
  region         = var.region
  instance_group = module.mig.instance_group
}
