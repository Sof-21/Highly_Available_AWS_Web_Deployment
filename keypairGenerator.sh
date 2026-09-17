ssh-keygen -t rsa -b 4096 -f ~/.ssh/bastion -N ""
sleep 3
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ec2-private -N ""