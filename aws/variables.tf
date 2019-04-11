data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}

variable "aws_account_id" {
  type        = "string"
  default     = "090999229429"
  description = "AWS Account Identity"
}

variable "project_name" {
  type        = "string"
  default     = "bench-tc"
  description = "prefix for all created resources"
}

variable "environment" {
  type        = "string"
  default     = "development"
  description = "Environment i.e. production or development"
}

variable "aws_access_key" {
  type        = "string"
  default     = ""
  description = "the user aws access key"
}

variable "aws_secret_key" {
  type        = "string"
  default     = ""
  description = "the user aws secret key"
}

variable "aws_email" {
  type        = "string"
  default     = ""
  description = "the user email address"
}

variable "rds_port" {
  default = "5432"
}

variable "ssh_cidr" {
  type    = "list"
  default = ["76.76.0.0/16"]
}

variable "vpc_cidr_block" {
  type        = "string"
  default     = "10.0.0.0/16"
  description = "Virtual Private Cloud Classless Inter-Domain Routing"
}

variable "public_subnet_cidrs" {
  type        = "list"
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  description = "The cidrs the public subnet should reside in"
}

variable "private_subnet_cidrs" {
  type        = "list"
  default     = ["10.0.50.0/24", "10.0.51.0/24"]
  description = "The cidrs the private subnet should reside in"
}

## Bastion

variable "bastion_instance_type" {
  type    = "string"
  default = "t2.micro"
}

variable "bastion_key_name" {
  type        = "string"
  description = "the ssh key pair to use for the bastion EC2 instance"
}

variable "bastion_public_key_path" {
  default     = "../keys/bench-tc-bastion.pub"
  description = "path to bastion public key"
}

variable "bastion_ssh_user" {
  type    = "string"
  default = "ubuntu"
}

## Cluster

variable "cluster_cidrs" {
  type        = "list"
  default     = []
  description = "The cidrs the cluster should reside in"
}

variable "cluster_max_size" {
  default = 4
}

variable "cluster_min_size" {
  default = 1
}

variable "cluster_desired_capacity" {
  default = 2
}

variable "cluster_instance_type" {
  default = "t2.large"
}

variable "cluster_key_name" {
  description = "the ssh key pair to use for the EC2 instances making up the cluster"
}

variable "cluster_public_key_path" {
  default     = "../keys/bench-tc-cluster.pub"
  description = "path to cluster public key"
}

variable "config_output_path" {
  default = "./"
}

## Database

variable "db_engine" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) The database engine to use."
  default     = "postgres"
}

variable "db_instance_class" {
  description = "(Required) The instance type of the RDS instance."
  default     = "db.t2.medium"
}

variable "db_param_family" {
  description = "(Optional) Name of the DB parameter group to associate."
  default     = "postgres10"
}

variable "db_size" {
  description = "allocated_storage (Required unless a snapshot_identifier or replicate_source_db is provided) The allocated storage in gibibytes."
  default     = 20
}

variable "db_version" {
  description = "engine_version (Optional) The engine version to use. If auto_minor_version_upgrade is enabled, you can provide a prefix of the version"
  default     = "10.4"
}

variable "db_major_version" {
  description = "major_engine_version (Optional) The major engine version to use."
  default     = "10"
}

variable "db_port" {
  description = "(Optional) The port on which the DB accepts connections."
  default     = 5432
}

variable "db_identifier" {
  default     = "pg-bench-db"
  description = "(Forces new resource) The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier."
}

variable "db_name" {
  default     = "benchdb"
  description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance. Note that this does not apply for Oracle or SQL Server engines. See the AWS documentation for more details on what applies for those engines."
}

variable "db_username" {
  default     = "benchtc"
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Username for the master DB user."
}

variable "db_password" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file."
}

variable "db_storage_type" {
  description = "(Optional) One of standard (magnetic), gp2 (general purpose SSD), or io1 (provisioned IOPS SSD). The default is io1 if iops is specified, standard if not. Note that this behaviour is different from the AWS web console, where the default is gp2."
  default     = "gp2"
}

variable "db_storage_encrypted" {
  description = "(Optional) Specifies whether the DB instance is encrypted. Note that if you are creating a cross-region read replica this field is ignored and you should instead declare kms_key_id with a valid ARN. The default is false if not specified."
  default     = true
}

variable "db_maintenance_window" {
  description = "(Optional) The window to perform maintenance in. Syntax: ddd:hh24:mi-ddd:hh24:mi. Eg: Sun:00:00-Sun:03:00."

  # SUN 12:30AM-01:30AM ET
  default = "Sun:04:30-Sun:05:30"
}

variable "db_backup_retention_period" {
  description = "(Optional) The days to retain backups for. Must be 1 or greater to be a source for a Read Replica."
  default     = 0
}

variable "db_backup_window" {
  description = "(Optional) The daily time range (in UTC) during which automated backups are created if they are enabled. Example: 09:46-10:16. Must not overlap with maintenance_window."

  # 12:00AM-12:30AM ET
  default = "04:00-04:30"
}

variable db_iops {
  description = "(Optional) The amount of provisioned IOPS. Setting this implies a storage_type of io1."
  default     = 0
}

variable "db_multi_availability_zone" {
  description = "(Optional) Specifies if the RDS instance is multi availability zone"
  default     = true
}

variable "db_publicly_accessible" {
  description = "(Optional) Bool to control if instance is publicly accessible. Default is false."
  default     = false
}

variable "db_auto_minor_version_upgrade" {
  description = "(Optional) Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Defaults to true."
  default     = true
}

variable "db_allow_major_version_upgrade" {
  description = "(Optional) Indicates that major engine upgrades will be applied automatically to the DB instance during the maintenance window. Defaults to false."
  default     = false
}

variable "db_apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "(Optional) Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier. Default is false."
  default     = true
}

variable "db_copy_tags_to_snapshot" {
  description = "(Optional, boolean) On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified). Default is false."
  default     = true
}

## Jenkins

variable "jenkins_cidrs" {
  type    = "list"
  default = ["10.0.103.0/24"]
  description = "The cidrs that jenkins should reside in"
}

variable "jenkins_key_name" {
  description = "ssh auth keypair name"
}

variable "jenkins_private_key_path" {
  default     = "../keys/bench-tc-jenkins"
  description = "path to ssh private key"
}

variable "jenkins_public_key_path" {
  default     = "../keys/bench-tc-jenkins.pub"
  description = "path to ssh public key"
}

variable "jenkins_developer_password" {
  description = "jenkins password for dev user"
}

variable "jenkins_admin_password" {
  description = "jenkins password for admin user"
}

variable "github_user" {
  description = "The user jenkins should use for github scm checkouts"
}

variable "github_token" {
  description = "GitHub api token for the 'github_user'"
}

variable "github_repo_owner" {
  description = "The github user account that *owns* the repos for which pipelines should be instantiated"
}

variable "github_repo_include" {
  description = "Repos to include from github owner account"
}

variable "github_branch_include" {
  default     = "master PR-* build-*"
  description = "Branches to include from candidate repos"
}

variable "github_branch_trigger" {
  default     = "master"
  description = "Branches to automatically build (of the subset of included branches)"
}