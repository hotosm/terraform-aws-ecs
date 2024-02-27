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

variable "container_secrets" {
  description = "Secrets from secrets manager passed on to the containers"
  type = list(object({
    name      = string
    valueFrom = string
  }))

  nullable = true
}

variable "container_envvars" {
  description = "Environment variables passed on to the containers"
  type = list(object({
    name  = string
    value = string
  }))

  nullable = true
}

variable "container_settings" {
  type = object({
    service_name     = string
    app_port         = number
    image_url        = string
    image_tag        = string
    cpu_architecture = string
  })

  validation {
    condition = contains(
      ["X86_64", "ARM64"],
      lookup(var.container_settings, "cpu_architecture")
    )
    error_message = "Allowed CPU architectures are x86_64 and ARM64"
  }
}

variable "container_capacity" {
  type = map(number)
  default = {
    cpu       = 256
    memory_mb = 512
  }
}

variable "container_security" {

  default = {
    privileged = false
  }
}

variable "efs_settings" {
  description = "EFS access and encryption settings"
  type = object({
    file_system_id     = string
    root_directory     = string
    access_point_id    = string
    transit_encryption = string
    iam_authz          = string
  })

  validation {
    condition = contains(["ENABLED", "DISABLED"], lookup(var.efs_settings, "transit_encryption"))

    error_message = "Transit encryption needs to be ENABLED or DISABLED"
  }

  validation {
    condition = contains(["ENABLED", "DISABLED"], lookup(var.efs_settings, "iam_authz"))

    error_message = "IAM authorization needs to be ENABLED or DISABLED"
  }

}

variable "tasks_count" {
  type        = map(number)
  description = "Desired count of replications for service"

  default = {
    desired_count   = 2
    min_healthy_pct = 50
    max_pct         = 200
  }
}

variable "log_configuration" {
  description = "Log configuration"
  type = object({
    logdriver = string
    options = object({
      awslogs-group         = string
      awslogs-region        = string
      awslogs-stream-prefix = string
    })
  })

  validation {
    condition = contains([
      "json-file",
      "journald",
      "gelf",
      "fluentd",
      "awslogs",
      "splunk",
      "awsfirelens",
      "syslog"
      ],
    lookup(var.log_configuration, "logdriver"))
    error_message = "Valid values are awslogs, json-file, journald, gelf, fluentd, splunk, awsfirelens and syslog"
  }
}

variable "linux_capabilities" {
  type = map(list(string))

  default = {
    drop = ["NET_RAW", "NET_BIND_SERVICE", "SYS_CHROOT"]
  }

  /**
  validation {
    condition = contains(
      [
        null,
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
**/
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
  type = object({
    enable   = bool
    names    = list(string)
    rollback = bool
  })
}

variable "scaling_target_values" {
  type = object({
    cpu_pct             = number
    memory_pct          = number
    request_count       = number
    container_min_count = number
    container_max_count = number
  })

  default = {
    cpu_pct             = 85
    memory_pct          = 85
    request_count       = 50
    container_min_count = 2
    container_max_count = 20
  }

  // TODO: validation - mem_pct max 99; mem_pct min 5;
  // TODO: validation - cpu_pct max 99; cpu_pct min 5;
  // TODO: validation - container_min_count min 1; max_count min 5;
}

variable "alb_settings" {
  description = "Application Load Balancer settings"
  type = object({
    subnets             = list(string)
    health_check_path   = string
    acm_tls_cert_domain = string
    tls_cipher_policy   = string
  })
}

variable "service_settings" {
  description = "List of subnets in which services can be launched"
  type = object({
    subnets             = list(string)
    propagate_tags_from = string
  })

  validation {
    condition = contains(
      ["SERVICE", "TASK_DEFINITION"],
      lookup(var.service_settings, "propagate_tags_from")
    )
    error_message = "Valid values for tag propagation are SERVICE or TASK_DEFINITION"
  }

}

variable "aws_vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "service_security_groups" {
  description = "Security groups to attach to service"
  type        = list(string)

  default = []
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster in which to launch the services"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster in which to launch the services"
  type        = string
}
