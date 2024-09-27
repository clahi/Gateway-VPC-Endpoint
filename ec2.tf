# A security group which allows ssh traffic to instnace in the public subnets
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh traffic through port 22 for public instances"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Security group for the private instances to allow ssh from instances in the vpc (10.0.0.0/16)
resource "aws_security_group" "allow_ssh_private" {
  name        = "allow_ssh from instanced within the vpc"
  description = "Allow ssh traffic through port 22 for private instances"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_private" {
  security_group_id = aws_security_group.allow_ssh_private.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# RSA key of size 4096 
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# The Key pair that will be used to ssh to the instance
resource "aws_key_pair" "TF_key" {
  key_name   = "TF_key"
  public_key = tls_private_key.pk.public_key_openssh
}

# A local file that will host the private key generated using tls_private_key
resource "local_file" "ssh_key" {
  content  = tls_private_key.pk.private_key_openssh
  filename = "${aws_key_pair.TF_key.key_name}.pem"
}

data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

# An instance spined inside public_subnetA
resource "aws_instance" "public_instance" {
  instance_type   = var.instance_type
  ami             = data.aws_ami.amazon_ami.id
  key_name        = aws_key_pair.TF_key.key_name
  subnet_id       = aws_subnet.public_subnets["subnet-A"].id
  security_groups = [aws_security_group.allow_ssh.id]

  depends_on = [
    aws_vpc.main_vpc,
    aws_subnet.public_subnets
  ]

  tags = {
    Name = "public_instance"
  }

}

# An instance spined inside private_subnetA with no connection to the outside world
resource "aws_instance" "private_instance" {
  instance_type = var.instance_type
  ami           = data.aws_ami.amazon_ami.id
  subnet_id     = aws_subnet.private_subnets["subnet-A"].id
  key_name = aws_key_pair.TF_key.key_name
  security_groups = [aws_security_group.allow_ssh_private.id]

  tags = {
    Name = "private_instance"
  }
}