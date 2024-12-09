# Create application load balencer
resource "aws_lb" "app_lb" {
    name = "yt-app-lb"
    load_balancer_type = "application"
    internal = false
    security_groups = [ aws_security_group.alb_sg.id ]
    subnets = aws_subnet.Publice_subnet[*].id
    depends_on = [ aws_internet_gateway.igw_vpc ]
 
}

# Target group for ALB

resource "aws_lb_target_group" "alb_ec2_tg" {
    name = "yt-web-server-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.asg_vpc.id
    tags = {
        name = "yt-alb-ec2-tg"
    }
  
}

# Create the listener for the ALB

resource "aws_lb_listener" "alb_listener" {
    load_balancer_arn = aws_lb.app_lb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb_ec2_tg.arn
    }

    tags = {
      name = "yt alb listener"
    }
}

# Launch template for the auto scaling group

resource "aws_launch_template" "ec2_launch_template" {
    name = "yt-web-server1"
    image_id = "ami-0c76bd4bd302b30ec"
    instance_type = "t2.micro"


    network_interfaces {
      associate_public_ip_address = false
      security_groups = [ aws_security_group.ec2_sg.id ]
    }

    user_data = filebase64("userdata.sh")

    tag_specifications {
      resource_type = "instance"
      tags = {
        name = "yt-ec2-web-server"
      }
    }
  
}

# create auto scaling group  for the YT web server

resource "aws_autoscaling_group" "ec2_asg" {
    max_size = 3
    min_size = 1
    desired_capacity = 2

    name = "yt-ec2-asg"
    target_group_arns = [ aws_lb_target_group.alb_ec2_tg.arn ]
    vpc_zone_identifier = aws_subnet.private_subnet[*].id

    launch_template {
      id = aws_launch_template.ec2_launch_template.id
      version = "$Latest"
    }

    health_check_type = "EC2"
  
}

output "alb_dns_name" {
    value = aws_lb.app_lb.dns_name
  
}