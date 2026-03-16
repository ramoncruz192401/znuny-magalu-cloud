#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root"
  exit 1
fi

required_vars=(
  DB_HOST
  DB_NAME
  DB_USER
  DB_PASS
  BUCKET_NAME
  OBJ_KEY_ID
  OBJ_KEY_SECRET
  ZNUNY_VERSION
  ZNUNY_ADMIN_USER
  ZNUNY_ADMIN_PASS
)

for v in "${required_vars[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    echo "Missing env var: ${v}"
    exit 1
  fi
done

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  apache2 libapache2-mod-perl2 \
  perl libdbi-perl libdbd-mysql-perl \
  libnet-dns-perl libnet-ldap-perl \
  libio-socket-ssl-perl libcrypt-ssleay-perl \
  libencode-hanextra-perl libjson-xs-perl \
  libmail-imapclient-perl libtemplate-perl \
  libtext-csv-xs-perl libtimedate-perl \
  libxml-libxml-perl libxml-libxslt-perl \
  default-mysql-client s3cmd wget

znuny_tgz="znuny-${ZNUNY_VERSION}.tar.gz"
znuny_url="https://download.znuny.org/releases/${znuny_tgz}"

if [[ ! -f "/tmp/${znuny_tgz}" ]]; then
  wget -q -O "/tmp/${znuny_tgz}" "${znuny_url}"
fi

tar -xzf "/tmp/${znuny_tgz}" -C /opt/
ln -sfn "/opt/znuny-${ZNUNY_VERSION}" /opt/znuny

useradd -r -d /opt/znuny -s /bin/bash -c "Znuny" znuny 2>/dev/null || true
adduser www-data znuny 2>/dev/null || true
chown -R znuny:www-data "/opt/znuny-${ZNUNY_VERSION}"
find /opt/znuny -type f -exec chmod 660 {} \;
find /opt/znuny -type d -exec chmod 770 {} \;

for _ in $(seq 1 30); do
  if mysqladmin ping -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" --silent >/dev/null 2>&1; then
    break
  fi
  sleep 10
done

mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

cp /opt/znuny/Kernel/Config.pm.dist /opt/znuny/Kernel/Config.pm
sed -i \
  -e "s|\$Self->{DatabaseHost} = .*|\$Self->{DatabaseHost} = '${DB_HOST}';|" \
  -e "s|\$Self->{Database} = .*|\$Self->{Database} = '${DB_NAME}';|" \
  -e "s|\$Self->{DatabaseUser} = .*|\$Self->{DatabaseUser} = '${DB_USER}';|" \
  -e "s|\$Self->{DatabasePw} = .*|\$Self->{DatabasePw} = '${DB_PASS}';|" \
  /opt/znuny/Kernel/Config.pm

su -s /bin/bash znuny -c "cd /opt/znuny && perl bin/otrs.Console.pl Maint::Database::Install"
su -s /bin/bash znuny -c "cd /opt/znuny && perl bin/otrs.Console.pl Admin::User::SetPassword ${ZNUNY_ADMIN_USER} ${ZNUNY_ADMIN_PASS}"

cat >/etc/apache2/sites-available/znuny.conf <<'APACHE'
<VirtualHost *:80>
    DocumentRoot /opt/znuny/var/httpd/htdocs
    ScriptAlias /znuny/ /opt/znuny/bin/cgi-bin/
    <Directory /opt/znuny/bin/cgi-bin/>
        Options +ExecCGI
        AllowOverride All
        Require all granted
    </Directory>
    <Directory /opt/znuny/var/httpd/htdocs/>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/znuny_error.log
    CustomLog ${APACHE_LOG_DIR}/znuny_access.log combined
</VirtualHost>
APACHE

a2enmod cgi rewrite
a2ensite znuny.conf
a2dissite 000-default.conf || true
systemctl restart apache2

cat >/etc/s3cmd.cfg <<S3CFG
[default]
access_key = ${OBJ_KEY_ID}
secret_key = ${OBJ_KEY_SECRET}
host_base = br-se1.magaluobjects.com
host_bucket = %(bucket)s.br-se1.magaluobjects.com
use_https = True
S3CFG
chmod 600 /etc/s3cmd.cfg

cat >/usr/local/bin/znuny_backup_to_s3.sh <<'BACKUP'
#!/usr/bin/env bash
set -euo pipefail
s3cmd -c /etc/s3cmd.cfg sync /opt/znuny/var/ "s3://${BUCKET_NAME}/var/"
BACKUP
chmod +x /usr/local/bin/znuny_backup_to_s3.sh

cat >/etc/cron.d/znuny-backup <<'CRON'
0 2 * * * root BUCKET_NAME_PLACEHOLDER=1 /usr/local/bin/znuny_backup_to_s3.sh
CRON
sed -i "s|BUCKET_NAME_PLACEHOLDER=1|BUCKET_NAME=${BUCKET_NAME}|" /etc/cron.d/znuny-backup

echo "Znuny installation complete"
