variable "settings" {
  description = "Configuration settings"
  type        = map(any)
  default = {
    "database" = {
      allocated_storage   = 10            // storage in gigabytes
      engine              = "mysql"       // engine type
      engine_version      = "8.0.28"      // engine version
      instance_class      = "db.t2.micro" // rds instance type
      db_name             = "tutorial"    // database name
      skip_final_snapshot = true
    },
  }
}

variable "db_password" {
  default = "Shimi431"
}

variable "db_username" {
  default = "shlomi"
}