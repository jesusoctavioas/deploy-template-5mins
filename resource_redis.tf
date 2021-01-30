resource "aws_elasticache_subnet_group" "redis_subnet" {
  name = "redis-subnet-${var.SHORT_ENVIRONMENT_NAME}"
  subnet_ids = [aws_subnet.subnet_primary.id]
}

resource "aws_elasticache_cluster" "redis" {
  count = 1
  cluster_id = "redis-cluster-${var.SHORT_ENVIRONMENT_NAME}"
  engine = "redis"
  node_type = var.REDIS_NODE_TYPE
  num_cache_nodes = 1
  port = 6379
  security_group_ids = [aws_security_group.security_group.id]
  subnet_group_name = aws_elasticache_subnet_group.redis_subnet.name
}

# Output

output "redis_address" {
  value = aws_elasticache_cluster.redis.0.cache_nodes.0.address
}

output "redis_port" {
  value = aws_elasticache_cluster.redis.0.port
}

output "redis_availability_zone" {
  value = aws_elasticache_cluster.redis.0.availability_zone
}

output "redis_url" {
  value = "redis://${aws_elasticache_cluster.redis.0.cache_nodes.0.address}:${aws_elasticache_cluster.redis.0.port}"
}
