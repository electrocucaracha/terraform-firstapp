# Configure TryStack Provider
provider "openstack" {
  user_name  = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password  = "${var.password}"
  auth_url  = "${var.auth_url}"
}

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

resource "openstack_compute_keypair_v2" "firstapp" {
  name = "SSH keypair for First App instances"
  region = "${var.region}"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

resource "openstack_compute_secgroup_v2" "worker" {
  name = "worker"
  region = "${var.region}"
  description = "for services that run on a worker node"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "controller" {
  name = "controller"
  region = "${var.region}"
  description = "for services that run on a control node"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 5672
    to_port = 5672
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_floatingip_v2" "firstapp" {
  depends_on = ["openstack_networking_router_interface_v2.firstapp"]
  region = "${var.region}"
  pool = "public"
}

resource "openstack_compute_instance_v2" "app-controller" {
  name = "app-controller"
  region = "${var.region}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.firstapp.name}"
  security_groups = [ "${openstack_compute_secgroup_v2.controller.name}" ]
  floating_ip = "${openstack_compute_floatingip_v2.firstapp.address}"
  user_data = "curl -L -s http://git.openstack.org/cgit/openstack/faafo/plain/contrib/install.sh | bash -s -- -i messaging -i faafo -r api"

  network {
    uuid = "${openstack_networking_network_v2.private.id}"
  }

  provisioner "local-exec" {
    command = "echo \"ssh ubuntu@${openstack_compute_floatingip_v2.firstapp.address}\" > ssh-controller.sh"
  }
}

resource "openstack_compute_instance_v2" "app-worker01" {
  depends_on = ["openstack_compute_instance_v2.app-controller"]
  name = "app-worker01"
  region = "${var.region}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.firstapp.name}"
  security_groups = [ "${openstack_compute_secgroup_v2.worker.name}" ]
  user_data = "curl -L -s http://git.openstack.org/cgit/openstack/faafo/plain/contrib/install.sh | bash -s -- -i faafo -r worker -e 'http://${openstack_compute_floatingip_v2.firstapp.address}' -m 'amqp://guest:guest@%${openstack_compute_floatingip_v2.firstapp.address}:5672/"

  network {
    uuid = "${openstack_networking_network_v2.private.id}"
  }
}
