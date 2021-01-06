# vim:set ft=dockerfile:
FROM centos:8

ARG MARIADB_ENTERPRISE_TOKEN

# Update System
RUN dnf -y install epel-release && \
    dnf -y upgrade

# Add MariaDB Enterprise Setup Script
ADD https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup /tmp

RUN chmod +x /tmp/mariadb_es_repo_setup && \
    /tmp/mariadb_es_repo_setup --mariadb-server-version=10.5 --token=${MARIADB_ENTERPRISE_TOKEN} --apply

# Install some basic dependencies
RUN dnf -y install bind-utils \
    bc \
    boost \
    expect \
    glibc-langpack-en \
    jemalloc \
    jq \
    less \
    libaio \
    MariaDB-server \
    monit \
    nano \
    net-tools \
    openssl \
    perl \
    perl-DBI \
    python3 \
    rsyslog \
    snappy \
    sudo \
    tcl \
    vim \
    wget

# Default env variables
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV TINI_VERSION=v0.18.0

# Add Tini Init Process
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini

# Install ColumnStore Engine
RUN dnf clean all && \
    rm -rf /var/cache/dnf && \
    dnf -y install MariaDB-columnstore-engine

# Copy Files To Image
COPY config/monit.d/columnstore.conf /etc/monit.d/columnstore.conf

COPY scripts/columnstore-init \
     scripts/columnstore-start \
     scripts/columnstore-stop \
     scripts/columnstore-restart /usr/bin/

# Chmod some files
RUN chmod +x /usr/bin/tini \
    /usr/bin/columnstore-init \
    /usr/bin/columnstore-start \
    /usr/bin/columnstore-stop \
    /usr/bin/columnstore-restart && \
    sed -i 's|set daemon\s.30|set daemon 5|g' /etc/monitrc && \
    sed -i 's|#.*with start delay\s.*240|  with start delay 60|g' /etc/monitrc

# Expose MariaDB Port
EXPOSE 3306

# Create Persistent Volumes
VOLUME ["/etc/columnstore", "/var/lib/columnstore", "/var/lib/mysql"]

# Copy Entrypoint To Image
COPY scripts/docker-entrypoint.sh /usr/bin/

# Make Entrypoint Executable & Create Legacy Symlink
RUN chmod +x /usr/bin/docker-entrypoint.sh && \
    ln -s /usr/bin/docker-entrypoint.sh /docker-entrypoint.sh

# Clean system and reduce size
RUN dnf clean all && \
    rm -rf /var/cache/dnf && \
    find /var/log -type f -exec cp /dev/null {} \; && \
    cat /dev/null > ~/.bash_history && \
    history -c && \
    sed -i 's|SysSock.Use="off"|SysSock.Use="on"|' /etc/rsyslog.conf && \
    sed -i 's|^.*module(load="imjournal"|#module(load="imjournal"|g' /etc/rsyslog.conf && \
    sed -i 's|^.*StateFile="imjournal.state")|#  StateFile="imjournal.state"\)|g' /etc/rsyslog.conf

# Bootstrap
ENTRYPOINT ["/usr/bin/tini","--","docker-entrypoint.sh"]
CMD columnstore-start && monit -I
