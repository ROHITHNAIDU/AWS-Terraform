resource "aws_db_subnet_group" "rds_subnet_grp" {
  name       = "rds_subnet_grp"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags       = {
    Name = "example-subnet-group"
  }
}

resource "aws_db_instance" "my_rds" {
  identifier            = "example-db"
  allocated_storage     = 20
  storage_type          = "gp3"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  username              = "admin"
  password              = "your-strong-password"
  db_subnet_group_name  = aws_db_subnet_group.rds_subnet_grp.name
  publicly_accessible   = false
  skip_final_snapshot    = true
}

output "rds_endpoint" {
  value = aws_db_instance.my_rds.endpoint
}