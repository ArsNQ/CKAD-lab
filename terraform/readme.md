## AUTHENTICATION
```bash
gcloud config list --format='value(core.project)'
gcloud config set project <my-gcp-project>
```

### step to reproduce
```bash
terraform init
terraform plan 
terraform apply
```

### show ip address
```bash
terraform show | grep "nat_ip"
```