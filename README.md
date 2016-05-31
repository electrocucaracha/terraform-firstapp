terraform-firstapp
==================

This Terraform project pretends to cover those steps explained into [OpenStack firstapp guide] (http://developer.openstack.org/firstapp-libcloud/getting_started.html).  It was created only for didactic purposes.

## Requirements:

* [Terraform] (https://www.terraform.io/intro/getting-started/install.html)
* [TryStack access] (http://trystack.org/)

## Steps for execution:

    git clone https://github.com/electrocucaracha/terraform-firstapp.git
    cd  terraform-firstapp
    terraform apply -var 'user_name=TRYSTACK_USERNAME' -var 'tenant_name=TRYSTACK_PROJECT_NAME' -var 'password=TRYSTACK_PASSWORD'
    bash ssh-controller.sh 

## Destroy:

    terraform destroy
