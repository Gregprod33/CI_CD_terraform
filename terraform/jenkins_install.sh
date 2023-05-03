#!/bin/bash
sudo useradd ec2-user
sudo yum update -y
# Install OpenJDK 11
sudo amazon-linux-extras install java-openjdk11 -y
# Install wget
sudo yum -y install wget
# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo amazon-linux-extras install epel -y
sudo yum update -y
sudo yum install jenkins -y
# Start Jenkins service
# Setup Jenkins to start at boot
sudo systemctl start jenkins
sudo systemctl enable jenkins

