provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_security_group" "cloud_sg" {
  name        = "terra-sg"
  description = "Security group for cloud instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "cloud_instance" {
  ami             = "ami-0866a3c8686eaeeba"  
  instance_type   = "t2.micro"
  key_name        = "terraform"  
  security_groups = [aws_security_group.cloud_sg.name]

  tags = {
    Name        = "Terra-cloud"
    Environment = "development"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io stress", 
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo docker network create my-network || true",
      "sudo docker run -d --name postgres-container --network my-network -e POSTGRES_USER=user -e POSTGRES_PASSWORD=${var.postgres_password} -e POSTGRES_DB=cloud_db -p 5432:5432 postgres",

      "sudo docker run -d --name clouds-container --network my-network --memory 250m -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-container:5432/cloud_db -e SPRING_DATASOURCE_USERNAME=user -e SPRING_DATASOURCE_PASSWORD=${var.postgres_password} -p 8080:8080 solomon11/cloud:latest",

      "sudo docker exec -d clouds-container stress --vm 1 --vm-bytes 200M --vm-keep --timeout 600s",   

      "echo '${file("container_scaling.sh")}' > /home/ubuntu/container_scaling.sh",
      "chmod +x /home/ubuntu/container_scaling.sh",
      "nohup /home/ubuntu/container_scaling.sh &"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("C:/Users/DELL/Downloads/terraform.pem")  
      host        = self.public_ip
    }
  }
}


output "instance_public_ip" {
  value = aws_instance.cloud_instance.public_ip
}
