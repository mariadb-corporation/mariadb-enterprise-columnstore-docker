![logo](https://raw.githubusercontent.com/mariadb-corporation/mariadb-enterprise-columnstore-docker/master/MDB-HLogo_RGB.jpg)

# MariaDB ColumnStore 1.4 Enterprise Docker Image

## Summary
MariaDB ColumnStore is a columnar storage engine that utilizes a massively parallel distributed data architecture. It was built by porting InfiniDB to MariaDB and has been released under the GPL license.

MariaDB ColumnStore is designed for big data scaling to process petabytes of data, linear scalability and exceptional performance with real-time response to analytical queries. It leverages the I/O benefits of columnar storage, compression, just-in-time projection, and horizontal and vertical partitioning to deliver tremendous performance when analyzing large data sets.

This project features a combined [UM/PM](https://mariadb.com/kb/en/library/columnstore-architectural-overview/) system with [monit](https://linux.die.net/man/1/monit) supervision, [tini](https://github.com/krallin/tini) `init` for containers, persistent storage and graceful startup/shutdown. This leaves ColumnStore in the proper state when a container is stopped and allows for easy restart.

## Quick Reference

* Detailed Documentation: [MariaDB Knowledge Base](https://mariadb.com/kb/en/library/mariadb-columnstore/)
* Public Forum: [Google Groups](https://groups.google.com/forum/#!forum/mariadb-columnstore)
* Jira System: [MCOL](https://jira.mariadb.org/projects/MCOL/issues)
* Sample: [Data Sets](https://github.com/mariadb-corporation/mariadb-columnstore-samples)

## Prerequisites

* [Enterprise Token](https://customers.mariadb.com/downloads/token/)
* [Docker](https://www.docker.com/products/docker-desktop)
* [Git](https://git-scm.com/downloads)

## Run Single Instance Container

To build the MariaDB ColumnStore image, run the following commands:

1. Visit our [website](https://customers.mariadb.com/downloads/token/) and grab your enterprise token
1. `git clone https://github.com/mariadb-corporation/mariadb-enterprise-columnstore-docker.git`
1. `cd` into the newly cloned folder
1. ```docker build . --tag mcs_image --build-arg MARIADB_ENTERPRISE_TOKEN=your_token_here```
1. ```docker run -d -p 3306:3306 --name mcs_container mcs_image```
1. ```docker exec -it mcs_container bash```

## Customization

The following environment variables can be utilized to configure behavior:

* ANALYTICS_ONLY : Set to 1 to create a system that enforces ColumnStore engine only
* MARIADB_ROOT_HOST : Additional host for root user (localhost and 127.0.0.1 already included)
* MARIADB_ROOT_PASSWORD : Specify the password for the root user
* S3_ACCESS_KEY_ID : Your S3 access id
* S3_BUCKET: Your S3 bucket name
* S3_ENDPOINT: Your endpoint url
* S3_SECRET_ACCESS_KEY: Your S3 access key
* USE_S3_STORAGE: Set to 1 to activate S3 storage

Example:

```
docker run -d -p 3306:3306 \
-e MARIADB_ROOT_HOST=% \
-e MARIADB_ROOT_PASSWORD=mypassword \
-e USE_S3_STORAGE=1 \
-e S3_BUCKET=your_bucket_name_here \
-e S3_ENDPOINT=your_url_here \
-e S3_ACCESS_KEY_ID=your_id_here \
-e S3_SECRET_ACCESS_KEY=your_key_here \
--name mcs_container mcs_image
```

## Usage

*Note: Once you run your docker container, ColumnStore processes may take a couple of minutes to start up.
An additional database user named '__cej__' has been created. Removal of this user will break the [cross engine join](https://mariadb.com/kb/en/configuring-columnstore-cross-engine-joins/) function of ColumnStore.*

#### For information about ColumnStore health:
```
[root@dockerid /]# mcsadmin getSystemInfo
```
#### To access MariaDB client:
```
[root@dockerid /]# mariadb
```

```
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 9
Server version: 10.4.11-5-MariaDB-enterprise MariaDB Enterprise Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```
