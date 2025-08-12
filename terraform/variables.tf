variable "instance_type" {
    description = "EC2 instance type"
    type        = string
    default     = "t2.large"
}

variable "key_name" {
    description = "Name of the instance key pair"
    type        = string
    default     = "vockey"
}

variable "ami" {
    description = "Ubuntu Server 24.04 LTS (HVM)"
    type        = string
    default     = "ami-04b4f1a9cf54c11d0"
}

variable "zone" {
    description = "Availability Zone"
    type        = string
    default     = "us-east-1a"
}