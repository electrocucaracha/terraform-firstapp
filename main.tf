# Configure TryStack Provider
provider "openstack" {
  user_name  = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password  = "${var.password}"
  auth_url  = "${var.auth_url}"
}

# Template for controller installation
resource "template_file" "controller_bash" {
    template = "${file("controller.tpl")}"
}

# Template for worker installation
resource "template_file" "worker_bash" {
    template = "${file("worker.tpl")}"
    vars {
        controller_ip = "${openstack_compute_floatingip_v2.firstapp.address}"
    }
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
    from_group_id = "${openstack_compute_secgroup_v2.worker.id}"
  }
}

resource "openstack_compute_instance_v2" "app-controller" {
  name = "app-controller"
  region = "${var.region}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.firstapp.name}"
  security_groups = [ "${openstack_compute_secgroup_v2.controller.name}" ]
  floating_ip = "${openstack_compute_floatingip_v2.firstapp.address}"
  user_data = "${template_file.controller_bash.rendered}"

  network {
    uuid = "${openstack_networking_network_v2.private.id}"
  }

  provisioner "local-exec" {
    command = "echo \"ssh ubuntu@${openstack_compute_floatingip_v2.firstapp.address}\" > ssh-controller.sh"
  }
}

resource "openstack_compute_instance_v2" "app-worker" {
  depends_on = ["openstack_compute_instance_v2.app-controller"]
  count = 2
  name = "app-worker${count.index + 1}"
  region = "${var.region}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  security_groups = [ "${openstack_compute_secgroup_v2.worker.name}" ]
  user_data = "${template_file.worker_bash.rendered}"

  network {
    uuid = "${openstack_networking_network_v2.private.id}"
  }
}
