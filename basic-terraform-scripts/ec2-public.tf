#code to create EC2 instance, security group
resource "aws_instance" "public_instance" {
  ami                         = "ami-0889a44b331db0194"
  instance_type               = "t2.micro"
  key_name                    = "my-ec2-keypair"
  vpc_security_group_ids      = [aws_security_group.public_instance_sg.id]
  subnet_id                   = aws_subnet.public_subnet_1.id
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  tags = {
    Name = "public-ec2-instance"
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

resource "aws_ebs_volume" "public_instance_ebs_volume" {
  availability_zone = "us-east-1a"
  size              = 10
  type              = "gp3"

  tags = {
    Name = "public_instance_ebs_volume"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.public_instance_ebs_volume.id
  instance_id = aws_instance.public_instance.id
}

resource "aws_security_group" "public_instance_sg" {
  name_prefix = "public_instance_sg"
  description = "public instance security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
