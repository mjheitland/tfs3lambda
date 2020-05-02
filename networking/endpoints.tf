#--- networking/endpoints.terraform

#-----------------
#--- VPC Endpoints
#-----------------

resource "aws_vpc_endpoint" "s3_vpce" {
  vpc_id            = aws_vpc.vpc1.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = format("%s_s3_vpce", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_vpc_endpoint" "ssm_vpce" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.sgpub1.id]
  subnet_ids          = [aws_subnet.subpub1.*.id[0]]
  tags = {
    Name = format("%s_ssm_vpce", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_vpc_endpoint" "ssmmessages_vpce" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.sgpub1.id]
  subnet_ids          = [aws_subnet.subpub1.*.id[0]]
  tags = {
    Name = format("%s_ssmmessages_vpce", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_vpc_endpoint" "ec2_vpce" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.sgpub1.id]
  subnet_ids          = [aws_subnet.subpub1.*.id[0]]
  tags = {
    Name = format("%s_ec2_vpce", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_vpc_endpoint" "ec2messages_vpce" {
  vpc_id              = aws_vpc.vpc1.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.sgpub1.id]
  subnet_ids          = [aws_subnet.subpub1.*.id[0]]
  tags = {
    Name = format("%s_ec2messages_vpce", var.project_name)
    project_name = var.project_name
  }
}