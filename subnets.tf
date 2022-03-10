data "aws_availability_zones" "azs" {
    exclude_zone_ids = [ "apne2-az2", "apne2-az4" ] # 제외 가용영역
}

resource "aws_subnet" "public" {
    count = 2 # 현 리소스를 두번 반복
    vpc_id = aws_vpc.vpc.id
    availability_zone = element(data.aws_availability_zones.azs.names, count.index) # 인덱스 길이 초과시 0번째 요소부터 다시 반환하는element
    cidr_block = cidrsubnet(var.cidr,8,count.index) # ip range, newbits, netnum
    map_public_ip_on_launch = true
    tags = {
        Name = "terraform_pub ${count.index + 1}"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public_route" {
    route_table_id = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "attach_public_subnet" {
    count = length(aws_subnet.public)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat" {
    vpc = true
    instance = aws_instance.nat.id
}

# ---------------------------------------#
# web, was (4)
resource "aws_subnet" "private" {
    count = 4
    vpc_id = aws_vpc.vpc.id
    availability_zone = element(data.aws_availability_zones.azs.names, count.index)
    cidr_block = cidrsubnet(var.cidr, 8, 128+count.index)
    tags = {
        Name = "terraform_priv ${count.index + 1}"
    }
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "private_route" {
    route_table_id = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    # network_interface_id = aws_network_interface.nat.id
    network_interface_id = aws_instance.nat.primary_network_interface_id
}

resource "aws_route_table_association" "attach_private_subnet" {
    count = length(aws_subnet.private)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_network_interface" "web" {
    count = 2
    security_groups = [aws_default_security_group.all_allow.id]
    subnet_id = element(slice(aws_subnet.private[*].id, 0, 2), count.index)
}

resource "aws_network_interface" "was" {
    count = 2
    security_groups = [aws_default_security_group.all_allow.id]
    subnet_id = element(slice(aws_subnet.private[*].id, 2, 4), count.index)
}