locals {
  source_user = "transfer" # Set the source cluster username.
  source_database = "adventureworks"

  source_pwd  = var.transfer_password
  source_host = yandex_compute_instance.instance.network_interface.0.ip_address 
  source_port = 5432              
}

resource "yandex_datatransfer_endpoint" "dc24-transfer-source" {
  description = "Source endpoint for PostgreSQL cluster"
  name        = "dc24-source"
  settings {
    postgres_source {
      connection {
        on_premise {
          hosts     = [local.source_host]
          port      = local.source_port
          subnet_id = data.yandex_vpc_subnet.default.id
        }
      }
      database       = local.source_database
      service_schema = "ya_transfer"
      user           = local.source_user
      password {
        raw = local.source_pwd
      }
      object_transfer_settings {
        function = "BEFORE_DATA"
      }
    }
  }
  depends_on = [ module.dc24_mdb ]
}

resource "yandex_datatransfer_endpoint" "dc24-transfer-target" {
  description = "Target endpoint for the Managed Service for PostgreSQL cluster"
  name        = "dc24-target"
  settings {
    postgres_target {
      connection {
        mdb_cluster_id = module.dc24_mdb.cluster_id
      }
      database = var.target_database
      user     = var.target_owner
      password {
        raw = module.dc24_mdb.owners_data.0.password
      }
    }
  }
  depends_on = [ module.dc24_mdb ]
}

resource "yandex_datatransfer_transfer" "pgsql-transfer" {
  description = "Transfer from PostgreSQL cluster to the Managed Service for PostgreSQL cluster"
  name        = "transfer-dc24"
  source_id   = yandex_datatransfer_endpoint.dc24-transfer-source.id
  target_id   = yandex_datatransfer_endpoint.dc24-transfer-target.id
  type        = "SNAPSHOT_AND_INCREMENT" # Copy all data from the source cluster and start replication.
}
