resource "aws_key_pair" "bastion" {
  key_name   = "bastion"
  public_key = file("~/.ssh/bastion.pub")
}

resource "aws_key_pair" "ec2-private" {
  key_name   = "ec2-private"
  public_key = file("~/.ssh/ec2-private.pub")
}