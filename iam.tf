# AWS Managed EC2 SSM Role
data "aws_iam_policy" "ec2ssm" { arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM" }

resource "aws_iam_instance_profile" "ssm" {
    name = "terraform_ec2_ssm"
    role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_iam_role" "ec2_ssm_role" {
    name = "terraform_ec2_ssm_role"
    path = "/"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "attach_role" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = data.aws_iam_policy.ec2ssm.arn
}