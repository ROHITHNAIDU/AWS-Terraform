#!/bin/bash
sudo amazon-linux-extras install epel -y
sudo /bin/yum install httpd -y
sudo /bin/systemctl restart httpd
sudo /bin/systemctl enable httpd
sudo su
sudo /bin/echo "Hello World from $(hostname -f)" > /var/www/html/index.html 