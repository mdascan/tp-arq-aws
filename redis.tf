resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "group-1"
  replication_group_description = "Redis"
  node_type                     = "cache.t2.micro"
  number_cache_clusters         = 1
  parameter_group_name          = "default.redis3.2"
  port                          = 6379
  security_group_ids            = ["${aws_security_group.redis.id}"]

  provisioner "local-exec" {
    command = "echo ${aws_elasticache_replication_group.redis.primary_endpoint_address} >> node/redis_dns"
  }
}