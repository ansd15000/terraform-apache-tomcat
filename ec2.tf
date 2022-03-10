data "aws_ami" "amazon_linux2" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-ebs"]
    }
}

data "aws_ami" "nat" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn-ami-vpc-nat-*-x86_64-ebs"]
    }
}

data "dns_a_record_set" "nlb" {
    host = aws_lb.internal.dns_name
    depends_on = [
        aws_lb.internal
    ]
}

data "template_file" "apache" {
    template = file("userdatas/apache.sh")
    vars = {
        nlb1 = element(split(",",join(",", data.dns_a_record_set.nlb.addrs)),0)
        nlb2 = element(split(",",join(",", data.dns_a_record_set.nlb.addrs)),1)
    }
}

data "template_file" "tomcat9" {
    template = file("userdatas/tomcat9.sh")
}

resource "aws_instance" "nat" {
    ami = data.aws_ami.nat.id
    instance_type = var.t3
    key_name = var.key_pair
    iam_instance_profile = aws_iam_instance_profile.ssm.id
    source_dest_check = false
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [aws_default_security_group.all_allow.id]
    private_ip = "80.0.0.10"
    root_block_device {
        volume_type = "gp3"
    }
    tags = {
        Name = "${var.service_name}_nat"
    }
}

resource "aws_instance" "web" {
    count = 2
    ami = data.aws_ami.amazon_linux2.id
    instance_type = var.t3
    network_interface {
        network_interface_id = aws_network_interface.web[count.index].id
        device_index = 0
    }
    root_block_device {
        volume_type = "gp3"
    }
    key_name = var.key_pair
    iam_instance_profile = aws_iam_instance_profile.ssm.id
    # user_data = file("userdatas/was-php-fpm.sh")
    user_data = data.template_file.apache.rendered
    tags = {
        Name = "terraform_web ${count.index + 1}"
    }
}

resource "aws_instance" "was" {
    count = 2
    ami = data.aws_ami.amazon_linux2.id
    instance_type = var.t3
    network_interface {
        network_interface_id = aws_network_interface.was[count.index].id
        device_index = 0
    }
    root_block_device {
        volume_type = "gp3"
    }
    key_name = var.key_pair
    iam_instance_profile = aws_iam_instance_profile.ssm.id
    # user_data = file("userdatas/tomcat9.sh")
    user_data = data.template_file.tomcat9.rendered
    tags = {
        Name = "terraform_was ${count.index + 1}"
    }
}