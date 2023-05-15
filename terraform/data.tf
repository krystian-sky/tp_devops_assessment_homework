data "aws_route_table" "vpc_routing_table" {
    vpc_id = aws_vpc.fargate_vpc.id
}
