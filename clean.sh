#!/bin/bash

rm -rf terraform/.terraform
rm terraform/application_default_credentials.json
rm terraform/terraform.tfstate
rm terraform/terraform.tfstate.backup
rm terraform/terraform.tfvars-E
rm terraform/.terraform.lock.hcl
rm ansible/join-command