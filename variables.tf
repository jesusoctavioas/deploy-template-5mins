variable "ENVIRONMENT_NAME" {}

variable "SHORT_ENVIRONMENT_NAME" {}

variable "PG_ALLOCATED_STORAGE" {
  default = 20
  type = number
}

variable "PG_INSTANCE_CLASS" {
  default = "db.t2.micro"
  type = string
}

variable "EC2_INSTANCE_TYPE" {
  default = "t2.micro"
  type = string
}

variable "SMTP_FROM" {
  default = ""
  type = string
}
