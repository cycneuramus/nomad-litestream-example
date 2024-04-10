# Nomad + Litestream example

This repository contains a hacky [Nomad](https://www.nomadproject.io) job that deploys an SQLite backed application (in this case, [Navidrome](https://github.com/navidrome/navidrome)) and leverages [Litestream](https://litestream.io) to synchronize the database to, and restore it from, an S3 endpoint.

## Why?

The point of this example job is to demonstrate a gross but functional way of achieving high availability with SQLite-based applications. SQLite, being file-based, doesn't inherently support the distributed data synchronization required by multi-node deployments, and is notoriously unreliable over network filesystems (e.g. NFS).

So, by continuously streaming the SQLite database changes to an S3 endpoint and—this is the gross part—restoring its state from this endpoint on every redeploy, this example job remains effectively agnostic to the underlying database's physical location.

## Prerequisites

+ A Nomad cluster with Docker runtime support
+ An S3 bucket (selfhosted or otherwise) with read/write permissions

## Usage

+ In the `.env` file: fill out your S3 credentials and configuration details.
+ In `navidrome.hcl`: change `~/path/to/navidrome-dir` to the relevant path on your host(s)
+ On all nodes: `mkdir ~/path/to/navidrome-dir/db`.
+ `nomad run navidrome.hcl`.

**NOTE**: For the sake of this example, the `cache` and `music` directories in the Nomad job are simple bind-mounts, which technically defeats the purpose of this pseudo-stateless deployment, so it's up to you to configure the storage mechanism of your choosing here.
