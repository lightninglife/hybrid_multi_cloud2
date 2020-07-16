provider "aws" {
 region = "ap-south-1"
 profile = "Moiz"
}


variable "key_name" {}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_instance" "myos" {
 ami           = "ami-0732b62d310b80e97"
 availability_zone = "ap-south-1a"
 key_name   = var.key_name
 instance_type = "t2.micro"
 security_groups = [aws_security_group.allow_network_services.name]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.example.private_key_pem
    host     = aws_instance.myos.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

 tags = {
   Name = "MyBoi"
 }
}

// resource "tls_private_key" "my_key" {
//   algorithm = "RSA"
//   rsa_bits  = 2048
// }


// resource "aws_key_pair" "my_key" {
//   key_name   = "keyc"
//   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7kXdRvfRleQjdwHHnZmEN+ZZtiE4tBriOS0YfoWB10yV6FBj4h4HkU31Ig3DQgT+8hC8ggb8AXuEGJQ+fuY1gaBlUD0JeWrr5CvbZVXI84RjbD5AhsaRFSNNvL1G83BsCx1fCG6GmG/iTux4LzezI+LFlrxrClJStfXQbsWH4ctT3E6W393m8QGbLoqo1gJVDQMTVDS3TV5a2DvbMN2hUlmhTfM+VpzjXIdS99MN78HHfQWqYjDMRXWqOVafF0oMmrNdc6dyeEaEBdeQQ5Aof0jVw1SZocGVygmBHLtW0Lc11Ln4iliOTlxcgwM6BR/mnZltfnErGi/lleTjXZIaP moiz.7152@gmail.com"
// }


resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}


resource "aws_security_group" "allow_network_services" {
  name        = "allow_network_services"
  description = "Allow SSH, ICMP and TCP"
  vpc_id = aws_default_vpc.default.id

  ingress {
    description = "Incoming Request on HTTPs/TLS"
    from_port   = 443	
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Incoming Request on HTTP"
    from_port   = 80	
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {    
   description = "SSH"    
   from_port   = 22    
   to_port     = 22
   protocol    = "tcp"    
   cidr_blocks = [ "0.0.0.0/0" ]  
}

ingress {
  description = "Checking Connection"
  cidr_blocks = ["0.0.0.0/0"]
  protocol = "icmp"
  from_port = -1
  to_port = -1
}

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

  tags = {
    Name = "Allow SSH, ICMP and TCP"
  }
}

resource "aws_efs_file_system" "allow_nfs" {
 depends_on =  [ aws_security_group.allow_network_services, aws_instance.myos,  ] 
  creation_token = "allow_nfs"


  tags = {
    Name = "allow_nfs"
  }
}

resource "aws_efs_mount_target" "alpha" {
 depends_on =  [ aws_efs_file_system.allow_nfs, ] 
  file_system_id = aws_efs_file_system.allow_nfs.id
  subnet_id      = aws_instance.myos.subnet_id
  security_groups = [aws_security_group.allow_network_services.id]
}


// resource "aws_ebs_volume" "esb2" {
//   availability_zone = aws_instance.myos.availability_zone
//   size = 1

//   tags = {
//     Name = "myebs1"
//   }
// }

// resource "aws_volume_attachment" "attaching_ebs" {
//   device_name = "/dev/sdd"
//   volume_id   = aws_ebs_volume.esb2.id
//   instance_id = aws_instance.myos.id
//   force_detach = true
// }


resource "null_resource" "nullremote1"  {
 depends_on = [ aws_efs_mount_target.alpha, ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.example.private_key_pem
    host     = aws_instance.myos.public_ip
  }
  provisioner "remote-exec" {
      inline = [
        "sudo echo ${aws_efs_file_system.allow_nfs.dns_name}:/var/www/html efs defaults,_netdev 0 0 >> sudo /etc/fstab",
        "sudo mount  ${aws_efs_file_system.allow_nfs.dns_name}:/  /var/www/html",
        "sudo rm -rf /var/www/html/*",
        "sudo git clone https://github.com/Moiz-Ali-Moomin/hybrid_multi_cloud2.git /var/www/html/"
      ]
  }
}


// resource "null_resource" "nullremote1"  {

// depends_on = [aws_volume_attachment.attaching_ebs,aws_key_pair.generated_key]


//   connection {
//     type     = "ssh"
//     user     = "ec2-user"
//     private_key = tls_private_key.example.private_key_pem
//     host     = aws_instance.myos.public_ip
//   }

// provisioner "remote-exec" {
//     inline = [
//       "sudo mkfs.ext4  /dev/xvdd",
//       "sudo mount  /dev/xvdd  /var/www/html",
//       "sudo rm -rf /var/www/html/*",
//       "sudo git clone https://github.com/Moiz-Ali-Moomin/hybrid_multi_cloud1.git /var/www/html/"
//     ]
//   }
// }


resource "null_resource" "nulllocal2"  {

depends_on = [
    null_resource.nullremote1,
    aws_cloudfront_distribution.s3_distribution,
    aws_key_pair.generated_key,
  ]


	provisioner "local-exec" {
	    command = "firefox  ${aws_instance.myos.public_ip}"
  	}
}    

resource "aws_s3_bucket" "my-web-code" {
  bucket = "my-web-code"
  acl    = "public-read"

  provisioner "local-exec"  {
    command = "git clone https://github.com/Moiz-Ali-Moomin/hybrid_multi_cloud2.git images"
  }

    provisioner "local-exec" {
		
			when = destroy
			command = "rm -rf images"
		}


  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::my-web-code/*"
    }
  ]
}

POLICY

cors_rule {
allowed_headers = ["*"]
allowed_methods = ["PUT", "POST"]
allowed_origins = ["*"]
expose_headers  = ["ETag"]
max_age_seconds = 3000
}


  versioning {
    enabled = true
  }
  tags = {
      Name = "web-code-bucket"  
  }
}

resource "aws_s3_bucket_object" "myobject" {
  bucket = aws_s3_bucket.my-web-code.bucket
  key    = "image.png"
  acl = "public-read"
  source = "images/image.png"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Access Identity created"
}


locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {  

  origin {
    domain_name = aws_s3_bucket.my-web-code.bucket_domain_name
    origin_id   = local.s3_origin_id

   s3_origin_config {
    origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }

  }

  enabled             = true
  is_ipv6_enabled     = true



  # Cache behavior with precedence 1
  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

     forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
  }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = [ "IN","US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.example.private_key_pem
    host     = aws_instance.myos.public_ip
  }

  provisioner "remote-exec" {
    inline = [                   
   "sudo su",
   "sudo cd /var/www/html/",
   "sudo su << EOF",
   "echo \"<img src='http://${aws_cloudfront_distribution.s3_distribution.domain_name}$/{aws_s3_bucket_object.myobject.key}'>\" >> index.php",   
   "EOF",
    ]
  }
}



data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.my-web-code.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.my-web-code.arn}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn] 
    }
  }
}

resource "aws_s3_bucket_policy" "my_policy" {
  bucket = aws_s3_bucket.my-web-code.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

output  "avalability_zone_id" {
	value = aws_instance.myos.availability_zone
}

output  "my_sec_public_ip" {
	value = aws_instance.myos.public_ip
}