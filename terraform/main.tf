resource "aws_instance" "jenkins_server" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  vpc_security_group_ids = [ aws_security_group.jenkins-server-sg.id ]

  tags = {
    Name = "jenkins-server"
  }
  user_data = file("jenkins-server.sh")
}

resource "aws_instance" "jenkins_worker" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  vpc_security_group_ids = [ aws_security_group.jenkins-worker-sg.id ]

  tags = {
    Name = "jenkins-worker"
  }
  
  user_data = file("jenkins-worker.sh")
}

resource "aws_security_group" "jenkins-server-sg" {
  name = "jenkins-server-sg"
  ingress {
    description = "Allow all inbound from my IP"
    from_port = 0
    to_port = 0
    protocol = "-1"  #all protocols
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    description = "Allow all outbound to my IP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "github_webhook_ips" {
  for_each          = var.github_webhook_ips
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.jenkins-server-sg.id
  description       = "Allow All traffic from Gihub Webhook IP ${each.value}"
}

resource "aws_security_group" "jenkins-worker-sg" {
  name = "jenkins-worker-sg"
  ingress {
    description = "Allow all inbound from my IP"
    from_port = 0
    to_port = 0
    protocol = "-1"  #all protocols
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_instance.jenkins_server.private_ip}/32"]
  }

  egress {
    description = "Allow all outbound to my IP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "jenkins_server_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "jenkins_worker_ip" {
  value = aws_instance.jenkins_worker.public_ip
}
