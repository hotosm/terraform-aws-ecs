variable "project_meta" {
  description = "Metadata relating to the project for which the VPC is being created"
  type        = map(string)

  default = {
    name       = ""
    short_name = ""
    version    = ""
    url        = ""
  }
}

variable "deployment_environment" {
  description = "Deployment flavour or variant identified by this name"
  type        = string
}

variable "default_tags" {
  description = "Default resource tags to apply to AWS resources"
  type        = map(string)

  default = {
    project        = ""
    maintainer     = ""
    documentation  = ""
    cost_center    = ""
    IaC_Management = "Terraform"
  }
}

variable "container_secret_refs" {
  type = list(string)
}

variable "container_envvars" {
  type = list(string)
}

variable "container_settings" {
  type = map(string)

  default = {
    service_name     = ""
    port             = 8000
    image_url        = ""
    image_tag        = ""
    cpu_architecture = "x86_64" // or ARM64
  }
}

variable "container_capacity" {
  default = {
    cpu       = 10
    memory_mb = 512
  }
}

variable "container_security" {

  default = {
    privileged = false
  }
}

variable "efs_settings" {
  type = map(string)

  default = {
    file_system_id  = ""
    root_directory  = ""
    access_point_id = ""
  }
}

variable "tasks_desired_count" {
  type        = number
  description = "Desired count of replications for service"
}

variable "log_configuration" {

  default = {
    logdriver = "awslogs"
    options = {
      awslogs-group         = ""
      awslogs-region        = "us-east-1"
      awslogs-stream-prefix = ""
    }
  }
}

variable "linux_capabilities" {
  type = map(any)

  default = {
    add  = null
    drop = ["NET_RAW", "NET_BIND_SERVICE", "SYS_CHROOT"]
  }

  validation {
    condition = contains(
      [
        "CAP_AUDIT_CONTROL",
        "CAP_AUDIT_READ",
        "CAP_AUDIT_WRITE",
        "CAP_BLOCK_SUSPEND",
        "CAP_BPF",
        "CAP_CHECKPOINT_RESTORE",
        "CAP_CHOWN",
        "CAP_DAC_OVERRIDE",
        "CAP_DAC_READ_SEARCH",
        "CAP_FOWNER",
        "CAP_FSETID",
        "CAP_IPC_LOCK",
        "CAP_IPC_OWNER",
        "CAP_KILL",
        "CAP_LEASE",
        "CAP_LINUX_IMMUTABLE",
        "CAP_MAC_ADMIN",
        "CAP_MAC_OVERRIDE",
        "CAP_MKNOD",
        "CAP_NET_ADMIN",
        "CAP_NET_BIND_SERVICE",
        "CAP_NET_BROADCAST",
        "CAP_NET_RAW",
        "CAP_PERFMON",
        "CAP_SETGID",
        "CAP_SETFCAP",
        "CAP_SETPCAP",
        "CAP_SETUID",
        "CAP_SYS_ADMIN",
        "CAP_SYS_BOOT",
        "CAP_SYS_CHROOT",
        "CAP_SYS_MODULE",
        "CAP_SYS_NICE",
        "CAP_SYS_PACCT",
        "CAP_SYS_PTRACE",
        "CAP_SYS_RAWIO",
        "CAP_SYS_RESOURCE",
        "CAP_SYS_TIME",
        "CAP_SYS_TTY_CONFIG",
        "CAP_SYSLOG",
        "CAP_WAKE_ALARM"
      ],
      lookup(var.linux_capabilities, "add")
    )
    error_message = "Value is not a valid Linux Capabilities"
  }
}

variable "deployment_controller" {
  type = string

  default     = "ECS"
  description = "Deployment Controller"

  validation {
    condition     = contains(["ECS", "CODEDEPLOY"], var.deployment_controller)
    error_message = "Allowed values are ECS or CODEDEPLOY"
  }
}

variable "alarm_settings" {
  description = "Alarm Settings"

  default = {
    enable   = true
    names    = []
    rollback = false
  }
}

variable "scaling_target_values" {
  type = map(number)

  default = {
    cpu_pct       = 85
    memory_pct    = 85
    request_count = 50
  }
}

variable "alb_target_group" {}
variable "alb_container_name" {}
variable "alb_container_port" {}
variable "service_subnets" {}
variable "service_security_groups" {}

variable "propagate_tags_from" {
  description = "Propagate tags from SERVICE or TASK_DEFINITION"
  type        = string

  default = "SERVICE"

  validation {
    condition     = contains(["SERVICE", "TASK_DEFINITION"], var.propagate_tags_from)
    error_message = "Allowed values are SERVICE or TASK_DEFINITION"
  }
}

