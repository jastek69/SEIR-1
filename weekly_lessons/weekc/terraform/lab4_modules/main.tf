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

# domain_name = "www.chewbacca-snacks.com"
# enable_waf  = true
# allowed_ips = ["YOUR_IP/32"]

}


module "waf" {
  source = "./modules/waf"

  name = "${local.prefix}-${var.environment}"

  enable_geo_blocking  = true
  blocked_region_codes = ["RU", "CN", "KP"]

  enable_rate_limit       = true
  rate_limit_count        = 100
  rate_limit_interval_sec = 60

  enable_waf_rules      = true
  enable_bot_management = false
}


module "postgres" {
  source = "./modules/postgres"

  name     = "${local.prefix}-${var.environment}"
  region   = var.region
  network  = module.vpc.network_id

  db_name     = "chewbacca"

  #Chewbacca (Hard Coded)
  db_user     = "chewie"
  db_password = "supersecret123"

  # Han (Security Manager)
  han_user     = "han"
  han_password = "never-tell-me-the-odds"
}
}

module "han_secret" {
  source = "./modules/secrets"

  name         = "han-db-password"
  secret_value = "never-tell-me-the-odds"
}


module "mig" {
  source = "./modules/mig"

  name       = "${local.prefix}-${var.environment}-web"
  zone       = var.zone
  network    = module.vpc.network_id
  subnetwork = module.vpc.subnet_id

#  connection_name = module.postgres.connection_name

  db_host     = module.postgres.private_ip
  db_name     = "chewbacca"
  db_user     = "chewie"
  db_user     = "han"
  db_password = "supersecret123"
}

#VPN 

module "vpn_ha" {
  source = "./modules/vpn_ha"

  name        = "${local.prefix}-${var.environment}-corp"
  region      = var.region
  network     = module.vpc.network_id
  router_name = "${local.prefix}-${var.environment}-vpn-router"

  local_bgp_asn = 64514
  peer_bgp_asn  = 65010

  peer_interface_0_ip = "203.0.113.10"
  peer_interface_1_ip = "203.0.113.11"

  shared_secret_0 = "chewbacca-parsec-0"
  shared_secret_1 = "chewbacca-parsec-1"

  bgp_ip_range_0 = "169.254.10.1/30"
  bgp_peer_ip_0  = "169.254.10.2"

  bgp_ip_range_1 = "169.254.20.1/30"
  bgp_peer_ip_1  = "169.254.20.2"
}
