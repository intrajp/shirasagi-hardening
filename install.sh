# install.sh -- install script of shirasagi-hardening
#
# Copyright(C) Shintaro Fujiwara

#### including global variables and functions

#. .config 
#. functions

##################### .config ###################

#### prog_name
PROG_NAME="shirasagi-hardening" 

#### OS 
OS_VERSION="CentOS Linux release 7.3.1611 (Core)"

#### vars

THIS_USER=""
SELINUX=""

SS_HOSTNAME=${1:-"example.jp"}
SS_USER=${2:-"$USER"}
SS_DIR="/var/www/${PROG_NAME}"

#### ports

PORT_COMPA=8001
PORT_CHILD=8002
PORT_OPEND=8003

#### logfile

NOW=`date +%Y%m%d%H%M%S`
LOGFILE="${PROG_NAME}_install-log_${NOW}.log"

#### check rpms which is not instlled on the box

RPMS_TO_BE_INSTALLED=()
PACKAGES=("policycoreutils-python" "mongodb-org" "nginx" "gcc" "gcc-c++" "glibc-headers" "openssl-devel" "readline" "libyaml-devel" "readline-devel" "zlib" "zlib-devel" "wget" "git" "ImageMagick" "ImageMagick-devel")

##################### end .config ###################

##################### functions ###################

# creates log file in /root and logs what the script do 

mklog()
{
    sync >/dev/null 2>&1
    exec > >(tee $LOGFILE) 2>&1
}

# error message 

err_msg()
{
    echo "Oops! Something went wrong!"
    exit 1
}

# echo installer 

echo_installer()
{
    echo "########"
    echo "This is ${PROG_NAME} installer"
    echo ""
    echo "########"
}

# echo installer finished 

echo_installer_finished()
{
    echo "########"
    echo "${PROG_NAME} installer finished"
    echo "check install log file $LOGFILE for detail"
    echo "########"
}

# check user is root 

check_root()
{
    local result=""
    if [ ${EUID:-${UID}} = 0 ]; then
        result="root"
    else
        result="nonroot" 
    fi
    echo "${result}"
}

# check OS version

check_OS_version()
{
    if [ -e "/etc/centos-release" ]; then
        ## just use xargs for trimming 
        os_version=$(cat /etc/centos-release | xargs)
        if [ "${os_version}" = "${OS_VERSION}" ]; then
            echo "OS version is ${os_version}"
        else
            echo "Only on ${OS_VERSION} could be installed"
            err_msg
        fi
    else
        echo "Only on ${OS_VERSION} could be installed"
        err_msg
    fi
}

# check SELinux is enabled 

check_SELinux_is_enabled()
{
    local result=""
    result=$(getenforce)
    echo "${result}"
}

# check rpms to be installed

check_rpms()
{
    local num=1
    RPMS_TO_BE_INSTALLED=()
    while [ $num -le $# ]; do
        local rpm_lacked=""
        local rpm_name=""
        rpm_name=$(eval echo "\$$num")
        #echo $rpm_name
        `rpm -q "${rpm_name}" >/dev/null`
        if [ $? -ne 0 ]; then
            rpm_lacked=$(echo "$rpm_name")
            RPMS_TO_BE_INSTALLED=("${RPMS_TO_BE_INSTALLED[@]}" "${rpm_lacked}")
        fi
        shift
    done
    echo "${RPMS_TO_BE_INSTALLED[@]}"
}

# check function succeeded 

check_function_succeeded()
{
    if [ $? -eq 0 ]; then
        echo "success"
    else
        err_msg
    fi
}

##################### end functions ###################

#### echo installer 
echo_installer

#### check OS version and if not ok, exit
check_OS_version

#### make log file and logs in root directory

mklog

#### check if SELinux is Enforcing, else exit 

SELINUX=$(check_SELinux_is_enabled)
if [ $? -eq 0 ]; then
    if [ "${SELINUX}" = "Enforcing" ]; then
        echo "SELinux is $SELINUX"
    else
        echo "Please set SELinux to Enforcing"
        err_msg
    fi
else
    err_msg
fi

#### check if user is root, else exit 

THIS_USER=$(check_root)
if [ $? -eq 0 ]; then
    if [ "${THIS_USER}" = "root" ]; then
        echo "This user is root"
    else
        echo "Only root can exec this program"
        err_msg
    fi
else
    err_msg
fi

#### repo file for mongodb

cat > /etc/yum.repos.d/mongodb-org-3.4.repo << "EOF"
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOF

#### repo file for Nginx

cat > /etc/yum.repos.d/nginx.repo << "EOF"
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
EOF

#### installing packages which is not installed on the box

yum -y install $(check_rpms "${PACKAGES[@]}")
	
#### getting gpg key

for i in $(seq 1 3)
do
  curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 5s
done

#### setting something, dont konw what it is 

\curl -sSL https://get.rvm.io | bash -s stable
RVM_HOME=/usr/local/rvm

#### installing rvm

export PATH="$PATH:$RVM_HOME/bin"
source $RVM_HOME/scripts/rvm
rvm install 2.3.4
rvm use 2.3.4 --default
gem install bundler

#### cloning shirasagi-hardening and coping files to dir

git clone --depth 1 https://github.com/intrajp/${PROG_NAME}
mkdir -p /var/www
mv ${PROG_NAME} ${SS_DIR}

#### coping ruby stuff

cd $SS_DIR
cp -n config/samples/*.{rb,yml} config/
for i in $(seq 1 5)
do
  bundle install --without development test --path vendor/bundle
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 5s
done

#### change secret

sed -i "s/dbcae379.*$/`bundle exec rake secret`/" config/secrets.yml

#### enable recommendation

sed -e "s/disable: true$/disable: false/" config/defaults/recommend.yml > config/recommend.yml

#### setting nginx

cat > /etc/nginx/conf.d/http.conf << "EOF"
server_tokens off;
server_name_in_redirect off;
etag off;
client_max_body_size 100m;
client_body_buffer_size 256k;

gzip on;
gzip_http_version 1.0;
gzip_comp_level 1;
gzip_proxied any;
gzip_vary on;
gzip_buffers 4 8k;
gzip_min_length 1000;
gzip_types text/plain
           text/xml
           text/css
           text/javascript
           application/xml
           application/xhtml+xml
           application/rss+xml
           application/atom_xml
           application/javascript
           application/x-javascript
           application/x-httpd-php;
gzip_disable "MSIE [1-6]\\.";
gzip_disable "Mozilla/4";

proxy_headers_hash_bucket_size 128;
proxy_headers_hash_max_size 1024;
proxy_cache_path /var/cache/nginx/proxy_cache levels=1:2 keys_zone=my-key:8m max_size=50m inactive=120m;
proxy_temp_path /var/cache/nginx/proxy_temp;
proxy_buffers 8 64k;
proxy_buffer_size 64k;
proxy_max_temp_file_size 0;
proxy_connect_timeout 30;
proxy_read_timeout 120;
proxy_send_timeout 10;
proxy_cache_use_stale timeout invalid_header http_500 http_502 http_503 http_504;
proxy_cache_lock on;
proxy_cache_lock_timeout 5s;
EOF

cat > /etc/nginx/conf.d/header.conf << "EOF"
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header Remote-Addr \$remote_addr;
proxy_set_header X-Forwarded-Host \$http_host;
proxy_set_header X-Forwarded-Server \$host;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header Accept-Encoding "";
proxy_set_header X-Sendfile-Type X-Accel-Redirect;
proxy_hide_header X-Pingback;
proxy_hide_header Link;
proxy_hide_header ETag;
EOF

mkdir /etc/nginx/conf.d/{common,server}

cat > /etc/nginx/conf.d/common/drop.conf << "EOF"
location = /favicon.ico                      { expires 1h; access_log off; log_not_found off; }
location = /robots.txt                       { expires 1h; access_log off; log_not_found off; }
location = /apple-touch-icon.png             { expires 1h; access_log off; log_not_found off; }
location = /apple-touch-icon-precomposed.png { expires 1h; access_log off; log_not_found off; }
EOF

cat > /etc/nginx/conf.d/virtual.conf << "EOF"
server {
    include conf.d/server/shirasagi.conf;
    server_name example.jp;
    root /var/www/shirasagi-hardening/public/sites/w/w/w/_/;
}
server {
    listen  8001;
    include conf.d/server/shirasagi.conf;
    server_name example.jp:8001;
    root /var/www/shirasagi-hardening/public/sites/c/o/m/p/a/n/y/_/;
}
server {
    listen  8002;
    include conf.d/server/shirasagi.conf;
    server_name example.jp:8002;
    root /var/www/shirasagi-hardening/public/sites/c/h/i/l/d/c/a/r/e/_/;
}
server {
    listen  8003;
    include conf.d/server/shirasagi.conf;
    server_name example.jp:8003;
    root /var/www/shirasagi-hardening/public/sites/o/p/e/n/d/a/t/a/_/;
}
EOF

cat > /etc/nginx/conf.d/server/shirasagi.conf << "EOF"
include conf.d/common/drop.conf;

location @app {
    include conf.d/header.conf;
    if ($request_filename ~ .*\\.(ico|gif|jpe?g|png|css|js)$) { access_log off; }
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header X-Accel-Mapping /var/www/shirasagi-hardening/=/private_files/;
}
location / {
    try_files $uri $uri/index.html @app;
}
location /assets/ {
    root /var/www/shirasagi-hardening/public/;
    expires 1h;
    access_log off;
}
location /private_files/ {
    internal;
    alias /var/www/shirasagi-hardening/;
}
EOF

#### daemonize

cat > /etc/systemd/system/shirasagi-unicorn.service << "EOF"
[Unit]
Description=Shirasagi Unicorn Server
After=mongod.service

[Service]
User=root
WorkingDirectory=/var/www/shirasagi-hardening
ExecStart=/usr/local/rvm/wrappers/default/bundle exec rake unicorn:start
ExecStop=/usr/local/rvm/wrappers/default/bundle exec rake unicorn:stop
ExecReload=/usr/local/rvm/wrappers/default/bundle exec rake unicorn:restart
Type=forking
PIDFile=/var/www/shirasagi-hardening/tmp/pids/unicorn.pid

[Install]
WantedBy=multi-user.target
EOF

chown root: /etc/systemd/system/shirasagi-unicorn.service
chmod 644 /etc/systemd/system/shirasagi-unicorn.service

#### start mongod and enable it 

systemctl start mongod.service
check_function_succeeded
systemctl enable mongod.service
check_function_succeeded

#### SELinux needs to httpd_t 
#Allow /usr/sbin/httpd to bind to network port <PORT> 
#Modify the port type.
#where PORT_TYPE is one of the following: ntop_port_t, http_cache_port_t, http_port_t.
#here we go
#set each port if aready set,modify it

for i in $(seq 1 3)
do
    if [ ${i} -eq 1 ]; then
        p_="${PORT_COMPA}"
    elif [ ${i} -eq 2 ]; then
        p_="${PORT_CHILD}"
    elif [ ${i} -eq 3 ]; then
        p_="${PORT_OPEND}"
fi
    semanage port -a -t http_port_t -p tcp "$p_" 
    if [ $? -ne 0 ]; then
        semanage port -m -t http_port_t -p tcp "$p_" 
        if [ $? -ne 0 ]; then
            echo "semanage -m -t http_port_t -p tcp $p_ failed"
            err_msg
        else
            echo "semanage -m -t http_port_t -p tcp $p_ succeeded"
        fi
    else
        echo "semanage -a -t http_port_t -p tcp $p_ succeeded"
    fi
done

#### enable nginx 

systemctl enable nginx.service
check_function_succeeded

#### enable shirasagi-unicorn 

systemctl enable shirasagi-unicorn.service
check_function_succeeded

#### taking changed configurations from filesystem and regenerationg dependency trees 

systemctl daemon-reload
check_function_succeeded

#### start nginx

systemctl start nginx.service
check_function_succeeded

cd $SS_DIR
bundle exec rake db:drop
check_function_succeeded
bundle exec rake db:create_indexes
check_function_succeeded
bundle exec rake ss:create_site data="{ name: \"自治体サンプル\", host: \"www\", domains: \"${SS_HOSTNAME}\" }"
check_function_succeeded
bundle exec rake ss:create_site data="{ name: \"企業サンプル\", host: \"company\", domains: \"${SS_HOSTNAME}:${PORT_COMPA}\" }"
check_function_succeeded
bundle exec rake ss:create_site data="{ name: \"子育て支援サンプル\", host: \"childcare\", domains: \"${SS_HOSTNAME}:${PORT_CHILD}\" }"
check_function_succeeded
bundle exec rake ss:create_site data="{ name: \"オープンデータサンプル\", host: \"opendata\", domains: \"${SS_HOSTNAME}:${PORT_OPEND}\" }"
check_function_succeeded
bundle exec rake db:seed name=demo site=www
check_function_succeeded
bundle exec rake db:seed name=company site=company
check_function_succeeded
bundle exec rake db:seed name=childcare site=childcare
check_function_succeeded
bundle exec rake db:seed name=opendata site=opendata
check_function_succeeded
bundle exec rake db:seed name=gws
check_function_succeeded
bundle exec rake db:seed name=webmail
check_function_succeeded

#### start shirasagi-unicorn

systemctl start shirasagi-unicorn.service
check_function_succeeded

# use openlayers as default map
echo 'db.ss_sites.update({}, { $set: { map_api: "openlayers" } }, { multi: true });' | mongo ss > /dev/null

bundle exec rake cms:generate_nodes
check_function_succeeded
bundle exec rake cms:generate_pages
check_function_succeeded

cat >> crontab << "EOF"
*/15 * * * * /bin/bash -l -c 'cd /var/www/shirasagi-hardening && /usr/local/rvm/wrappers/default/bundle exec rake cms:release_pages && /usr/local/rvm/wrappers/default/bundle exec rake cms:generate_nodes' >/dev/null
0 * * * * /bin/bash -l -c 'cd /var/www/shirasagi-hardening && /usr/local/rvm/wrappers/default/bundle exec rake cms:generate_pages' >/dev/null
EOF

# modify ImageMagick policy to work with simple captcha
# see: https://github.com/diaspora/diaspora/issues/6828
cd /etc/ImageMagick && cat << EOF | patch
--- policy.xml.orig     2016-12-08 13:50:47.344009000 +0900
+++ policy.xml  2016-12-08 13:15:22.529009000 +0900
@@ -67,6 +67,8 @@
   <policy domain="coder" rights="none" pattern="MVG" />
   <policy domain="coder" rights="none" pattern="MSL" />
   <policy domain="coder" rights="none" pattern="TEXT" />
-  <policy domain="coder" rights="none" pattern="LABEL" />
+  <!-- <policy domain="coder" rights="none" pattern="LABEL" /> -->
   <policy domain="path" rights="none" pattern="@*" />
+  <policy domain="coder" rights="read | write" pattern="JPEG" />
+  <policy domain="coder" rights="read | write" pattern="PNG" />
 </policymap>
EOF

#### restarting services
systemctl restart nginx.service
check_function_succeeded
systemctl restart mongod.service
check_function_succeeded
systemctl restart shirasagi-unicorn.service
check_function_succeeded

#### firewalld stuff

firewall-cmd --add-port=http/tcp --permanent
check_function_succeeded
firewall-cmd --add-port=${PORT_COMPA}/tcp --permanent
check_function_succeeded
firewall-cmd --add-port=${PORT_CHILD}/tcp --permanent
check_function_succeeded
firewall-cmd --add-port=${PORT_OPEND}/tcp --permanent
check_function_succeeded
firewall-cmd --reload
check_function_succeeded

#### echo installer finished
echo_installer_finished