# Challenges & Troubleshooting

## 1. Bastion Host SSH Access

### Problem
I created an EC2 instance as a bastion host (jump box) to test my infrastructure and provide administrative SSH access to the EC2 instances deployed in private subnets.

As part of the setup, I created a security group that restricted SSH access to my public IP address.

I initially used `ifconfig` on my laptop and selected the first IP address that looked like an IP address:
```
192.168.100.6
```
I then configured the bastion security group to allow SSH from that address:
```
ingress {
    description = "ssh from anywhere for now"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "192.168.100.6/32"
  }
```

However, the SSH connection timed out:
```
ssh -i bastion ec2-user@54.123.45.67

debug1: Connecting to 54.123.45.67 [54.123.45.67] port 22.
debug1: connect to address 54.123.45.67 port 22: Operation timed out
ssh: connect to host 54.123.45.67 port 22: Operation timed out
```

### Investigation
After investigating the issue, I discovered that I had used an address associated with my local network rather than the public IP address through which my traffic reached the internet.

The security group was therefore allowing SSH from the wrong source IP.

### Root Cause
The bastion security group was configured to allow SSH from my local network address instead of the public source IP visible to AWS.

When my laptop connected to the EC2 instance over the internet, AWS saw the connection as coming from my public IP, not the local address I had configured in the security group.

### Solution
I checked my public IP using:
```
curl https://checkip.amazonaws.com
```
This returned:
```
93.159.26.243
```
I then updated the security group to allow SSH from that address:
```
cidr_blocks = ["93.159.26.243/32"]
```
After applying the change, I was able to successfully SSH into the bastion host.

### Lesson Learned
Private/local IP addresses and public IP addresses serve different purposes.

A device can have a private IP address within its local network while using a public IP address when communicating with the internet.

When restricting AWS security group access to a specific external client, the rule must use the public source IP visible to AWS.

Using /32 restricts the rule to a single IPv4 address.

---

## 2. SSH Authentication to Private EC2

### Problem
Once I was able to SSH into my bastion host, I attempted to connect to the EC2 instances deployed in the private subnets using their private IP addresses.

The connection reached the private EC2 instance, but authentication failed:

```
[ec2-user@ip-10-0-1-168 ~]$ ssh ec2-user@10.0.2.13

The authenticity of host '10.0.2.13 (10.0.2.13)' can't be established. ED25519 key fingerprint is SHA256:n29wS6gpGAkuYGDwA1O/rVkyJD+rMltm5B4XKwb5Gc4. This key is not known by any other names. Are you sure you want to continue connecting (yes/no/[fingerprint])? yes Warning: Permanently added '10.0.2.13' (ED25519) to the list of known hosts. 

ec2-user@10.0.2.13: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

### Investigation
On my investigation, i can see the bastion established initial connection to the private EC2 instance, but later failed with `Permission denied`. 
 
I investigated the SSH configuration of the instance and discovered that I had overlooked configuring an EC2 key pair when creating the private instances.

As a result, I did not have the corresponding private key required to authenticate to the instances using SSH.

### Root Cause
The private EC2 instances were created without an EC2 key pair.

The bastion host had network connectivity to the private instances, but I did not have the appropriate SSH credentials to authenticate as ec2-user.

This helped distinguish two separate layers of SSH connectivity:
```
Bastion
   │
   │ Network connectivity
   ▼
Private EC2
   │
   │ SSH authentication
   ▼
Permission denied
```

### Solution
I recreated the private EC2 instances with an EC2 key pair named ec2-private.

I then transferred the corresponding private key from my local laptop to the bastion host using scp:
```
scp -i bastalion.pem ec2-private.pem ec2-user@34.205.141.204:/home/ec2-user/
```

Once the instances were running with the correct key pair, I was able to authenticate to the private EC2 using the private key:

```
[ec2-user@ip-10-0-1-168 ~]$ ssh -i ec2-private ec2-user@10.0.2.13
```
The SSH connection was then established successfully.

### Lesson Learned
SSH connectivity and SSH authentication are separate concerns.

In this case, the bastion host could successfully reach the private EC2 over the network, but authentication failed because I had not configured an EC2 key pair.

This reinforced the importance of planning both:

- Network access - routing and security groups
- Authentication - SSH keys and user credentials

I also learned that EC2 key-pair configuration should be considered when creating instances that require SSH administration.

**Note:** Copying the private EC2 key onto the bastion is convenient in this case as its for a lab but isn't the ideal approach to use in production. For a production-oriented design, SSH agent forwarding or `ProxyJump`/SSM would be a better option.

---

## 3. ALB Target Group Reporting Targets as Unused

### Problem
The Application Load Balancer (ALB) target group was unable to confirm the health of the EC2 instances.

The target group showed 0 healthy targets and was displayed as "unused target group" in the AWS console.
![un-used-targets](/Image/un-used-targets.png)
![un healthy targets](/Image/unhealthy-targets.png)

### Investigation
I investigated the target group and EC2 network configuration and found that the EC2 instances were deployed in private subnets located in Availability Zones that were different from the Availability Zones selected for the public subnets hosting the ALB.

My initial ALB configuration prioritized selecting public subnets with internet connectivity without considering the Availability Zones where the EC2 instances were deployed.

The architecture was therefore structured roughly as:

- ALB: Public subnets in AZ-A and AZ-B
- EC2 instances: Private subnets in AZ-C and AZ-D
- Target Group: EC2 instances in the private subnets

This resulted in the ALB not having the expected network path to the registered targets.

### Root Cause
The issue was caused by an incorrect understanding of the ALB's subnet and Availability Zone requirements.

An ALB must have subnets in at least two Availability Zones, and its nodes need network connectivity to the registered targets. I had selected public subnets based primarily on their public-facing role rather than ensuring the overall subnet/AZ design provided connectivity to the EC2 instances.

### Solution
I redesigned the subnet layout so that the public and private subnets were aligned across the same Availability Zones.

I then:

1. Redeployed the public subnets to the Availability Zones containing the EC2 private subnets.
2. Deployed the ALB into the new public subnets.
3. Kept the EC2 instances in their private subnets.
4. Verified that the ALB could reach the EC2 instances through the appropriate security group and network configuration.
5. Confirmed that the EC2 instances became healthy targets in the target group.

The resulting architecture follows the intended pattern:
```
Internet → Internet-facing ALB (Public Subnets) → EC2 Instances (Private Subnets)
```
with the public and private subnets distributed across the same Availability Zones.

### Lesson Learned
Availability Zone selection should be considered before deploying the individual networking components.

For a highly available AWS architecture, I should design the subnet and AZ layout as a complete system rather than selecting public and private subnets independently.

---

## 4. ALB Accessible with HTTP but Not HTTPS

### Problem
After deploying the Application Load Balancer, I was able to access the application using curl, but accessing the ALB DNS name through a web browser using HTTPS was unsuccessful.

### Investigation
I verified that the ALB was reachable and that the target EC2 instances were responding correctly.

I then checked the ALB listener configuration and found that the ALB had an HTTP listener configured, but I was attempting to access it using the HTTPS protocol.

### Root Cause
I verified that the ALB was reachable and that the target EC2 instances were responding correctly.

I then checked the ALB listener configuration and found that the ALB had an HTTP listener configured, but I was attempting to access it using the HTTPS protocol.

### Solution
I accessed the ALB using HTTP instead:
```
http://<alb-dns-name>
```
The application was then accessible through the browser as expected.

### Lesson Learned
The protocol used to access an ALB must match the listener configuration.

An internet-facing ALB does not automatically provide HTTPS just because it is publicly accessible. To support HTTPS, the ALB needs an HTTPS listener with a valid SSL/TLS certificate, typically managed through AWS Certificate Manager (ACM).
