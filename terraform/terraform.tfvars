region = "eu-west-3"
# indique la plage d'ip disponible : le 16 indique que les deux premières octets restent les mêmes"
vpc_cidr = "192.168.0.0/16"
login = "AKIASYRJPK3I7HTEXQSI"
password = "Iwt2coCEM6tQIIVWLzgd/Vc2qbSAcMmtoojPgpUo" 

# l'annotation 0.0.0.0/0 indique de prendre l'ensemble des ip addressées auparavant
all_cidr = "0.0.0.0/0"
public_subnet1_cidr = "192.168.1.0/24"
public_subnet2_cidr = "192.168.2.0/24"
private_subnet_cidr = "192.168.3.0/24"
availability_zone = "eu-west-3a"
jenkins_port = 8080
sonarqube_port = 9000
grafana_port = 3000
http_port = 80
ssh_port = 22
key_name = "greg"

#Il s'agit de la valeur de la clé ssh publique qui est dans utilisateur/greg/.ssh
key_value = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCPeSiPig0Z9tW1y6JO9f2KmQy3HqqCQLvR7C3xUD1vgjQlO+cctDuz4TsvLZUJOCPdYJoPifOVryurLu1FEBUShatpIA89/xPv/SrJnQKe1sc19n7UKftgymN698ms/EqZgg4cLhuGz6VdDtSP1EB0yuoEsjwfmMQQeCpBi05lMXm2cQqcwZ9IwLZs0qSENDjvIjZU8h+ezGxtYLFyDQUFVbR7MoO/udIZM6TsW/fMxjFbjYuR8s70ZN6aCe9leEDGqXhUU9BMllwycdnr0lDvcu5N15ThqB0hdO8GoAa7jqvnHbTsntfsw8FQ+fNIqf7o2AQAJJ0KI1Gb+nx64f1h rsa-key-20230311"

username = ["robert", "ducky"]
linux2_ami = "ami-06b6c7fea532f597e"
ubuntu_ami = "ami-05b457b541faec0ca"

micro_instance = "t2.micro"
small_instance = "t2.small"
jenkins_ip_address = "52.47.182.27"