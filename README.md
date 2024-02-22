# tf-gcp-infra
#### Terraform commands
* terraform init
* terraform plan
* terraform apply
* terraform destroy

#### GCLOUD SETUP
gcloud init -> create a new configuration, add a new project
go to google console and verify that the project is created
Now go to IAM & Admin -> Service Accounts -> Create Service Account
Create a new service account and download the json file from keys
add the keys to your project and in provider provide the project_id and the credentials file path

Define your resources
run terraform init
then run terraform plan
then run terraform apply

all the resources will be created in the google cloud platform

#### Terraform commands to create resources at command line
terraform plan \
-var='vpc_name=["cloud-vpc1", "cloud-vpc2", "cloud-vpc3"]' \
-var='webapp_ip_cidr_range=162.1.0.0/24' \
-var='db_ip_cidr_range=162.2.0.0/24'

terraform plan \
-var='vpc_name=["vpc-test"]' \
-var='webapp_ip_cidr_range=162.1.0.0/24' \
-var='db_ip_cidr_range=162.2.0.0/24'

terraform apply \
-var='vpc_name=["cloud-vpc1", "cloud-vpc2", "cloud-vpc3"]' \
-var='webapp_ip_cidr_range=162.1.0.0/24' \
-var='db_ip_cidr_range=162.2.0.0/24'
