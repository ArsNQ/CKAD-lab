# Region and zone
region= "us-central1"
zone= "us-central1-a"
# number of master
count-master= 1
# number of workers
count-worker= 2
# type of machines
# e2-micro around 7$ CAD / month / per machine
# e2-small around 13$ CAD / month / per machine
# e2-medium around 25$ CAD / month / per machine
machine-type= "e2-small"
# network and subnetwork name
network-name= "kubernetes-network"
subnetwork-name= "kubernetes-subnetwork"
# firewall name
firewall-name= "kubernetes-firewall"
# tag for your firewall
firewall-target-tag= "kubernetes-firewall-target"
project-name="laboratory-kubernetes"
