#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

function warn {
	echo "RUNNING: \"$@\""
	if ! eval "$@"; then
		echo >&2 "WARNING: command failed \"$@\""
	fi
}

sudo uname -a
sudo lsb_release -a
sudo df -h
sudo lsblk
sudo cat /etc/apt/sources.list

echo "Install ansible2"
warn "sudo apt-get update -y"
warn "sudo apt-get install -y ansible tcpd"
warn "sudo apt-get upgrade -y"

echo "Install other tools"


echo 'Downloading and installing SSM Agent' 
warn "sudo snap install amazon-ssm-agent --classic"

echo 'Downloading and installing amazon-cloudwatch-agent'
warn "wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /var/tmp/amazon-cloudwatch-agent.deb"
warn "sudo apt-get install -y /var/tmp/amazon-cloudwatch-agent.deb"

echo 'Starting cloudwatch agent'
warn "sudo amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/tmp/CWAgentParameters.json -s"

echo 'Install Amazon Inspector'
warn 'curl https://inspector-agent.amazonaws.com/linux/latest/install | sudo bash'


sudo apt-get install -y ruby unzip

echo "wget for ec2 ami tools"
wget https://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip


echo "make directory"
sudo mkdir -p /usr/local/ec2

echo "unzip tools"
sudo unzip ec2-ami-tools.zip -d /usr/local/ec2

echo "Create /etc/profile.d/myenvvars.sh"
sudo touch /etc/profile.d/myenvvars.sh

echo "Installing kpartx, grub as required by ec2-ami-tools"
sudo apt-get install kpartx -y
sudo apt-get install grub -y

#sudo apt-get install grub2-common -y
#sudo apt-get install grub-pc -y
#sudo apt-get install grub-efi-ia32 -y
#sudo apt-get install grub-efi-amd64 -y

echo "add to etc/profile.d/myenvvars.sh export variable EC2_AMITOOL_HOME"
sudo bash -c 'echo "export EC2_AMITOOL_HOME=/usr/local/ec2/ec2-ami-tools-1.5.7" >> /etc/profile.d/myenvvars.sh'
sudo bash -c 'echo "export PATH=/usr/local/ec2/ec2-ami-tools-1.5.7/bin:$PATH:" >> /etc/profile.d/myenvvars.sh'

#sudo yum update -y kernel
#sudo reboot
