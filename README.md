# Terraform state bug
Everytime I run `terraform apply` I get a different set of changes, when it shouldn't be the cases.

# Steps to reproduce
- Configure AWS credentials of an AWS account
- `terraform init`
- `terraform apply`
- `terraform apply` # This time you should see that some security group rules will be applied again.
- `terraform apply` # You'll see a different set of changes.


