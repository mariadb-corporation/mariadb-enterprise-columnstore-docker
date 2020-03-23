# vim:set ft=dockerfile:
FROM centos:7

# Set Default ENV Variables
ENV TINI_VERSION=v0.18.0

ARG MARIADB_ENTERPRISE_TOKEN

# Update System
RUN yum -y install epel-release && \
    yum -y upgrade

# Install Some Basic Dependencies
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

# Add Tini Init Process
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini

# Add MariaDB Enterprise Setup Script
ADD https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup /tmp

RUN chmod +x /usr/bin/tini /tmp/mariadb_es_repo_setup && \
    /tmp/mariadb_es_repo_setup --token=${MARIADB_ENTERPRISE_TOKEN} --apply

# Install MariaDB/ColumnStore packages
RUN yum -y install MariaDB-server \
    MariaDB-columnstore-platform \
    MariaDB-columnstore-engine && \
    columnstore-post-install && \
    yum clean all && \
    rm -rf /var/cache/yum

# Copy Files To Image
COPY config/rsyslog.conf \
     config/monitrc \
     config/monit.d/ /etc/

COPY config/storagemanager.cnf /etc/columnstore/storagemanager.cnf

COPY config/columnstore.cnf /etc/my.cnf.d/columnstore.cnf

COPY scripts/columnstore-restart \
     scripts/columnstore-init \
     scripts/columnstore-bootstrap /bin/

# Set Permissions
RUN chmod 0600 /etc/monitrc && \
    chmod +x /bin/columnstore-bootstrap \
    /bin/columnstore-init \
    /bin/columnstore-restart

# Work Around For https://jira.mariadb.org/browse/MCOL-3830
RUN rm -rf /etc/systemd/system/mariadb.service.d \
    /usr/lib/systemd/system/mariadb.service \
    /usr/lib/systemd/system/mariadb@.service \
    /usr/share/mysql/systemd/mariadb.service \
    /usr/share/mysql/systemd/mariadb@.service

# Expose MariaDB Port
EXPOSE 3306

# Create Persistent Volumes
VOLUME ["/etc/columnstore", "/var/lib/columnstore", "/var/lib/mysql"]

# Copy Entrypoint To Image
COPY scripts/docker-entrypoint.sh /usr/local/bin/

# Make Entrypoint Executable & Create Legacy Symlink
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh

# Bootstrap
ENTRYPOINT ["/usr/bin/tini","--","docker-entrypoint.sh"]

CMD /bin/columnstore-bootstrap && /usr/bin/monit -I
