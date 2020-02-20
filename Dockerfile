# vim:set ft=dockerfile:
FROM centos:7

# Default env variables
ENV TINI_VERSION=v0.18.0

ARG MARIADB_ENTERPRISE_TOKEN
# Update system
RUN yum -y install epel-release && \
    yum -y upgrade

# Install some basic dependencies
RUN yum -y install bind-utils \
    bc \
    boost \
    curl \
    expect \
    file \
    jemalloc \
    libaio \
    libcurl \
    libnl \
    libxml2 \
    lsof \
    monit \
    nano \
    net-tools \
    nmap \
    numactl-libs \
    openssh-clients \
    openssh-server \
    openssl \
    perl \
    perl-DBI \
    psmisc \
    rsync \
    rsyslog \
    snappy \
    sudo \
    sysvinit-tools \
    wget \
    which \
    zlib && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /etc/rsyslog.d/listen.conf && \
    localedef -i en_US -f UTF-8 en_US.UTF-8

ADD https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup /tmp
RUN chmod +x /tmp/mariadb_es_repo_setup && \
    /tmp/mariadb_es_repo_setup --token=${MARIADB_ENTERPRISE_TOKEN} --apply

# Install MariaDB/ColumnStore packages
RUN yum -y install MariaDB-server \
    MariaDB-columnstore-platform \
    MariaDB-columnstore-engine && \
    columnstore-post-install && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    mkdir -p /var/log/mysql && \
    chown -R mysql:mysql /var/log/mysql

# Add Tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

# Copy files to image
COPY config/rsyslog.conf \
     config/monitrc \
     config/monit.d/ /etc/
COPY config/storagemanager.cnf /etc/columnstore/storagemanager.cnf
COPY config/columnstore.cnf /etc/my.cnf.d/columnstore.cnf
COPY scripts/columnstore-restart \
     scripts/columnstore-init \
     scripts/columnstore-bootstrap /bin/

# Set permissions for monit config
RUN chmod 0600 /etc/monitrc

# Make scripts executable
RUN chmod +x /bin/columnstore-bootstrap \
    /bin/columnstore-init \
    /bin/columnstore-restart

# Expose MariaDB port
EXPOSE 3306

# Create persistent volumes
VOLUME ["/etc/columnstore", "/var/lib/columnstore", "/var/lib/mysql"]

# Copy entrypoint to image
COPY scripts/docker-entrypoint.sh /usr/local/bin/

# Make entrypoint executable & create legacy symlink
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh

# Bootstrap
ENTRYPOINT ["/usr/bin/tini","--","docker-entrypoint.sh"]
CMD /bin/columnstore-bootstrap && /usr/bin/monit -I
