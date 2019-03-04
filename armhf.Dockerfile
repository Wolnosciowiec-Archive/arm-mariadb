FROM balenalib/armv7hf-debian:buster

RUN [ "cross-build-start" ]
RUN apt-get update \
    && apt-get install mariadb-server mariadb-client gosu \
    && apt-get clean

RUN set -ex; \
    { \
        echo "mariadb-server-$MARIADB_MAJOR" mysql-server/root_password password 'unused'; \
        echo "mariadb-server-$MARIADB_MAJOR" mysql-server/root_password_again password 'unused'; \
    } | debconf-set-selections; \
    backupPackage='mariadb-backup'; \
    apt-get update; \
    apt-get install -y \
        "mariadb-server" \
        $backupPackage \
        socat \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf /etc/mysql/conf.d/*; \
    rm -rf /var/lib/mysql; \
    mkdir -p /var/lib/mysql /var/run/mysqld; \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld; \
    chmod 777 /var/run/mysqld; \
    find /etc/mysql/ -name '*.cnf' -print0 \
        | xargs -0 grep -lZE '^(bind-address|log)' \
        | xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/'; \
    echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf
RUN [ "cross-build-end" ]

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
