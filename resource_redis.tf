resource "aws_elasticache_cluster" "redis" {
  count = var.REDIS_NODE_TYPE != "" ? 1 : 0
  cluster_id = "redis-cluster"
  engine = "redis"
  node_type = var.REDIS_NODE_TYPE
  num_cache_nodes = 1
  port = 6379
  security_group_ids = [aws_security_group.redis.id]
}

resource "aws_security_group" "redis" {
  name = "${var.ENVIRONMENT_NAME}_REDIS"
  vpc_id = data.aws_vpc.default.id
  tags = local.common_tags
}

resource "aws_security_group_rule" "allow_redis_access" {
  type = "ingress"
  from_port = 6379
  to_port = 6379
  protocol = "tcp"
  security_group_id = aws_security_group.redis.id
  cidr_blocks = ["0.0.0.0/0"]
}

# Output

output "redis_address" {
  value = var.REDIS_NODE_TYPE != "" ? aws_elasticache_cluster.redis.0.cache_nodes.0.address : ""
}

output "redis_port" {
  value = var.REDIS_NODE_TYPE != "" ? aws_elasticache_cluster.redis.0.port : ""
}

output "redis_availability_zone" {
  value = var.REDIS_NODE_TYPE != "" ? aws_elasticache_cluster.redis.0.availability_zone : ""
}

output "redis_url" {
  value = var.REDIS_NODE_TYPE != "" ? "redis://${aws_elasticache_cluster.redis.0.cache_nodes.0
  .address}:${aws_elasticache_cluster.redis.0.port}" : ""
}
