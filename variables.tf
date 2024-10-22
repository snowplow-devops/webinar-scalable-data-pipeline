variable "aws_region" {
  description = "The region in which the pipeline gets deployed"
  type        = string
}

variable "prefix" {
  description = "Will be prefixed to all resource names. Use to easily identify the resources created"
  type        = string
}

variable "vpc_id" {
  description = "The VPC to deploy the components within"
  type        = string
}

variable "public_subnet_ids" {
  description = "The list of public subnets to deploy the components across"
  type        = list(string)
}

variable "ssh_public_key" {
  description = "The SSH public key to use for the deployment"
  type        = string
}

variable "ssh_ip_allowlist" {
  description = "The list of CIDR ranges to allow SSH traffic from"
  type        = list(any)
}

variable "snowflake_account_url" {
  description = "Snowflake account URL to use"
  type        = string
}

variable "snowflake_loader_user" {
  description = "The Snowflake user used by Snowflake Streaming Loader"
  type        = string
}

variable "snowflake_loader_private_key" {
  description = "The private key to use for the loader user"
  type        = string
  sensitive   = true
}

variable "snowflake_database" {
  description = "Snowflake database name"
  type        = string
}

variable "snowflake_schema" {
  description = "Snowflake schema name"
  type        = string
}

variable "kinesis_stream_mode_details" {
  description = "The mode in which Kinesis Streams are setup"
  type        = string
}

variable "ec2_enable_auto_scaling" {
  description = "Whether to enable EC2 auto-scaling for Collector & Enrich"
  type        = bool
}

variable "ec2_collector_min_size" {
  description = "Min number of nodes for Collector"
  type        = number
}

variable "ec2_collector_max_size" {
  description = "Max number of nodes for Collector"
  type        = number
}

variable "ec2_collector_instance_type" {
  description = "Instance type for Collector"
  type        = string
}

variable "ec2_enrich_min_size" {
  description = "Min number of nodes for Enrich"
  type        = number
}

variable "ec2_enrich_max_size" {
  description = "Max number of nodes for Enrich"
  type        = number
}

variable "ec2_enrich_instance_type" {
  description = "Instance type for Enrich"
  type        = string
}

variable "ec2_sf_loader_min_size" {
  description = "Min number of nodes for Snowflake Loader"
  type        = number
}

variable "ec2_sf_loader_max_size" {
  description = "Max number of nodes for Snowflake Loader"
  type        = number
}

variable "ec2_sf_loader_instance_type" {
  description = "Instance type for Snowflake Loader"
  type        = string
}

variable "dyndb_kcl_read_min_capacity" {
  description = "Min read units for KCL Table"
  type        = number
}

variable "dyndb_kcl_read_max_capacity" {
  description = "Max read units for KCL Table"
  type        = number
}

variable "dyndb_kcl_write_min_capacity" {
  description = "Min write units for KCL Table"
  type        = number
}

variable "dyndb_kcl_write_max_capacity" {
  description = "Max write units for KCL Table"
  type        = number
}

variable "telemetry_enabled" {
  description = "Whether or not to send telemetry information back to Snowplow Analytics Ltd"
  type        = bool
  default     = true
}

variable "user_provided_id" {
  description = "An optional unique identifier to identify the telemetry events emitted by this stack"
  default     = ""
  type        = string
}

variable "iam_permissions_boundary" {
  description = "The permissions boundary ARN to set on IAM roles created"
  default     = ""
  type        = string
}
