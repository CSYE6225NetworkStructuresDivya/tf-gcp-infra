# tf-gcp-infra
#### Terraform setup commands
* terraform init
* terraform plan
* terraform apply
* terraform destroy

GCLOUD SET

terraform plan \
-var='vpc_name=["cloud-vpc1", "cloud-vpc2", "cloud-vpc3"]' \
-var='webapp_ip_cidr_range=162.1.0.0/24' \
-var='db_ip_cidr_range=162.2.0.0/24'


terraform apply \
-var='vpc_name=["cloud-vpc1", "cloud-vpc2", "cloud-vpc3"]' \
-var='webapp_ip_cidr_range=162.1.0.0/24' \
-var='db_ip_cidr_range=162.2.0.0/24'
