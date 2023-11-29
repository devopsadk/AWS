AWS

### Setup user data
#!/bin/bash
sudo yum install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
echo welcome2nginx >> index.html
sudo cp index.html /usr/share/nginx/html

#!/bin/bash
sudo yum install httpd -y
sudo systemctl enable httpd
sudo systemctl start httpd
echo httpdwelcome >> index.html
sudo cp index.html /var/www/html

########################################

I am trying out to add a extra EBS space while creating an EC2 instance of 8 gb.
However once the instance is created if you hit df -hT you wont be able to see extra 8 gb added. To see that
we need to mount it as below

to check use df -hT
check using sudo lsblk

Mounting XFS filesystem
To illustrate let's first create a partition and add xfs filesystem on it.

To create a new XFS file system you will first need a partition to format. You can use fdisk to create a new partition.

 sudo fdisk /dev/xvdb

 Now that your partition is ready you can create an XFS filesystem by using the mkfs.xfs command, with the name of the partition you created like this:

 sudo mkfs.xfs /dev/xvdb

  sudo mkdir /test

  sudo mount /dev/xvdb /test

  df -hT
Filesystem     Type      Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs  4.0M     0  4.0M   0% /dev
tmpfs          tmpfs     379M     0  379M   0% /dev/shm
tmpfs          tmpfs     152M  4.4M  148M   3% /run
/dev/xvda4     xfs       9.4G  1.3G  8.1G  14% /
/dev/xvda3     xfs       495M  165M  331M  34% /boot
/dev/xvda2     vfat      200M  8.0K  200M   1% /boot/efi
tmpfs          tmpfs      76M     0   76M   0% /run/user/1000
/dev/xvdb      xfs       8.0G   90M  8.0G   2% /test


Now we can see file system /dev/xvdb and mountpoint /test


------------------------------

Next scenario I will increase the root volume from 10 to 12 GB and make it reflect 
AWS console increase the root volume size and after that apply below commands 

sudo lsblk
sudo growpart /dev/xvda 1

(In our case sudo growpart /dev/xvda 4)

df -hT
sudo lsblk
sudo xfs_growfs -d /


sudo resize2fs /dev/xvda1


-----------------------------

Next scenario I will detach the 8 gb ebs which was attached on the previous instance and will attach to the
new instance created

sudo umount /test

I have created another EC2 instance in a different region . EBS volume was created in us-east-1b
and I have created ec2 in us-east-1a . So directly cannot attach to it. Need to take a snapshot of the 
volume and from tht you need to create a volume and attach to ec2 instance

mkdir /tester
sudo mount /dev/xvdb /tester

and its attached check df -hT

what we have done this is the temporary mounting means once you restart the ec2 instance mount is lost 
again you need to mount. In order to make a permanent mount

sudo vi /etc/fstab

------------------------

VPC

-----------------------

Calculate CIDR range 
https://mxtoolbox.com/subnetcalculator.aspx


192.168.0.0/28 this will give total 16 ips
formula is cidr range = 2^(32-N)
                      =2^(32-28)=16
calculate subnet ranges using 
https://www.davidc.net/sites/default/subnets/subnets.html

Lets create a VPC
--------------------

VPC --> MYVPC --> CIDR --> 192.168.0.0/19  (This will give 8,192 ips)

and region --> ohio

I want to create below servers

Loadbalancer server --> us-east-1a and us-east-1b
Application server --> us-east-1a and us-east-1b
Database server --> us-east-1a and us-east-1b

Subnets
--------
dmz-subnet-1 --> 510 ips --> us-east-2a -->cidr--> 198.168.0.0/23
dmz-subnet-2 --> 510 ips --> us-east-2b -->cidr--> 198.168.2.0/23
pub-subnet-1 --> 510 ips --> us-east-2a -->cidr--> 198.168.4.0/23
pub-subnet-2 --> 510 ips --> us-east-2b -->cidr--> 198.168.6.0/23
priv-subnet-1 --> 510 ips --> us-east-2a -->cidr--> 198.168.8.0/23
priv-subnet-2 --> 510 ips --> us-east-2b -->cidr--> 198.168.10.0/23


VPC components
--------------
1. VPC network
2. Subnet
3. Internet gateway
4. Route tables
5. NAT gateway

Internet gateway has been created and has been attached to VPC

I have created 1 DMZRT route table 1 PUBRT and PRIVRT route tables

Associate the subnets DMZRT with dmz-subnet-1 and dmz-subnet-2
                      PUBRT with pub-subnet-1 and pub-subnet-2
                      PRIVRT with priv-subnet-1 and priv-subnet-2
In the Route section add destination as 0.0.0.0.0 which means from anywhere and target as internet gateway which we created for DMZRT and PUBRT

### Important setting on your VPC go to settings and check the box Enable DNS hostnames and save
### If you require public ip then on the subnet settings check the box Enable auto-assign public IPv4 address

You cannot access servers created in private subnet directly as they do not have internet connection. If you want to access them then you need
to login in one of the servers created in the public subnet and from there with help of keys you can access the servers created in private subnet
so basically servers on public subnet act as the jump servers

----------------

VPC Peering

--------------

Create another VPC with the following details

10.0.0.0/16 -- CIDR

6 subnets --> 1024 ips

 dmz-s1 --> us-east-2a --> 10.0.0.0/22
 dmz-s2 --> us-east-2b --> 10.0.4.0/22
 pub-s1 --> us-east-2a --> 10.0.8.0/22
 pub-s2 --> us-east-2b --> 10.0.12.0/22
 priv-s1 --> us-east-2a --> 10.0.16.0/21
 priv-s2 --> us-east-2b --> 10.0.24.0/21

 dmzroute
 priv-route-vpc2
 pub-route-vpc2

add IG to pub-route-vpc2
create a NAT gateway and choose public subnet of the vpc (pub-route-vpc)
and in private-route-vpc2 (private route table) assign the routes for the NAT. Now you can login to the server created on the private subnet via
server from the public subnet and check the internet connection using ping -c 2 google.com

Create a VPC peering and update the route tables with other VPC as destination and target as the peering VPC

-------------------------------------------

Autoscaling

-------------------------------------------


-----------------
load balancer
-----------------



---------
SNS topics
---------



--------

Creating users 

--------

https://975951347459.signin.aws.amazon.com/console

Hari -- Admin user is created
raju -- Provided policy access to ec2-full access
ramesh -- Provided policy access to ec2-readonly
rani -- s3 full access

Groups
----
S3usersgroup -- Give s3-full access add raju,ramesh and rani to the group

------ Accessing AWS via  CLI

click on the user and create access key for the user
download the aws CLI for windows and install it
aws configure

-------------


Terraform

----------------

Install terrform cli for windows and the path of the exe file in the path environment variables of the system

Terrform consists of the below blocks

1. terraform block
2. provider block
3. resource block
4. variable block
5. input block
6. output block


------------------------------------
I have created a first code to create a EC2 instance


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.26.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA6GOZ3X4BS5DDPON7"
  secret_key = "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"
}

resource "aws_instance" "ins" {
  ami           = "ami-0fcb151e709410607"
  instance_type = "t2.micro"
  key_name= "linux"

  tags = {
    Name = "myterrainstance"
  }
}
-----------------------------------------------------------
After coding Hit the command 
terraform.exe init
terraform.exe plan
terraform.exe validate
terraform apply
terraform destroy
terraform apply --auto-approve


---------------------------------------------------------

I am going to create a VPC now with subnets , Internet gateways

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.26.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "vpcref" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames ="true"

  tags = {
    Name = "myvpc5"
  }
}

resource "aws_subnet" "pub11" {
  vpc_id     = aws_vpc.vpcref.id
  cidr_block = "10.0.0.0/23"
  map_public_ip_on_launch ="true"

  tags = {
    Name = "pub1"
  }
}

resource "aws_subnet" "pub12" {
  vpc_id     = aws_vpc.vpcref.id
  cidr_block = "10.0.2.0/23"
  map_public_ip_on_launch ="true"

  tags = {
    Name = "pub2"
  }
}

resource "aws_subnet" "dmz11" {
  vpc_id     = aws_vpc.vpcref.id
  cidr_block = "10.0.4.0/23"

  tags = {
    Name = "dmz1"
  }
}

resource "aws_subnet" "dmz12" {
  vpc_id     = aws_vpc.vpcref.id
  cidr_block = "10.0.6.0/23"

  tags = {
    Name = "dmz1"
  }
}




resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpcref.id

  tags = {
    Name = "myigw"
  }
}


resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.vpcref.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "pubrt-vpc5"
  }
}


resource "aws_route_table" "dmzrt" {
  vpc_id = aws_vpc.vpcref.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "dmzrt-vpc5"
  }
}

resource "aws_route_table_association" "apub" {
  subnet_id      = aws_subnet.pub11.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_route_table_association" "bpub" {
  subnet_id      = aws_subnet.pub12.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_route_table_association" "admz" {
  subnet_id      = aws_subnet.dmz11.id
  route_table_id = aws_route_table.dmzrt.id
}

resource "aws_route_table_association" "bdmz" {
  subnet_id      = aws_subnet.dmz12.id
  route_table_id = aws_route_table.dmzrt.id
}
