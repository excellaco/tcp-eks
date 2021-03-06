terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  version    = "~> 2.23"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "local" {
  version = "~> 1.3"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.0"
}

# Virtual Private Cloud (VPC)
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=master"

  name = "${var.project_name}-${var.environment}"
  cidr = var.vpc_cidr_block
  azs  = [data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1]]

  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true

  tags = {
    Project = var.project_name
    Creator = var.aws_email
    Created = timestamp()
    Environment = var.environment
  }
}

# Control Network Access to RDS and EC2 Instances Using a Bastion Server
module "bastion" {
  source = "git::https://github.com/excellaco/terraform-aws-ec2-bastion-server.git?ref=master"

  name        = "bastion"
  namespace   = var.project_name
  environment = var.environment
  port        = var.db_port
  vpc_id      = module.vpc.vpc_id
  key_name    = var.project_key_name
  subnets     = module.vpc.public_subnets
  ssh_user    = var.bastion_ssh_user
  instance_type = var.bastion_instance_type
  security_groups = []
  allowed_cidr_blocks = var.ssh_cidr
  tags = {
    Project = var.project_name
    Creator = var.aws_email
    Created = timestamp()
    Environment = var.environment
  }
}

# Jenkins Open-source CI/CD Automation Server
module "jenkins" {
  source = "git::https://github.com/excellaco/terraform-aws-ec2-jenkins-server.git?ref=master"

  vpc_id                     = module.vpc.vpc_id
  environment                = var.environment
  name                       = var.project_name
  aws_email                  = var.aws_email
  aws_access_key             = var.aws_access_key
  aws_secret_key             = var.aws_secret_key
  jenkins_key_name           = var.project_key_name
  jenkins_subnet_ids         = module.vpc.public_subnets
  jenkins_private_key_path   = var.ssh_key_path
  jenkins_public_key_path    = var.ssh_key_path
  jenkins_developer_password = var.jenkins_developer_password
  jenkins_admin_password     = var.jenkins_admin_password
  github_user                = var.github_user
  github_token               = var.github_token
  github_repo_owner          = var.github_repo_owner
  github_repo_include        = var.github_repo_include
  github_branch_include      = var.github_branch_include
  github_branch_trigger      = var.github_branch_trigger
  account_id                 = data.aws_caller_identity.current.account_id
}

# Relational Database Service (RDS)
module "rds" {
  source = "git::https://github.com/excellaco/terraform-aws-rds.git?ref=master"

  name                  = var.db_name
  identifier            = "${var.environment}-${var.db_identifier}"
  username              = var.db_username
  password              = var.db_password
  port                  = var.db_port
  multi_az              = var.db_multi_availability_zone
  iops                  = var.db_iops
  allocated_storage     = var.db_size
  storage_type          = var.db_storage_type
  storage_encrypted     = var.db_storage_encrypted
  engine                = var.db_engine
  engine_version        = var.db_version
  major_engine_version  = var.db_major_version
  instance_class        = var.db_instance_class
  publicly_accessible   = var.db_publicly_accessible
  subnet_ids            = module.vpc.private_subnets
  vpc_id                = module.vpc.vpc_id
  auto_minor_version_upgrade  = var.db_auto_minor_version_upgrade
  allow_major_version_upgrade = var.db_allow_major_version_upgrade
  apply_immediately           = var.db_apply_immediately
  maintenance_window          = var.db_maintenance_window
  skip_final_snapshot         = var.db_skip_final_snapshot
  copy_tags_to_snapshot       = var.db_copy_tags_to_snapshot
  backup_retention_period     = var.db_backup_retention_period
  backup_window               = var.db_backup_window
  tags = {
    Project = var.project_name
    Creator = var.aws_email
    Created = timestamp()
    Environment = var.environment
  }
}

# Elastic Kubernetes Service (EKS)
module "eks-cluster" {
  source = "git::https://github.com/excellaco/terraform-aws-eks.git?ref=master"

  name         = var.project_name
  environment  = var.environment
  aws_email    = var.aws_email
  aws_region   = var.aws_region
  cluster_name = "${var.project_name}-${var.environment}-cluster"
  vpc_id       = module.vpc.vpc_id

  config_output_path = var.config_output_path
  cloudwatch_prefix  = "${var.project_name}/${var.environment}"
  private_subnet    = module.vpc.private_subnets
  public_subnet     = module.vpc.public_subnets
  cluster_cidrs     = var.public_subnet_cidrs

  cluster_max_size = var.cluster_max_size
  cluster_min_size = var.cluster_min_size
  desired_capacity = var.cluster_desired_capacity
  cluster_key_name = aws_key_pair.project.key_name
  instance_type    = var.cluster_instance_type
}

# Key Management Service (KMS)
resource "aws_key_pair" "project" {
  key_name   = var.project_key_name
  public_key = tls_private_key.default.public_key_openssh
  depends_on = ["local_file.public_key_openssh"]
}

resource "aws_kms_key" "project" {
  description             = "${var.project_name}-${var.environment}-kms-key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  tags = {
    Name    = "${var.project_name}-${var.environment}-kms-key"
    Project = var.project_name
    Creator = var.aws_email
    Created = timestamp()
    Environment = var.environment
  }
}

resource "aws_kms_alias" "project" {
  name = "alias/${var.project_name}-${var.environment}-kms-key"
  target_key_id = aws_kms_key.project.key_id
}

# SSH Key Creation
locals {
  public_key_filename  = "${var.ssh_key_path}/${var.project_key_name}.pub"
  private_key_filename = "${var.ssh_key_path}/${var.project_key_name}.pem"
  chmod_command = "chmod 600 %v"
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "public_key_openssh" {
  depends_on = ["tls_private_key.default"]
  content    = tls_private_key.default.public_key_openssh
  filename   = local.public_key_filename
}

resource "local_file" "private_key_pem" {
  depends_on = ["tls_private_key.default"]
  content    = tls_private_key.default.private_key_pem
  filename   = local.private_key_filename
}

resource "null_resource" "chmod" {
  count      = local.chmod_command != "" ? 1 : 0
  depends_on = ["local_file.private_key_pem"]

  provisioner "local-exec" {
    command = format(local.chmod_command, local.private_key_filename)
  }
}

resource "aws_s3_bucket" "terraform_state_storage_s3" {
  bucket = "${var.project_name}-terraform"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }
  tags = {
    Name    = "${var.project_name}-${var.environment}-s3-terraform-state"
    Project = var.project_name
    Creator = var.aws_email
    Created = timestamp()
    Environment = var.environment
  }
}

resource "local_file" "terraform_file" {
    content     = <<EOF
[default]
aws_access_key_id = var.aws_access_key
aws_secret_access_key = var.aws_secret_key
EOF
    filename = "${path.module}/../keys/aws_credentials"
}