module "dc24_mdb" {

  source = "github.com/terraform-yc-modules/terraform-yc-postgresql"

  network_id  = data.yandex_vpc_network.default.network_id
  name        = "dc24_mdb"
  description = "Single-node PostgreSQL cluster for test database"

  pg_version = "16"

  resource_preset_id = "b2.medium"
  disk_type          = "network-ssd"
  disk_size          = 50

  deletion_protection = false

  postgresql_config = {
    autovacuum_vacuum_scale_factor        = "0.1"
    autovacuum_max_workers                = 3
    autovacuum_naptime                    = 60000
    autovacuum_vacuum_insert_scale_factor = "0.2"
    autovacuum_vacuum_insert_threshold    = -1
    vacuum_cost_page_miss                 = 2 
  }

  maintenance_window = {
    type = "WEEKLY"
    day  = "SUN"
    hour = "01"
  }

  backup_retain_period_days = 7

  backup_window_start = {
    hours   = 22
    minutes = 55
  }

  access_policy = {
    web_sql = true
  }

  performance_diagnostics = {
    enabled                      = true
    sessions_sampling_interval   = 60
    statements_sampling_interval = 600
  }

  hosts_definition = [
    {
      zone = var.zone
      assign_public_ip = false
      subnet_id        = data.yandex_vpc_subnet.default.id
    }
  ]


  default_user_settings = {
    default_transaction_isolation = "read committed"
    log_min_duration_statement    = "5000"
  }

  databases = [
    {
      name       = var.target_database
      owner      = var.target_owner
      lc_collate = "ru_RU.UTF-8"
      lc_type    = "ru_RU.UTF-8"
      extensions = ["pg_stat_statements",  "uuid-ossp", "tablefunc"]

    },

  ]

  owners = [
    {
      name       = "dc24_owner"
      conn_limit = 50
    }
  ]


  users = [
    {
      "name" : "odmin",
      "grants" : [
        "mdb_admin",
        "mdb_monitor"
      ],
      "permissions" : [
        "dc24",
      ],
      "login" : true,
      "conn_limit" : 5
    },
    {
      "name" : "person_viewer",
      "grants" : [],
      "permissions" : [
        "dc24",
      ],
      "login" : false,
      "conn_limit" : 0
    },
    {
      "name" : "sales_admin",
      "grants" : [],
      "permissions" : [
        "dc24",
      ],
      "login" : false,
      "conn_limit" : 0
    },
    {
      "name" : "vasja",
      "grants" : ["person_viewer", "sales_admin"],
      "permissions" : [
        "dc24",
      ],
      "login" : false,
      "conn_limit" : 15
    },    
    {
      "name" : "mary",
      "grants" : ["person_viewer"],
      "permissions" : [
        "dc24",
      ],
      "login" : false,
      "conn_limit" : 15
    },   
  ]
}
