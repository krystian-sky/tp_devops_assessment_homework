variable "region" {
  type        = string
  description = "Default region"
  default     = "eu-north-1"
}


variable "internet_cidr_block" {
  type        = string
  description = "Internet CIDR block"
  default     = "0.0.0.0/0"
}

variable "ecs_role" {
    type = string
    description = "ECS task role"
    default = "arn:aws:iam::303981612052:role/ecsTaskExecutionRole"
}

variable "name" {
    type = string
    description = "My name"
    default = "krystian-nowaczyk"
}