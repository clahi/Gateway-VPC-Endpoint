variable "aws_region" {
  description = "The region for our vpc"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The type of instnace we are going to spin up"
  default     = "t3.micro"
}