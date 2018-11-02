resource "aws_ecs_cluster" "cluster" {
  name = "${var.cluster}-${var.environment}"
}

module "rds" {
  source = "../rds"

  project_key        = "${var.cluster}"
  environment        = "${var.environment}"
  aws_region         = "${data.aws_region.current.name}"
  db_subnet_cidrs    = "${var.db_subnet_cidrs}"
  db_access_cidrs    = ["${concat(var.bastion_cidrs, var.private_subnet_cidrs)}"]
  vpc_id             = "${var.vpc_id}"
  availability_zones = "${var.availability_zones}"
  aws_email          = "${var.aws_email}"
  db_name            = "${var.db_name}"
  db_identifier      = "${var.cluster}-${var.environment}-pg-db"
  db_username        = "${var.db_username}"
  db_password        = "${var.db_password}"
}

module "alb" {
  source = "../alb"

  cluster           = "${var.cluster}"
  environment       = "${var.environment}"
  alb_name          = "${var.environment}-${var.cluster}"
  vpc_id            = "${var.vpc_id}"
  public_subnet_ids = "${module.network.public_subnet_ids}"
  aws_email          = "${var.aws_email}"
}

resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 61000
  protocol                 = "TCP"
  source_security_group_id = "${module.alb.alb_security_group_id}"
  security_group_id        = "${module.ecs-instances.ecs_instance_security_group_id}"
}

module "network" {
  source = "../network"

  vpc_id               = "${var.vpc_id}"
  vpc_igw              = "${var.vpc_igw}"
  cluster              = "${var.cluster}"
  environment          = "${var.environment}"
  public_subnet_cidrs  = "${var.public_subnet_cidrs}"
  private_subnet_cidrs = "${var.private_subnet_cidrs}"
  availability_zones   = "${var.availability_zones}"
  depends_id           = ""
  name                 = "${var.cluster}"
  aws_email            = "${var.aws_email}"
}

module "ecs-instances" {
  source = "../ecs-instances"

  environment             = "${var.environment}"
  cluster                 = "${var.cluster}"
  bastion_cidrs           = ["${var.bastion_cidrs}"]
  instance_group          = "${var.instance_group}"
  private_subnet_ids      = "${module.network.private_subnet_ids}"
  aws_ami                 = "${data.aws_ami.ecs_aws_ami.id}"
  aws_email               = "${var.aws_email}"
  instance_type           = "${var.instance_type}"
  max_size                = "${var.max_size}"
  min_size                = "${var.min_size}"
  desired_capacity        = "${var.desired_capacity}"
  vpc_id                  = "${var.vpc_id}"
  iam_instance_profile_id = "${aws_iam_instance_profile.ecs.id}"
  key_name                = "${var.key_name}"
  load_balancers          = "${var.load_balancers}"
  depends_id              = "${module.network.depends_id}"
  custom_userdata         = "${var.custom_userdata}"
  cloudwatch_prefix       = "${var.cloudwatch_prefix}"
}

# provides a log group for any applications deployed into this cluster to log to
resource "aws_cloudwatch_log_group" "log-group" {
  name              = "${var.cluster}/${var.environment}"
  retention_in_days = 7
}

resource "aws_kms_key" "secrets" {
  description = "master encryption key for dev, staging, and prod secrets"
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.cluster}/${var.environment}/secrets"
  target_key_id = "${aws_kms_key.secrets.key_id}"
}

resource "aws_s3_bucket" "secrets" {
  bucket = "${var.cluster}-${var.environment}-secrets"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.secrets.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags {
    Name        = "${var.cluster}-secrets"
    Project     = "${var.cluster}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
