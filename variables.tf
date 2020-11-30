variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "AWS_REGION" {}

variable "ENVIRONMENT_NAME" {}

variable "SHORT_ENVIRONMENT_NAME" {}

variable "POSTGRES_ALLOCATED_STORAGE" {
    default = 20
    type = number
}

variable "POSTGRES_INSTANCE_CLASS" {
    default = "db.t2.micro"
    type = string
}

variable "EC2_INSTANCE_TYPE" {
    default = "t2.micro"
    type = string
}
