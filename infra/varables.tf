
variable "iam_role_arn" {
  type    = string
}

variable "application_name" {
  type    = string
  default = "terraform-slack-notification"
}

variable "docker_image_in_ecr" {
  type  = string 
}

variable "terraform_slack_notification_ecr_secret_arn" {
  type = string 
}