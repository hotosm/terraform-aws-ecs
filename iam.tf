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
  statement {
    sid = "1"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = tolist([for o in var.container_secrets : o["valueFrom"]])
  }

  statement {
    sid = "2"

    actions = [
      "kms:Decrypt"
    ]

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
