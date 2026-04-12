resource "google_compute_health_check" "http" {
  name = "${var.name}-hc"

  http_health_check {
    request_path = "/"
    port         = 80
  }
}


resource "google_compute_backend_service" "backend" {
  name          = "${var.name}-backend"
  protocol      = "HTTP"
  timeout_sec   = 10
  health_checks = [google_compute_health_check.http.id]

  backend {
    group = var.instance_group
  }
  # security_policy = google_compute_security_policy.waf.id 
}

#URL Map

resource "google_compute_url_map" "url_map" {
  name            = "${var.name}-urlmap"
  default_service = google_compute_backend_service.backend.id
}

# Target HTTP Proxy

resource "google_compute_target_http_proxy" "proxy" {
  name    = "${var.name}-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Global IP

resource "google_compute_global_address" "ip" {
  name = "${var.name}-ip"
}

#Forwarding Rule

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "${var.name}-fw"
  target     = google_compute_target_http_proxy.proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.ip.address
}

resource "google_compute_managed_ssl_certificate" "cert" {
  name = "${var.name}-cert"

  managed {
    domains = [var.domain_name]
  }
}

# HTTPS PRoxy

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}

# Forwarding Rule (443)

resource "google_compute_global_forwarding_rule" "https" {
  name       = "${var.name}-https"
  target     = google_compute_target_https_proxy.https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.ip.address
}

# URL map split

resource "google_compute_url_map" "https_map" {
  name            = "${var.name}-https-map"
  default_service = google_compute_backend_service.backend.id
}

resource "google_compute_url_map" "http_redirect" {
  name = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

# Redirect

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

# HTTP forwarding rule

resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.name}-http"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.ip.address
}


