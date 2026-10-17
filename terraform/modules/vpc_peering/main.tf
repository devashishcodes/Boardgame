resource "aws_vpc_peering_connection" "this" {
  vpc_id      = var.vpc_id
  peer_vpc_id = var.peer_vpc_id
  auto_accept = true # same account + same region

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = { Name = "${var.name_prefix}-vpc-peering" }
}

# boardgame-vpc ke route tables -> default-vpc (Pritunl)
resource "aws_route" "to_peer" {
  count = length(var.local_route_table_ids)

  route_table_id            = var.local_route_table_ids[count.index]
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# default-vpc ke route tables -> boardgame-vpc
resource "aws_route" "from_peer" {
  count = length(var.peer_route_table_ids)

  route_table_id            = var.peer_route_table_ids[count.index]
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
