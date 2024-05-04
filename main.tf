provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""

}

# RSA key of size 4096 bits
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "myKey"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.kp.key_name}.pem"
  content = tls_private_key.pk.private_key_pem
}

resource "aws_security_group" "allow_ports" {
name        = "allow_ports"
description = "Allow ports 8080, 80,  inbound traffic"

ingress {
from_port   = 8080
to_port     = 8080
protocol    = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
ingress {
    from_port   = 22
    to_port     = 22
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


##Create Server Instance

resource "aws_instance" "Server" {
ami           = "ami-0e001c9271cf7f3b9" # Ubuntu 22.04
instance_type = "t2.micro"
security_groups = [aws_security_group.allow_ports.name]
key_name = aws_key_pair.kp.key_name
count = 1

tags = {
Name = "Server"
}

## Remote connection and installing packages
provisioner "remote-exec" {
inline = [
"sudo apt-add-repository -y ppa:ansible/ansible",
"echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
"curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
"sudo apt-get update",
"sudo apt-get install -y docker.io",
"sudo apt-get install -y ansible",
"sudo apt-get install -y kubectl kubeadm kubelet",
"git clone  https://github.com/lgandzii/orbit",
"sudo ansible-playbook orbit/install-jenkins-ubuntu.yaml",
"sudo cat /var/lib/jenkins/secrets/initialAdminPassword > jenkinspass.txt",
“sudo chmod 777 /var/run/docker.sock” 
]
}
connection {
type        = "ssh"
user        = "ubuntu"
private_key = "${tls_private_key.pk.private_key_pem}"
host        = self.public_ip
}
}
