#code to create EC2 instance, security groups and Application Load Balancer
resource "aws_instance" "web_server" {
  ami                         = "ami-0889a44b331db0194"
  instance_type               = "t2.micro"
  key_name                    = "my-ec2-keypair"
  vpc_security_group_ids      = [aws_security_group.web_server_sg.id]
  subnet_id                   = aws_subnet.private_subnet_2.id
  availability_zone           = "us-east-1b"
  associate_public_ip_address = false
  tags = {
    Name = "web-server"
  }

  root_block_device {
    volume_size = 10
  }

  user_data = <<EOF
#!/bin/bash
sudo amazon-linux-extras install epel -y
sudo /bin/yum install httpd -y
sudo /bin/systemctl restart httpd
sudo /bin/systemctl enable httpd
sudo su
sudo /bin/echo "Hello world " >/var/www/html/index.html
EOF

}

#instance security group
resource "aws_security_group" "web_server_sg" {
  name_prefix = "web_server_sg"
  description = "web server security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "port 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#ALB security group
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb_sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#code to create ALB
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name = "my-alb"
  }
}

resource "aws_lb_target_group" "my_tg" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "my-target-group"
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg_att" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.web_server.id
  port             = 80
}
