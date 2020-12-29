resource "aws_elasticache_cluster" "redis" {
  count = var.REDIS_NODE_TYPE != "" ? 1 : 0
  cluster_id = "redis-cluster"
  engine = "redis"
  node_type = var.REDIS_NODE_TYPE
  num_cache_nodes = 1
  port = 6379
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
