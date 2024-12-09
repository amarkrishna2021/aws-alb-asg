resource "aws_security_group" "alb_sg" {
    name = "yt_alb_sg"
    description = "Security group for application load balancer"

    vpc_id = aws_vpc.asg_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = {
      name = "yt_alb_sg"
    }
}

# Create security group for the ALB to EC2 instance

resource "aws_security_group" "ec2_sg" {
    name = "yt-ec2-sg"
    description = "security group for the web server"
    vpc_id = aws_vpc.asg_vpc.id

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups=  [aws_security_group.alb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]

    }

    tags = {
      name = "yt web server sg"
    }
  
}