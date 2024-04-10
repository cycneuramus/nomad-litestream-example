locals {
  storage   = pathexpand("~/path/to/navidrome-dir")
  sqlite_db = "navidrome.db"

  navidrome_version  = "0.51.1"
  litestream_version = "0.3.13"

  litestream_config = <<-EOF
    access-key-id: $S3_ID
    secret-access-key: $S3_KEY

    dbs:
      - path: /data/${local.sqlite_db}
        replicas:
          - type: s3
            bucket: $S3_BUCKET
            path: litestream/navidrome
            endpoint: $S3_HOST
            retention: 1h
  EOF
}

job "navidrome" {
  group "navidrome" {
    network {
      port "http" {
        to = 4533
      }
    }

    task "litestream-restore" {
      driver = "docker"
      user   = "1000:1000"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = "${local.litestream_config}"
        destination = "local/litestream.yml"
      }

      template {
        data        = file("litestream.sh")
        destination = "local/entrypoint.sh"
        perms       = "755"
      }

      config {
        image      = "litestream/litestream:${local.litestream_version}"
        entrypoint = ["/local/entrypoint.sh", "${local.sqlite_db}"]

        mount {
          type   = "bind"
          source = "${local.storage}/db"
          target = "/data"
        }
      }
    }

    task "litestream-replicate" {
      driver = "docker"
      user   = "1000:1000"

      kill_timeout = "30s"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = "${local.litestream_config}"
        destination = "local/litestream.yml"
      }

      config {
        image      = "litestream/litestream:${local.litestream_version}"
        entrypoint = ["litestream", "replicate", "-config", "/local/litestream.yml"]

        mount {
          type   = "bind"
          source = "${local.storage}/db"
          target = "/data"
        }
      }
    }

    task "navidrome" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "navidrome"
        port     = "http"
        provider = "nomad"
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "ghcr.io/navidrome/navidrome:${local.navidrome_version}"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.storage}/db"
          target = "/data"
        }

        # Example only; should be changed
        mount {
          type   = "bind"
          source = "${local.storage}/cache"
          target = "/data/cache"
        }

        # Example only; should be changed
        mount {
          type   = "bind"
          source = "${local.storage}/music"
          target = "/music"
        }
      }
    }
  }
}
