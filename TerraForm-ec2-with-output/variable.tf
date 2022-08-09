variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "terraform_vm"
}

variable "ami_id" {
  description = "value of ami"
  type        = string
  default     = "ami-090fa75af13c156b4"
}
variable "instance_type" {
  description = "value of instance type"
  type        = string
  default     = "t2.micro"
} 