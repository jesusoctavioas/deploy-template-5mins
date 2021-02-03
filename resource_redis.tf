resource "aws_elasticache_subnet_group" "redis_subnet" {
  count = var.DISABLE_REDIS == "true" ? 0 : 1
  name = "redis-subnet-${var.SHORT_ENVIRONMENT_NAME}"
  subnet_ids = [aws_subnet.subnet_primary.id]
}

resource "aws_elasticache_cluster" "redis" {
  count = var.DISABLE_REDIS == "true" ? 0 : 1
  cluster_id = "redis-cluster-${var.SHORT_ENVIRONMENT_NAME}"
  engine = "redis"
  node_type = var.REDIS_NODE_TYPE
  num_cache_nodes = 1
  port = 6379
  security_group_ids = [aws_security_group.security_group.id]
  subnet_group_name = aws_elasticache_subnet_group.redis_subnet[0].name
}

# Output

output "redis_address" {
  value = var.DISABLE_REDIS == "true" ? null : aws_elasticache_cluster.redis.0.cache_nodes.0.address
}

output "redis_port" {
  value = var.DISABLE_REDIS == "true" ? null : aws_elasticache_cluster.redis.0.port
}

output "redis_availability_zone" {
  value = var.DISABLE_REDIS == "true" ? null : aws_elasticache_cluster.redis.0.availability_zone
}

output "redis_url" {
  value = var.DISABLE_REDIS == "true" ? null : "redis://${aws_elasticache_cluster.redis.0.cache_nodes.0.address}:${aws_elasticache_cluster.redis.0.port}"
}
