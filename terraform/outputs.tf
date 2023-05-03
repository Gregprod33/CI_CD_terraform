output "jenkins_public_ip" {
    description = "Public IP of Jenkins instance"
    value = aws_instance.Jenkins.public_ip
}


output "sonarqube_public_ip" {
    description = "Public IP of SonarQube instance"
    value = aws_instance.SonarQube.public_ip
}

output "ansible_public_ip" {
    description = "Public IP of Ansible instance"
    value = aws_instance.Ansible.public_ip
}