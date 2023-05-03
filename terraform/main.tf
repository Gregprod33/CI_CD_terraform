# Initiate the provider
provider "aws" {
    region = var.region
    access_key = var.login
    secret_key = var.password 
}


# Create the VPC 
resource "aws_vpc" "production_vpc" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "Production VPC"
    }
}


# Une fois les 3 fichiers terraform terminés (main, variables et terraform.tfvars), dans le terminal, entrer terraform init pour se connecter avec AWS afin de le prévenir d'un déploiement et vérifier que tous les fichiers sont bons. Si tout est ok, terraform créé un dossier terraform dans le dossier de travail et un fichier .terraform.lock.hcl
# Puis entrer la commande terraform plan. Cette commande va comparer notre code de déploiement avec l'état de notre déploiement sur AWS. Si terraform détecte une différence, il va automatique détruire cette ressource.
#Dans le terminal, les différences s'affichent et si tout est ok :
#Entrer terraform apply
#Pour davantage de securite on enregitre les varibles relatives au provider aws : $env:AWS_ACCESS_KY_ID="lavaleur" $env:AWS_SECRET_ACCESS_KEY="" $env:AWS_DEFAULT_REGION="" 

# create the internet gateway : la porte ouverte de notre réseau vers l'exterieur
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.production_vpc.id
}

# creating elastic IP to associate with NAT Gateway
# depends on stipule à terraform de créer l'internet gateway et ensuite seulement l'elastic ip"
# l4Elastic IP est une addresse ip permettant de pouvoir communiquer avec internet, c'est une alternative à l'adresse IP publique
resource "aws_eip" "nat_eip" {
    depends_on = [aws_internet_gateway.igw]
}

# Create NAT gateway : permet à nos middlewares d'accéder à internet tout en étant protégé par ce NAT gateway
resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet1.id
    tags = {
        Name = "NAT Gateway"
    }
}

# create the public route table
# les route tables sont les règles des routes flux réseaux, ici il nous en faut une publique et une privée.
# les routes table en elle même ne peuvent pas être publiques ou privées tant qu'elle ne sont pas rattachées à une ressource.
# La première dite publique indique que l'ensemble du traffic des ip provenant de ce sous réseau doivent être routées en direction de l'internet gateway
# en résumé ça rend l'internet gatewayaccessible depuis internet.
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.production_vpc.id
    route {
        cidr_block = var.all_cidr
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "Public RT"
    }
}

# Create the private route table
# Pour toutes les ip addressées dans ce sous réseau, le traffic doit être routé vers le nat gateway
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.production_vpc.id
    route {
        cidr_block = var.all_cidr
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }
    tags = {
        Name = "Private RT"
    }
}

# Create the public subnet1
resource "aws_subnet" "public_subnet1" {
    vpc_id = aws_vpc.production_vpc.id
    cidr_block = var.public_subnet1_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true
    tags = {
        Name = "Public subnet 1"
    }
}


# Create the public subnet2
resource "aws_subnet" "public_subnet2" {
    vpc_id = aws_vpc.production_vpc.id
    cidr_block = var.public_subnet2_cidr
    availability_zone = "eu-west-3b"
    map_public_ip_on_launch = true
    tags = {
        Name = "Public subnet 2"
    }
}

# Create the private subnet
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.production_vpc.id
    cidr_block = var.private_subnet_cidr
    availability_zone = "eu-west-3b"

    tags = {
        Name = "Private subnet"
    }
}

# Associate public RT with public subnet 1
resource "aws_route_table_association" "public_association1" {
    subnet_id = aws_subnet.public_subnet1.id
    route_table_id = aws_route_table.public_rt.id
}

# Associate public RT with public subnet 2
resource "aws_route_table_association" "public_association2" {
    subnet_id = aws_subnet.public_subnet2.id
    route_table_id = aws_route_table.public_rt.id
}

# Associate public RT with private subnet
resource "aws_route_table_association" "private_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}

# Create Jenkins security group
# Ingress définit les règles sur les ports entrants
# Egress définit les règles sur les ports sortants : 0 signifie tous les ports et - 1 tous les protocoles
resource "aws_security_group" "jenkins_sg" {
    name = "Jenkins SG"
    description = "Allow ports 8080 and 22"
    vpc_id = aws_vpc.production_vpc.id

    ingress {
        description = "Jenkins"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Jenkins SG"
    }
}


# Create SonarQube security group
resource "aws_security_group" "sonarqube_sg" {
    name = "Sonarqube SG"
    description = "Allow ports 9000 and 22"
    vpc_id = aws_vpc.production_vpc.id

    ingress {
        description = "Sonarqube"
        from_port = var.sonarqube_port
        to_port = var.sonarqube_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = var.ssh_port
        to_port = var.ssh_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Sonarqube SG"
    }
}

#Create Ansible security group
resource "aws_security_group" "ansible_sg" {
    name = "Ansible SG"
    description = "Allow port 22"
    vpc_id = aws_vpc.production_vpc.id
    

    ingress {
        description = "SSH"
        from_port = var.ssh_port
        to_port = var.ssh_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "8080"
        from_port = var.jenkins_port
        to_port = var.jenkins_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = var.http_port
        to_port = var.http_port
        protocol = "tcp"
        security_groups = [aws_security_group.app_sg.id]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Ansible SG"
    }
}


# Create Grafana security group
resource "aws_security_group" "grafana_sg" {
    name = "Grafana SG"
    description = "Allow port 3000 and 22"
    vpc_id = aws_vpc.production_vpc.id

    ingress {
        description = "Grafana"
        from_port = var.grafana_port
        to_port = var.grafana_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = var.ssh_port
        to_port = var.ssh_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Grafana SG"
    }
}


# Create application security group
resource "aws_security_group" "app_sg" {
    name = "Application SG"
    description = "Allow port 80 and 22"
    vpc_id = aws_vpc.production_vpc.id

    ingress {
        description = "Application"
        from_port = var.http_port
        to_port = var.http_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = var.ssh_port
        to_port = var.ssh_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Application SG"
    }
}


# Create Load Balancer security group
resource "aws_security_group" "lb_sg" {
    name = "LoadBalancer SG"
    description = "Allow port 80"
    vpc_id = aws_vpc.production_vpc.id

    ingress {
        description = "LoadBalancer"
        from_port = var.http_port
        to_port = var.http_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "LoadBalancer SG"
    }
}


# Create ACL = network access control list : une ACL fait la même chose qu'un groupe sécurité
# Mais là où le groupe de sécurité s'opère au niveau d'une instance, l'ACL s'opère au niveau du scope du VPC
# C'est un filtre de traffic externe placé en amont d'un sous réseau ou de multiples sous réseaux :
# Quand un traffic veut atteindre une instance en particulier, il doit d'abord passer par l'ACL dans le VPC
# Ensuite, il passe le groupe de sécurité de l'instance
# De la même façon, lorsque le traffic veut sortir de l'instance, il doit en être autorisé
# par le groupe de sécurité correspondant et par l'ACL
# Les règles fonctionnent grâce à un nombre : plus il est bas plus il est prioritaire et masque les règles de moindre importance.
# On doit indiquer à l'ACL les différents sous réseaux concernés
# !!!!!! Attention si on ne parvient pas à accéder à nos instances depuis l'extérieur malgré l'autorisation des groupesde sécurité :
# On commente la ligne subnet_ids

resource "aws_network_acl" "nacl" {
    vpc_id = aws_vpc.production_vpc.id
    # subnet_ids = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id, aws_subnet.private_subnet.id]

    egress {
        protocol = "tcp"
        rule_no = "100"
        action = "allow"
        cidr_block = var.vpc_cidr
        from_port = 0
        to_port = 0
    }

    ingress {
        protocol = "tcp"
        rule_no = "100"
        action = "allow"
        cidr_block = var.all_cidr
        from_port = var.http_port
        to_port = var.http_port
    }

    ingress {
        protocol = "tcp"
        rule_no = "101"
        action = "allow"
        cidr_block = var.all_cidr
        from_port = var.ssh_port
        to_port = var.ssh_port
    }

    ingress {
        protocol = "tcp"
        rule_no = "102"
        action = "allow"
        cidr_block = var.all_cidr
        from_port = var.jenkins_port
        to_port = var.jenkins_port
    }

    ingress {
        protocol = "tcp"
        rule_no = "103"
        action = "allow"
        cidr_block = var.all_cidr
        from_port = var.sonarqube_port
        to_port = var.sonarqube_port
    }

    ingress {
        protocol = "tcp"
        rule_no = "104"
        action = "allow"
        cidr_block = var.all_cidr
        from_port = var.grafana_port
        to_port = var.grafana_port
    }

    ingress {
        protocol = "icmp"
        rule_no = "105"
        action = "allow"
        cidr_block = var.all_cidr
        from_port = 0
        to_port = 0
    }
    

    tags = {
        Name = "Main ACL"
    }
}


# Create the ECR repository : l'ECR est l'endroit où Ansible va stocker les images docker où seront stockés nos artefacts
#le paramètre image_scanning_configuration indique si l'ECR doit vérifier s'il y a des erreurs sur les images qu'il pousse dans le repo
# resource "aws_ecr_repository" "ecr_repo" {
#     name = "docker_repository"
#     image_scanning_configuration {
#       scan_on_push = true
#     }
# }

#Save ssh key pair to aws
resource "aws_key_pair" "auth_key"{
    key_name = var.key_name
    public_key = var.key_value
}


# Create S3 bucket for storing Terraform state
resource "aws_s3_bucket" "devops-project-terraform-state-gregprod33" {
  bucket = "devops-project-terraform-state-gregprod33"
}

resource "aws_s3_bucket_acl" "devops-project-terraform-state-gregprod33" {
  bucket = aws_s3_bucket.devops-project-terraform-state-gregprod33.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "versioning-devops-project-terraform-state-gregprod33" {
  bucket = aws_s3_bucket.devops-project-terraform-state-gregprod33.id
  versioning_configuration {
    status = "Enabled"
  }
}


# Configure the S3 backend
# key is the path to the file we want in our bucket on aws
# terraform {
#     backend "s3" {
#         bucket = "devops-project-terraform-state-gregprod33"
#         key = "prod/terraform.tfstate"
#         region = "eu-west-3"
#     }
# }

# Creating the Jenkins instance
# Ici, on va lancer une instance d'un EC2 c'est à dire un serveur virtuel
# le paramètre ami (Amazon Machine Image) est une image pré-configurée d'un OS
# le type d'instance t2.micro est une instance de base très légère et suffisante pour faire tourner Jenkins.
resource "aws_instance" "Jenkins" {
    ami = var.linux2_ami
    instance_type = var.micro_instance
    availability_zone = var.availability_zone
    subnet_id = aws_subnet.public_subnet1.id
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
    user_data = file("jenkins_install.sh")

    tags = {
        Name = "Jenkins"
    }
}

# Create the SonarQube instance
resource "aws_instance" "SonarQube" {
    ami = var.ubuntu_ami
    instance_type = var.small_instance
    availability_zone = var.availability_zone
    subnet_id = aws_subnet.public_subnet1.id
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.sonarqube_sg.id]

    tags = {
        Name = "SonarQube"
    }

}

# Create the Ansible instance
resource "aws_instance" "Ansible" {
    ami = var.linux2_ami
    instance_type = var.micro_instance
    availability_zone = var.availability_zone
    subnet_id = aws_subnet.public_subnet1.id
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.ansible_sg.id]
    user_data = file("ansible_install.sh")

    tags = {
        Name = "Ansible"
    }

}

# Création d'un template de lancement pour notre application:
resource "aws_launch_template" "app-launch-template" {
  name = "app-launch-template"
  image_id = var.linux2_ami
  instance_type = var.micro_instance
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name = var.key_name
  user_data = base64encode(file("app_template_install.sh"))
}

# Création du groupe autoscaling utilisant le template juste au dessus
# C'est le load balancer qui en vérifiera l'état
# Max = le nombre d'instances max, min le nombre d'instances min, desired_capacity : le nombre d'instances souhaitées
# ELB = Elastic Load Balancer
resource "aws_autoscaling_group" "app-asg"{
    name = "apps-asg"
    max_size = 2
    min_size = 1
    desired_capacity = 2
    health_check_type = "ELB"
    launch_template {
      id = aws_launch_template.app-launch-template.id
      version = "$Latest"
    }
    vpc_zone_identifier = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
    target_group_arns = [aws_lb_target_group.app-target-group.arn]
}

# Création du group cible pour l'autoscaling
resource "aws_lb_target_group" "app-target-group"{
    name = "app-target-group"
    port = "80"
    target_type = "instance"
    protocol = "HTTP"
    vpc_id = aws_vpc.production_vpc.id
}

# Création de la ressource liant l'autoscaling group au groupe cible
resource "aws_autoscaling_attachment" "autoscaling-attachment" {
    autoscaling_group_name = aws_autoscaling_group.app-asg.id
    lb_target_group_arn = aws_lb_target_group.app-target-group.arn
}

# Création du load balancer
# Internal false signifie que le load balancer sera accessible depuis internet et non uniquement à l'intérieur du VPC
resource "aws_lb" "app-lb" {
    name = "app-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.lb_sg.id]
    subnets = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
}

# Création du listener du load balancer qui est comme son cerveau et va préciser la direction des flux sortants
resource "aws_lb_listener" "app-listener" {
    load_balancer_arn = aws_lb.app-lb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.app-target-group.arn
    }
}