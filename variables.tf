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

variable "SERVICE_DESK_EMAIL" {
  type = string
}

variable "SMTP_FROM" {
  default = ""
  type = string
}

variable "REDIS_NODE_TYPE" {
  default = "cache.t2.micro"
  type = string
}

variable "DISABLE_POSTGRES" {
  default = "false"
  type = string
}

variable "DISABLE_REDIS" {
  default = "false"
  type = string
}
