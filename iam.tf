data "aws_iam_policy_document" "ecs-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs-agent" {
  description           = "ECS Task Execution Role used by ECS Agent"
  assume_role_policy    = data.aws_iam_policy_document.ecs-assume-role.json
  force_detach_policies = true
  name_prefix           = "ecs-task-execution-agent-role-"
}

data "aws_kms_alias" "secretsmanager" {
  name = "alias/aws/secretsmanager"
}

data "aws_iam_policy_document" "secrets-manager" {
  # Statement for getting secret values from Secrets Manager
  statement {
    sid = "1"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    # Dynamically reference the ARNs of the secrets
    resources = [
      for secret in var.container_secrets : secret.valueFrom
    ]
  }

  # Statement for decrypting KMS-encrypted secrets
  statement {
    sid = "2"

    actions = [
      "kms:Decrypt"
    ]

    # Reference the KMS alias for Secrets Manager
    resources = [
      data.aws_kms_alias.secretsmanager.arn
    ]
  }
}

resource "aws_iam_policy" "secrets-manager" {
  name_prefix = "secrets-manager"
  description = "IAM Policy that allows access to Secrets Manager entries"
  policy      = data.aws_iam_policy_document.secrets-manager.json
}

resource "aws_iam_role_policy_attachment" "secrets-manager" {
  role       = aws_iam_role.ecs-agent.name
  policy_arn = aws_iam_policy.secrets-manager.arn
}

resource "aws_iam_role_policy_attachment" "task-exec-role-policy-default" {
  role       = aws_iam_role.ecs-agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
