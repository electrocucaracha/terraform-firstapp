output "controller-ip-address" {
    value = "${openstack_compute_floatingip_v2.firstapp.address}"
}
