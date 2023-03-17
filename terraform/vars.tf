variable "region" {
  type = string
  default = ""
}

variable "zone" {
  type = string
  default = ""
}

variable "project-name" {
  type = string
  default = ""
}

variable "count-master" {
  type = string
  default = ""
}

variable "count-worker" {
  type = string
  default = ""
}

variable "machine-type" {
  type = string
  default = ""
}

variable "network-name" {
  type = string
  default = ""
}

variable "subnetwork-name" {
  type = string
  default = ""
}

variable "firewall-name" {
  type = string
}

variable "firewall-target-tag" {
  type = string
}

