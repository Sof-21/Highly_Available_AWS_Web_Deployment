resource "aws_instance" "jump_box" {
  ami           = var.ami
  instance_type = var.instance_type

  subnet_id = aws_subnet.public_subnet_1.id

  key_name = aws_key_pair.bastion.key_name

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.bastalion_sg.id
  ]

  tags = {
    Name = "jump_box"
  }
}

resource "aws_instance" "web_server_a" {
  ami           = var.ami
  instance_type = var.instance_type

  subnet_id = aws_subnet.private_subnet_1.id

  key_name = aws_key_pair.ec2-private.key_name

  vpc_security_group_ids = [
    aws_security_group.private_ec2_sg.id
  ]

  # User data for initialization of the instance, using a template file to customize the content based on the node name.
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    node_name = var.node_name_a
  })


  tags = {
    Name = "web_server_a"
  }
}

resource "aws_instance" "web_server_b" {
  ami           = var.ami
  instance_type = var.instance_type

  subnet_id = aws_subnet.private_subnet_2.id

  key_name = aws_key_pair.ec2-private.key_name

  vpc_security_group_ids = [
    aws_security_group.private_ec2_sg.id
  ]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    node_name = var.node_name_b
  })

  tags = {
    Name = "web_server_b"
  }
}