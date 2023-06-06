resource "aws_launch_template" "demo_lt" {
  name                   = "demo-launch-template"
  image_id               = "ami-0889a44b331db0194"
  instance_type          = "t2.micro"
  key_name               = "my-ec2-keypair"
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  #   network_interfaces {
  #     associate_public_ip_address = false
  #   }
  tags = {
    Name = "demo_lauch_template"
  }
  user_data = filebase64("${path.module}/ec2-user-data.sh")
}

resource "aws_autoscaling_group" "demo_asg" {
  name                = "demo-asg"
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.demo_lt.id
    version = "$Latest"
  }
  min_size         = 2
  max_size         = 2
  desired_capacity = 2
}

#instance security group
resource "aws_security_group" "demo_sg" {
  name_prefix = "demo_sg"
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


resource "aws_autoscaling_attachment" "asg_att" {
  autoscaling_group_name = aws_autoscaling_group.demo_asg.name
  lb_target_group_arn    = aws_lb_target_group.my_tg.arn
}
