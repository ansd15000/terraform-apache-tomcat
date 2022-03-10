resource "aws_lb" "external" {
    name = "terraform-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_default_security_group.all_allow.id ]
    subnets = [for subnet in aws_subnet.public : subnet.id]

    tags = {
        # Environment = "production" # 태그별로 뭐 달리할수있는건가?
        Name = "alb"
    }
}


resource "aws_lb_target_group" "alb-target" {
    name = "alb-target"  
    port = "80"
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "alb-target"
    }
}

resource "aws_alb_listener" "target-web" {
    load_balancer_arn = aws_lb.external.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.alb-target.arn
    }
}

resource "aws_lb_target_group_attachment" "web" {
    count = length(aws_instance.web)
    target_group_arn = aws_lb_target_group.alb-target.arn
    # target_id = aws_network_interface.web[count.index].id
    target_id = aws_instance.web[count.index].id
    port = 80
}

resource "aws_lb" "internal" {
    name = "terra-nlb"
    internal = true
    load_balancer_type = "network"
    subnets = [for i, _ in aws_subnet.private : aws_subnet.private[i].id if i > 1]
    tags = {
        Name = "terraform nlb"
    }
}

resource "aws_lb_target_group" "nlb-target" {
    name = "terraform-nlb-target"
    vpc_id = aws_vpc.vpc.id
    port = "8009"
    protocol = "TCP"
    target_type = "ip"
    tags = {
        Name = "terraform nlb target"
    }
}

resource "aws_lb_listener" "target-was" {
    load_balancer_arn = aws_lb.internal.arn
    port = "8009"
    protocol = "TCP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.nlb-target.arn
    }
}

resource "aws_lb_target_group_attachment" "was" {
    count = length(aws_instance.was)
    target_group_arn = aws_lb_target_group.nlb-target.arn
    # target_id = aws_instance.was[count.index].private_ip
    target_id = aws_network_interface.was[count.index].private_ip
    port = 8009
}