resource "aws_kms_key" "db_kms_key" {
  tags {
    Name        = "${var.db_identifier}-kms-key"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

// If Alias is not created the RDS instance will report that it has an encryption key of None..this fixes that issue :)
resource "aws_kms_alias" "db_kms_alias" {
  name          = "alias/${var.db_identifier}-kms-key"
  target_key_id = "${aws_kms_key.db_kms_key.key_id}"
}

resource "aws_ssm_parameter" "db_username" {
  name      = "db_username"
  type      = "SecureString"
  value     = "${var.db_username}"
  key_id    = "${aws_kms_key.db_kms_key.key_id}"
  overwrite = true
  tags {
    Name        = "${var.db_identifier}-db-username"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name      = "db_password"
  type      = "SecureString"
  value     = "${var.db_password}"
  key_id    = "${aws_kms_key.db_kms_key.key_id}"
  overwrite = true
  tags {
    Name        = "${var.db_identifier}-db-password"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name      = "db_name"
  type      = "SecureString"
  value     = "${var.project_key}"
  key_id    = "${aws_kms_key.db_kms_key.key_id}"
  overwrite = true
  tags {
    Name        = "${var.db_identifier}-db-name"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "db_identifier" {
  name      = "db_identifier"
  type      = "SecureString"
  value     = "pg-${var.project_key}-db"
  key_id    = "${aws_kms_key.db_kms_key.key_id}"
  overwrite = true
  tags {
    Name        = "${var.db_identifier}-db-identified"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "db_subnet_group" {
  name      = "db_subnet_group"
  type      = "SecureString"
  value     = "${var.project_key}-db-subnet-group"
  key_id    = "${aws_kms_key.db_kms_key.key_id}"
  overwrite = true
  tags {
    Name        = "${var.db_identifier}-db-subnet-group"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

output "rds_endpoint" {
  value = "${aws_db_instance.sql_database.endpoint}"
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name      = "${var.environment}_rds_endpoint"
  type      = "SecureString"
  value     = "${aws_db_instance.sql_database.endpoint}"
  key_id    = "${aws_kms_key.db_kms_key.key_id}"
  overwrite = true
  tags {
    Name        = "${var.db_identifier}-rds-endpoint"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
