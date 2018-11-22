resource "aws_subnet" "archivematica-redis-subnet" {
  vpc_id            = "${aws_vpc.archivematica-vpc3.id}"
  cidr_block        = "10.0.127.0/24"
  availability_zone = "eu-west-1b"

  tags {
    Name = "archivematica-subnet"
  }
}

resource "aws_elasticache_subnet_group" "archivematica-subnet-group" {
  name       = "archivematica-subnet-group"
  subnet_ids = ["${aws_subnet.archivematica-redis-subnet.id}"]
}

//# todo: we would use "aws_elasticache_replication_group" if we need replications
resource "aws_elasticache_cluster" "archivematica-redis" {
  cluster_id           = "archivematica-redis"
  engine               = "redis"
  node_type            = "cache.m3.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  port                 = 6379

  subnet_group_name = "${aws_elasticache_subnet_group.archivematica-subnet-group.name}"
}
