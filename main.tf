# --- COMMON

resource "aws_key_pair" "pipeline" {
  key_name   = "${var.prefix}-pipeline"
  public_key = var.ssh_public_key
}

# --- STREAMS

module "raw_stream" {
  source  = "snowplow-devops/kinesis-stream/aws"
  version = "0.3.0"

  name = "${var.prefix}-raw-stream"

  stream_mode_details = var.kinesis_stream_mode_details
}

module "bad_1_stream" {
  source  = "snowplow-devops/kinesis-stream/aws"
  version = "0.3.0"

  name = "${var.prefix}-bad-1-stream"

  stream_mode_details = var.kinesis_stream_mode_details
}

module "enriched_stream" {
  source  = "snowplow-devops/kinesis-stream/aws"
  version = "0.3.0"

  name = "${var.prefix}-enriched-stream"

  stream_mode_details = var.kinesis_stream_mode_details
}

# --- COLLECTOR

module "collector_lb" {
  source  = "snowplow-devops/alb/aws"
  version = "0.2.0"

  name              = "${var.prefix}-collector-lb"
  vpc_id            = var.vpc_id
  subnet_ids        = var.public_subnet_ids
  health_check_path = "/health"
}

module "collector_kinesis" {
  source  = "snowplow-devops/collector-kinesis-ec2/aws"
  version = "0.9.1"

  accept_limited_use_license = true

  name               = "${var.prefix}-collector-server"
  vpc_id             = var.vpc_id
  subnet_ids         = var.public_subnet_ids
  collector_lb_sg_id = module.collector_lb.sg_id
  collector_lb_tg_id = module.collector_lb.tg_id
  ingress_port       = module.collector_lb.tg_egress_port
  good_stream_name   = module.raw_stream.name
  bad_stream_name    = module.bad_1_stream.name

  ssh_key_name     = aws_key_pair.pipeline.key_name
  ssh_ip_allowlist = var.ssh_ip_allowlist

  enable_auto_scaling = var.ec2_enable_auto_scaling
  min_size            = var.ec2_collector_min_size
  max_size            = var.ec2_collector_max_size
  instance_type       = var.ec2_collector_instance_type

  iam_permissions_boundary = var.iam_permissions_boundary
  user_provided_id         = var.user_provided_id
  telemetry_enabled        = var.telemetry_enabled
}

# --- ENRICH

module "enrich_kinesis" {
  source  = "snowplow-devops/enrich-kinesis-ec2/aws"
  version = "0.6.1"

  accept_limited_use_license = true

  name                 = "${var.prefix}-enrich-server"
  vpc_id               = var.vpc_id
  subnet_ids           = var.public_subnet_ids
  in_stream_name       = module.raw_stream.name
  enriched_stream_name = module.enriched_stream.name
  bad_stream_name      = module.bad_1_stream.name

  ssh_key_name     = aws_key_pair.pipeline.key_name
  ssh_ip_allowlist = var.ssh_ip_allowlist

  enable_auto_scaling = var.ec2_enable_auto_scaling
  min_size            = var.ec2_enrich_min_size
  max_size            = var.ec2_enrich_max_size
  instance_type       = var.ec2_enrich_instance_type

  kcl_read_min_capacity  = var.dyndb_kcl_read_min_capacity
  kcl_read_max_capacity  = var.dyndb_kcl_read_max_capacity
  kcl_write_min_capacity = var.dyndb_kcl_write_min_capacity
  kcl_write_max_capacity = var.dyndb_kcl_write_max_capacity

  iam_permissions_boundary = var.iam_permissions_boundary
  user_provided_id         = var.user_provided_id
  telemetry_enabled        = var.telemetry_enabled
}

# --- SNOWFLAKE LOADER

module "sf_loader" {
  source  = "snowplow-devops/snowflake-streaming-loader-ec2/aws"
  version = "0.1.2"

  accept_limited_use_license = true

  name            = "${var.prefix}-sf-loader"
  vpc_id          = var.vpc_id
  subnet_ids      = var.public_subnet_ids
  in_stream_name  = module.enriched_stream.name
  bad_stream_name = module.bad_1_stream.name

  ssh_key_name     = aws_key_pair.pipeline.key_name
  ssh_ip_allowlist = var.ssh_ip_allowlist

  enable_auto_scaling = var.ec2_enable_auto_scaling
  min_size            = var.ec2_sf_loader_min_size
  max_size            = var.ec2_sf_loader_max_size
  instance_type       = var.ec2_sf_loader_instance_type

  snowflake_account_url = var.snowflake_account_url
  snowflake_loader_user = var.snowflake_loader_user
  snowflake_private_key = var.snowflake_loader_private_key
  snowflake_database    = var.snowflake_database
  snowflake_schema      = var.snowflake_schema

  kcl_read_min_capacity  = var.dyndb_kcl_read_min_capacity
  kcl_read_max_capacity  = var.dyndb_kcl_read_max_capacity
  kcl_write_min_capacity = var.dyndb_kcl_write_min_capacity
  kcl_write_max_capacity = var.dyndb_kcl_write_max_capacity

  iam_permissions_boundary = var.iam_permissions_boundary
  user_provided_id         = var.user_provided_id
  telemetry_enabled        = var.telemetry_enabled
}

# --- CLOUDWATCH DASHBOARD

data "aws_caller_identity" "current" {}

locals {
  collector_lb_arn_cw_id = replace(
    module.collector_lb.arn,
    "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/",
    ""
  )
}

resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.prefix}-pipeline"

  dashboard_body = templatefile("./templates/pipeline_dashboard.json.tmpl", {
    aws_region       = var.aws_region,
    prefix           = var.prefix
    collector_lb_arn = local.collector_lb_arn_cw_id
  })
}
