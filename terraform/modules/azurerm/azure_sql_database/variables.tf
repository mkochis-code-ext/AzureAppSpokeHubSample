variable "name" {
  description = "Name of the SQL Database"
  type        = string
}

variable "server_id" {
  description = "ID of the SQL Server"
  type        = string
}

variable "collation" {
  description = "Collation of the database"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "max_size_gb" {
  description = "Maximum size of the database in gigabytes"
  type        = number
  default     = 2
}

variable "sku_name" {
  description = "SKU name for the database"
  type        = string
  default     = "Basic"
}

variable "zone_redundant" {
  description = "Enable zone redundancy"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
