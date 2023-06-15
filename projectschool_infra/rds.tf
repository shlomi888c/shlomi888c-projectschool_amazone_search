resource "aws_db_instance" "tutorial_database" {

  allocated_storage      = var.settings.database.allocated_storage
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  identifier             ="test"
  db_name                = var.settings.database.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.tutorial_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
  publicly_accessible    = true
  iam_database_authentication_enabled = true
}

resource "aws_db_subnet_group" "tutorial_db_subnet_group" {
  name        = "rds_subnet_group"
  description = "Subnet group for RDS instance"
  subnet_ids  = [aws_subnet.sub_ec2_rds_1.id, aws_subnet.sub_ec2_rds_2.id]
}

resource "aws_iam_policy" "rds_policy" {
  name = "rds_access_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "rds-db:connect"
        ],
        Effect = "Allow",
        Resource = aws_db_instance.tutorial_database.arn
      }
    ]
  })
}
resource "aws_iam_user_policy_attachment" "rds_policy_attachment" {
  user = "shlomic@abnet.co.il"
  policy_arn = aws_iam_policy.rds_policy.arn
}
