#!/bin/bash
# Set the path to the Terraform variables file
tfvars_file="terraform/terraform.tfvars"

# Log in to gcloud
gcloud auth login

# Log in to application-default credentials and get the JSON key file path
gcloud auth application-default login > output.txt 2>&1
creds=$(grep -o -E '/[a-zA-Z0-9_/.-]+\.json' output.txt | awk 'NR==1')
cp $creds ./terraform

# Remove the output file
rm output.txt

# List available projects
gcloud projects list

# Ask the user for the project name
read -p "Enter the name of your GCP Project: " project_name

# Escape special characters in project_name
escaped_project_name=$(echo "$project_name" | sed -e 's/[\/&]/\\&/g')

# Check if the project name exists in the Terraform variables file
if grep -qE '^project.*' "$tfvars_file"; then
  # If it exists, replace the existing value
  sed -i -E "s/^project.*$/project-name=\"$escaped_project_name\"/" "$tfvars_file"
else
  # If it doesn't exist, add it to the end of the file
  echo "project-name=\"$escaped_project_name\"" >> "$tfvars_file"
fi

# Initialize Terraform
terraform -chdir=terraform/ init

# Generate Terraform execution plan
terraform -chdir=terraform/ plan

# Apply the Terraform execution plan
terraform -chdir=terraform/ apply --auto-approve

# Get the IP address of the Kubernetes master
ip_address=$(terraform -chdir=terraform/ output -json public_ip_master | jq -r '.[] | .[]')

# Escape special characters in project_name
escaped_project_name=$(echo "$ip_address" | sed -e 's/[\/&]/\\&/g')

# Define the file path to update
file_path="ansible/setupMaster/vars/main.yml"

# Check if the IP address exists in the file
if grep -qE '^ip.*' "$file_path"; then
  # If it exists, replace the existing value
  awk -v escaped_project_name="$escaped_project_name" 'BEGIN {FS=":"; OFS=":"} /^ip/ {$2=" "escaped_project_name}1' "$file_path" > tmpfile && mv tmpfile "$file_path"
else
  # If it doesn't exist, add it to the end of the file
  echo "ip_master: $escaped_project_name" >> "$file_path"
fi

# Get the IP addresses of the machines created with Terraform
IP_ADDRESSES_MASTER=$(terraform -chdir=terraform/ output -json public_ip_master | jq -r '.[] | .[]')
IP_ADDRESSES_WORKERS=$(terraform -chdir=terraform/ output -json public_ip_worker | jq -r '.[] | .[]')

# Initialize variables for the number of masters and workers
num_master=0
num_worker=0

# Write the IP addresses of the masters to the Ansible hosts file
echo "[all:vars]" > ansible/hosts
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ansible/hosts
echo "[k8sMasters]" >> ansible/hosts
for IP_ADDRESSES_MASTER in $IP_ADDRESSES_MASTER; do
    hostname_master="kubernetes-master-$(printf "%02d" $num_master)"
    echo "${hostname_master} ansible_host=$IP_ADDRESSES_MASTER ansible_user=ubuntu" >> ansible/hosts
    num_master=$((num_master + 1))
done

# Write the IP addresses of the workers to the Ansible hosts file.
echo "[k8sWorkers]" >> ansible/hosts

# Loop over each worker IP address and add it to the Ansible hosts file.
for IP_ADDRESSES_WORKERS in $IP_ADDRESSES_WORKERS; do
    # Create a hostname for the worker using printf with leading zeros.
    hostname_worker="kubernetes-worker-$(printf "%02d" $num_worker)"
    # Write the hostname, IP address, and username to the Ansible hosts file.
    echo "${hostname_worker} ansible_host=$IP_ADDRESSES_WORKERS ansible_user=ubuntu" >> ansible/hosts
    # Increment the worker number for the next hostname.
    num_worker=$((num_worker + 1))
done

# Wait 45 seconds for the Kubernetes API server to become available.
sleep 45

# Run the Ansible playbook with the inventory file we just created.
ansible-playbook -i ansible/hosts ansible/playbook.yml