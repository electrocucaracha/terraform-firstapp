resource "openstack_networking_network_v2" "private" {
  name = "private"
  region = "${var.region}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "private_subnet01" {
  name = "private_subnet01"
  region = "${var.region}"
  network_id = "${openstack_networking_network_v2.private.id}"
  cidr = "192.168.50.0/24"
  ip_version = 4
  enable_dhcp = "true"
  dns_nameservers = ["8.8.4.4","8.8.8.8"]
}

resource "openstack_networking_router_v2" "router" {
  name = "router"
  region = "${var.region}"
  admin_state_up = "true"
  external_gateway = "${var.external_gateway}"
}

resource "openstack_networking_router_interface_v2" "firstapp" {
  region = "${var.region}"
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.private_subnet01.id}"
}

resource "openstack_compute_floatingip_v2" "firstapp" {
  depends_on = ["openstack_networking_router_interface_v2.firstapp"]
  region = "${var.region}"
  pool = "public"
}
