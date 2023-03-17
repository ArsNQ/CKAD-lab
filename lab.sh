#!/bin/bash
tfvars_file="terraform/terraform.tfvars"

gcloud auth login > output.txt 2>&1
creds_file=$(grep -o -E '/[a-zA-Z0-9_/.-]+\.json' output.txt | awk 'NR==1')
cp $creds_file ./terraform

rm output.txt

gcloud projects list

# Ask the user for the project name
read -p "Enter the name of your GCP Project: " project_name

# Escape special characters in project_name
escaped_project_name=$(echo "$project_name" | sed -e 's/[\/&]/\\&/g')

# Check if project exists in the tfvars file
if grep -qE '^project.*' "$tfvars_file"; then
  # If it exists, replace the existing value
  sed -i -E "s/^project.*$/project-name=\"$escaped_project_name\"/" "$tfvars_file"
else
  # If it doesn't exist, add it to the end of the file
  echo "project-name=\"$escaped_project_name\"" >> "$tfvars_file"
fi

terraform -chdir=terraform/ init
terraform -chdir=terraform/ plan
terraform -chdir=terraform/ apply --auto-approve

# Get the IP address of the Kubernetes master
ip_address=$(terraform -chdir=terraform/ output -json public_ip_master | jq -r '.[] | .[]')

# Escape special characters in project_name
escaped_project_name=$(echo "$ip_address" | sed -e 's/[\/&]/\\&/g')

# Check if ip exists in the tfvars file
if grep -qE '^ip.*' ansible/setupMaster/vars/main.yml; then
  # If it exists, replace the existing value
  sed -i -E "s/^ip.*$/ip_master: $escaped_project_name/" ansible/setupMaster/vars/main.yml
else
  # If it doesn't exist, add it to the end of the file
  echo "ip_master: $escaped_project_name" >> ansible/setupMaster/vars/main.yml
fi


# Récupère les adresses IP des machines créées avec Terraform.
IP_ADDRESSES_MASTER=$(terraform -chdir=terraform/ output -json public_ip_master | jq -r '.[] | .[]')
IP_ADDRESSES_WORKERS=$(terraform -chdir=terraform/ output -json public_ip_worker | jq -r '.[] | .[]')

num_master=0
num_worker=0

# Écrit les adresses IP des masters dans le fichier Ansible hosts.
echo "[k8sMasters]" > ./ansible/hosts
for IP_ADDRESSES_MASTER in $IP_ADDRESSES_MASTER; do
    hostname_master="kubernetes-master-$(printf "%02d" $num_master)"
    echo "${hostname_master} ansible_host=$IP_ADDRESSES_MASTER ansible_user=ubuntu" >> ./ansible/hosts
    num_master=$((num_master + 1))
done

# Écrit les adresses IP des workers dans le fichier Ansible hosts.
echo "[k8sWorkers]" >> ./ansible/hosts
for IP_ADDRESSES_WORKERS in $IP_ADDRESSES_WORKERS; do
    hostname_worker="kubernetes-worker-$(printf "%02d" $num_worker)"
    echo "${hostname_worker} ansible_host=$IP_ADDRESSES_WORKERS ansible_user=ubuntu" >> ./ansible/hosts
    num_worker=$((num_worker + 1))
done

#ssh -T -F ./ansible/ansible.cfg localhost "ansible-playbook -i ./ansible/hosts ./ansible/playbook.yml"
ansible-playbook -i ./ansible/hosts -c ./ansible/ansible.cfg ./ansible/playbook.yml