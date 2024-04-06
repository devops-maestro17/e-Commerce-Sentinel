resource "aws_security_group" "sg" {
  name        = "sentinel-sg"
  description = "Allow TLS inbound traffic"
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sentinel-sg"
  }
}

resource "aws_instance" "web-server-1" {
  ami                    =  var.ami
  instance_type          =  var.instance_type_1
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = templatefile("./install-jenkins.sh", {})
  tags = {
    Name = "Jenkins-server"
  }
  root_block_device {
    volume_size = var.volume_size_1
  }
}

resource "aws_instance" "web-server-2" {
  ami                    =  var.ami
  instance_type          =  var.instance_type_2
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = templatefile("./install-sonarqube.sh", {})
  tags = {
    Name = "Jenkins-server"
  }
  root_block_device {
    volume_size = var.volume_size_2
  }
}