# install.sh -- install script of shirasagi
#
# The MIT License (MIT)
#
# Copyright (c) 2014 SHIRASAGI Project
# Copyright (C) 2017 Shintaro Fujiwara
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#### including global variables and functions (in case this script split into pieces)

#. .config 
#. functions

##################### .config ###################

#### program name

PROG_NAME="shirasagi" 

#### OS 
## TODO:read version which could be allowed to propagate this program 

OS_VERSION="CentOS Linux release 7.3.1611 (Core)"

#### vars

THIS_USER=""
SELINUX=""

## hostname and user will be ask and set later, so...

#SS_HOSTNAME=${1:-"example.jp"}
#SS_USER=${2:-"$USER"}
SS_DIR="/var/www/${PROG_NAME}"

#### ports

PORT_UNICORN=3000
PORT_COMPA=8001
PORT_CHILD=8002
PORT_OPEND=8003
SELINUX_PORT_TYPE="http_port_t"

#### script directory 

SCRIPT_DIR="/tmp"

#### log directory 

LOG_DIR="/var/log"

#### logfile

NOW=`date +%Y%m%d%H%M%S`
LOGFILE="${LOG_DIR}/${PROG_NAME}-install_${NOW}.log"

#### list of packages which should be present on the box

RPMS_TO_BE_INSTALLED=()
PACKAGES=("policycoreutils-python" "mongodb-org" "nginx" "gcc" "gcc-c++" "glibc-headers" "openssl-devel" "readline" "libyaml-devel" "readline-devel" "zlib" "zlib-devel" "wget" "git" "ImageMagick" "ImageMagick-devel" "firefox")

##################### end .config ###################

##################### functions ###################

# creates log file in script directory and logs what the script does 

mklog()
{
    sync >/dev/null 2>&1
    exec > >(tee $LOGFILE) 2>&1
}

# error message 

err_msg()
{
    echo "Oops! Something went wrong!"
    echo "Check log file in ${LOGFILE} for detail"
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

echo_installer_has_finished()
{
    echo "########"
    echo "${PROG_NAME} installer has finished"
    echo "check install log file ${LOGFILE} for detail"
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
    if [ `echo "${#RPMS_TO_BE_INSTALLED[@]}"` = 0 ]; then
        echo "All needed packages are installed on this box. Proceeding..."
        sleep 5
    else
        #echo "${RPMS_TO_BE_INSTALLED[@]}"
        yum -y install "${RPMS_TO_BE_INSTALLED[@]}"
    fi
}

# check if shirasagi directory exists 

check_shirasagi_dir_exists()
{
    if [ -d "${SS_DIR}" ]; then
        echo "${SS_DIR} exists."
        while :
        do
            echo "${SS_DIR} should be deleted for installing shirasagi anew."
            echo "Don't worry, ${SS_DIR} will be made in the installation process."
            echo ""
            echo -n "Do you delete ${SS_DIR} ? :[y/N]"
            read ans
            case $ans in
            [yY])
                break;;
            [nN])
                echo "Thank you using $0"
                exit 0;;
            *)
                echo "Type y or n"
            esac
        done
        `rm -rf "${SS_DIR}"` 
        if [ $? -ne 0 ]; then
            echo "Deleting ${SS_DIR} failed"
            err_msg
        else
            echo "Deleted directory ${SS_DIR}."
            echo "${SS_DIR} will be made in the installation process."
            echo ""
        fi
    else
        echo "${SS_DIR} does not exist."
        echo "${SS_DIR} will be made in the installation process."
        echo ""
    fi
}

# check function succeeded 

check_command_succeeded()
{
    local comm
    comm=$1
    ## exec the command
    $(${comm})
    if [ $? -eq 0 ]; then
        echo "'$comm' succeeded"
    else
        echo "'$comm' failed"
        err_msg
    fi
}

# check function succeeded (for runuser)

check_command_runuser()
{
    if [ $? -ne 0 ]; then
        echo "runuser command failed"
        err_msg
    else
        echo "runuser command succeeded"
        sleep 5
    fi
}

# check function succeeded (pattern 2, not used)

try_command_multiple_times()
{
    local comm
    comm=$1
    ## exec the command
    $(${comm})
    if [ $? -eq 0 ]; then
        echo "'$comm' succeeded"
    else
        echo "'$comm' failed"
        check_command_succeeded $comm
    fi
}

# clean the BUILD directory (not used) 

clean_build_dir()
{
    local comm
    comm=$1
    if [ $? -eq 0 ]; then
        echo "'$comm' succeeded"
    else
        echo "'$comm' failed"
        err_msg
    fi
}

# ask domain name

ask_domain_name()
{
    local ans=""
    SS_HOSTNAME="example.jp"
    echo -n "Set domain name [example.jp]:"
    read ans
    ## just trim white space
    echo ${ans} | xargs >/dev/null
    if [ ! "${ans}" ]; then
        SS_HOSTNAME=${SS_HOSTNAME}
    else
        SS_HOSTNAME=${ans}
    fi
}

#SELinux should be allowed /usr/sbin/httpd to bind to network port <PORT> 
#set each port and if aready set, modify it

semanage_selinux_port()
{
    local port_num=$2
    local selinux_port_type=$1
    semanage port -a -t ${selinux_port_type} -p tcp "${port_num}" 
    if [ $? -ne 0 ]; then
        semanage port -m -t ${selinux_port_type} -p tcp "${port_num}" 
        if [ $? -ne 0 ]; then
            echo "'semanage -m -t ${selinux_port_type} -p tcp ${port_num}' failed"
            err_msg
        else
            echo "'semanage -m -t ${selinux_port_type} -p tcp ${port_num}' succeeded"
        fi
    else
        echo "'semanage -a -t ${selinux_port_type} -p tcp ${port_num}' succeeded"
    fi
}

# set commands for using command check function will use them easily

SYSTEMCTL_START_MONGOD="systemctl start mongod.service"
SYSTEMCTL_ENABLE_MONGOD="systemctl enable mongod.service"
SYSTEMCTL_ENABLE_NGINX="systemctl enable nginx.service"
SYSTEMCTL_ENABLE_SHIRASAGI_UNICORN="systemctl enable shirasagi-unicorn.service"
SYSTEMCTL_DAEMON_RELOAD="systemctl daemon-reload"
SYSTEMCTL_START_NGINX="systemctl start nginx.service"
SYSTEMCTL_START_SHIRASAGI_UNICORN="systemctl start shirasagi-unicorn.service"
SYSTEMCTL_RESTART_NGINX="systemctl restart nginx.service"
SYSTEMCTL_RESTART_MONGOD="systemctl restart mongod.service"
SYSTEMCTL_RESTART_SHIRASAGI_UNICORN="systemctl restart shirasagi-unicorn.service"
FIREWALL_CMD_ADD_PORT_HTTP_TCP="firewall-cmd --add-port=http/tcp --permanent"
FIREWALL_CMD_ADD_PORT_PORT_UNICORN="firewall-cmd --add-port=${PORT_UNICORN}/tcp --permanent"
FIREWALL_CMD_ADD_PORT_PORT_COMPA="firewall-cmd --add-port=${PORT_COMPA}/tcp --permanent"
FIREWALL_CMD_ADD_PORT_PORT_CHILD="firewall-cmd --add-port=${PORT_CHILD}/tcp --permanent"
FIREWALL_CMD_ADD_PORT_PORT_OPEND="firewall-cmd --add-port=${PORT_OPEND}/tcp --permanent"
FIREWALL_CMD_RELOAD="firewall-cmd --reload"

##################### end functions ###################

##################### main part ###################

#### Dive into the directory which is only convenient  

pushd "${SCRIPT_DIR}"

#### make log file and logs in root directory

mklog

#### echo installer 

echo_installer

#### check OS version and if not ok, exit

check_OS_version

#### check if SELinux is Enforcing, else exit 
## TODO:it might be not a bad idea allowing systems without SELinux after asking admin

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

#### Add user shirasagi and lock password 

id -u shirasagi >/dev/null
if [ $? -ne 0 ]; then
    useradd shirasagi >/dev/null
    if [ $? -ne 0 ]; then
        echo "useradd shirasagi failed"
        err_msg
    else
        echo "Added user shirasagi and locked password"
    fi
else
    echo "user shirasagi exists."
fi

#### check_shirasagi directory exists

check_shirasagi_dir_exists

#### ask domain name

while :
do
    ask_domain_name
    echo -n "Are you sure setting domain name to '${SS_HOSTNAME}' ? :[y/N]"
    read ans
    case $ans in
    [yY])
        break;;
    [nN])
        echo ""
        ;;
    *)
        echo "Type y or n"
    esac
done

echo "Domain name will be set to '${SS_HOSTNAME}'"

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

#### installing packages which should be present on the box

check_rpms "${PACKAGES[@]}"

#### check all needed packages are present, else exit

for i in ${PACKAGES[@]}
do
    rpm -q ${i} >/dev/null
    if [ $? -ne 0 ]; then
        echo "${i}" is not installed
        err_msg
    fi
done
echo "######## All needed packages are install on this box ########"

#### start mongod and enable it 

check_command_succeeded "${SYSTEMCTL_START_MONGOD}"
check_command_succeeded "${SYSTEMCTL_ENABLE_MONGOD}"

#### enable nginx

echo "######## Enable nginx ########"

check_command_succeeded "${SYSTEMCTL_ENABLE_NGINX}"

#### SELinux port managing 

echo "######## SELinux port managing ########"

semanage_selinux_port "${SELINUX_PORT_TYPE}" "${PORT_UNICORN}"
semanage_selinux_port "${SELINUX_PORT_TYPE}" "${PORT_COMPA}"
semanage_selinux_port "${SELINUX_PORT_TYPE}" "${PORT_CHILD}"
semanage_selinux_port "${SELINUX_PORT_TYPE}" "${PORT_OPEND}"

#### start nginx

echo "######## Start nginx ########"

check_command_succeeded "${SYSTEMCTL_START_NGINX}"

#### getting gpg key

for i in $(seq 1 3)
do
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 5s
done

#### setting something, dont konw what it is (is this ruby ?)

\curl -sSL https://get.rvm.io | bash -s stable

RVM_HOME=/usr/local/rvm

#### installing rvm

export PATH=\"$PATH:$RVM_HOME/bin\"
source $RVM_HOME/scripts/rvm
rvm install 2.3.4
rvm use 2.3.4 --default
gem install bundler

#### cloning shirasagi and coping files to dir

runuser -l shirasagi -c "git clone -b stable --depth 1 https://github.com/shirasagi/${PROG_NAME}"
check_command_runuser
mkdir -p /var/www
mv /home/shirasagi/${PROG_NAME} ${SS_DIR}

echo ""
echo "#### Now, restoring context under /var/www, because when certain directory had been moved, SELinux label would not be 'should be state'."
echo ""
sleep 10

restorecon -Rv /var/www

echo ""
echo "#### Check above relabeling results after all the sequence is done"
echo ""
sleep 10

#### coping ruby stuff

cd $SS_DIR
cp -n config/samples/*.{rb,yml} config/
for i in $(seq 1 5)
do
    runuser -l shirasagi -c "${SS_DIR}/bin/bundle install --without development test --path vendor/bundle"
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 5s
done

echo "######## Installing bundle finished ########"

#### change secret

sed -i "s/dbcae379.*$/`bundle exec rake secret`/" config/secrets.yml

#### enable recommendation

sed -e "s/disable: true$/disable: false/" config/defaults/recommend.yml > config/recommend.yml

#### Furigana

echo "######## Furigana stuff ########"

runuser -l shirasagi -c 'wget --no-check-certificate -O mecab-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"'
check_command_runuser
runuser -l shirasagi -c 'wget --no-check-certificate -O mecab-ipadic-2.7.0-20070801.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"'
check_command_runuser
runuser -l shirasagi -c 'wget --no-check-certificate -O mecab-ruby-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7VUNlczBWVDZJbE0"'
check_command_runuser
runuser -l shirasagi -c 'wget https://raw.githubusercontent.com/shirasagi/shirasagi/stable/vendor/mecab/mecab-ipadic-2.7.0-20070801.patch'
check_command_runuser

echo "######## mecab ########"

runuser -l shirasagi -c "tar xvzf mecab-0.996.tar.gz"
check_command_runuser
runuser -l shirasagi -c "cd mecab-0.996;./configure --enable-utf8-only"
check_command_runuser
runuser -l shirasagi -c "cd mecab-0.996;make"
check_command_runuser
pushd /home/shirasagi/mecab-0.996
    pwd
    make install
popd

echo "######## mecab-ipadic-2.7.0-20070801 ########"

runuser -l shirasagi -c "tar xvzf mecab-ipadic-2.7.0-20070801.tar.gz"
check_command_runuser
runuser -l shirasagi -c "cd mecab-ipadic-2.7.0-20070801;patch -p1 < ../mecab-ipadic-2.7.0-20070801.patch;./configure --with-charset=UTF-8;make"
check_command_runuser
pushd /home/shirasagi/mecab-ipadic-2.7.0-20070801
    pwd
    make install
popd

echo "######## mecab-ruby ########"

runuser -l shirasagi -c "tar xvzf mecab-ruby-0.996.tar.gz"
check_command_runuser
runuser -l shirasagi -c "cd mecab-ruby-0.996;ruby extconf.rb;make"
check_command_runuser
pushd /home/shirasagi/mecab-ruby-0.996
    pwd
    make install
popd

echo "######## ldconfig ########"

cat >> /etc/ld.so.conf << "EOF"
/usr/local/lib
EOF

ldconfig

#### Voice

echo "######## Voice stuff ########"

runuser -l shirasagi -c "wget http://downloads.sourceforge.net/hts-engine/hts_engine_API-1.08.tar.gz \
    http://downloads.sourceforge.net/open-jtalk/open_jtalk-1.07.tar.gz \
    http://downloads.sourceforge.net/lame/lame-3.99.5.tar.gz \
    http://downloads.sourceforge.net/sox/sox-14.4.1.tar.gz"
check_command_runuser

echo "######## hts_engine_API-1.08 ########"

runuser -l shirasagi -c "tar xvzf hts_engine_API-1.08.tar.gz"
check_command_runuser
runuser -l shirasagi -c "cd hts_engine_API-1.08;./configure;make"
check_command_runuser
pushd /home/shirasagi/hts_engine_API-1.08
    make install
popd

echo "######## open_jtalk-1.07 ########"

runuser -l shirasagi -c "tar xvzf open_jtalk-1.07.tar.gz"
check_command_runuser
runuser -l shirasagi -c "sed -i \"s/#define MAXBUFLEN 1024/#define MAXBUFLEN 10240/\" open_jtalk-1.07/bin/open_jtalk.c"
check_command_runuser
runuser -l shirasagi -c "sed -i \"s/0x00D0 SPACE/0x000D SPACE/\" open_jtalk-1.07/mecab-naist-jdic/char.def"
check_command_runuser
runuser -l shirasagi -c "cd open_jtalk-1.07;./configure;make"
check_command_runuser
pushd /home/shirasagi/open_jtalk-1.07
    make install
popd

echo "######## lame-3.99.5 ########"

runuser -l shirasagi -c "tar xvzf lame-3.99.5.tar.gz"
check_command_runuser
runuser -l shirasagi -c "cd lame-3.99.5;./configure;make"
check_command_runuser
pushd /home/shirasagi/lame-3.99.5
    make install
popd

echo "######## sox-14.4.1 ########"

runuser -l shirasagi -c "tar xvzf sox-14.4.1.tar.gz"
check_command_runuser
runuser -l shirasagi -c "cd sox-14.4.1;./configure;make"
check_command_runuser
pushd /home/shirasagi/sox-14.4.1
    make install
popd

echo "######## ldconfig ########"

ldconfig

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
gzip_disable "MSIE [1-6].";
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
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header Remote-Addr $remote_addr;
proxy_set_header X-Forwarded-Host $http_host;
proxy_set_header X-Forwarded-Server $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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

cat > /etc/nginx/conf.d/virtual.conf <<EOF
server {
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME};
    root ${SS_DIR}/public/sites/w/w/w/_/;
}
server {
    listen  8001;
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME}:8001;
    root ${SS_DIR}/public/sites/c/o/m/p/a/n/y/_/;
}
server {
    listen  8002;
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME}:8002;
    root ${SS_DIR}/public/sites/c/h/i/l/d/c/a/r/e/_/;
}
server {
    listen  8003;
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME}:8003;
    root ${SS_DIR}/public/sites/o/p/e/n/d/a/t/a/_/;
}
EOF

cat > /etc/nginx/conf.d/server/shirasagi.conf <<EOF
include conf.d/common/drop.conf;

location @app {
    include conf.d/header.conf;
    if (\$request_filename ~ .*.(ico|gif|jpe?g|png|css|js)$) { access_log off; }
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header X-Accel-Mapping ${SS_DIR}/=/private_files/;
}
location / {
    try_files \$uri \$uri/index.html @app;
}
location /assets/ {
    root ${SS_DIR}/public/;
    expires 1h;
    access_log off;
}
location /private_files/ {
    internal;
    alias ${SS_DIR}/;
}
EOF

#### daemonize

cat > /etc/systemd/system/shirasagi-unicorn.service <<EOF
[Unit]
Description=Shirasagi Unicorn Server
After=mongod.service

[Service]
User=root
WorkingDirectory=${SS_DIR}
ExecStart=/usr/local/rvm/wrappers/default/bundle exec rake unicorn:start
ExecStop=/usr/local/rvm/wrappers/default/bundle exec rake unicorn:stop
ExecReload=/usr/local/rvm/wrappers/default/bundle exec rake unicorn:restart
Type=forking
PIDFile=${SS_DIR}/tmp/pids/unicorn.pid

[Install]
WantedBy=multi-user.target
EOF

chown root: /etc/systemd/system/shirasagi-unicorn.service
chmod 644 /etc/systemd/system/shirasagi-unicorn.service

#### enable shirasagi-unicorn 

check_command_succeeded "${SYSTEMCTL_ENABLE_SHIRASAGI_UNICORN}"

#### taking changed configurations from filesystem and regenerationg dependency trees 

check_command_succeeded "${SYSTEMCTL_DAEMON_RELOAD}"

runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:drop"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:create_indexes"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"自治体サンプル\", host: \"www\", domains: \"${SS_HOSTNAME}\" }'"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"企業サンプル\", host: \"company\", domains: \"${SS_HOSTNAME}:${PORT_COMPA}\" }'"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"子育て支援サンプル\", host: \"childcare\", domains: \"${SS_HOSTNAME}:${PORT_CHILD}\" }'"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"オープンデータサンプル\", host: \"opendata\", domains: \"${SS_HOSTNAME}:${PORT_OPEND}\" }'"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:seed name=demo site=www"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:seed name=company site=company"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:seed name=childcare site=childcare"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:seed name=opendata site=opendata"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:seed name=gws"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake db:seed name=webmail"
check_command_runuser

#### start shirasagi-unicorn

check_command_succeeded "${SYSTEMCTL_START_SHIRASAGI_UNICORN}"

# use openlayers as default map
echo 'db.ss_sites.update({}, { $set: { map_api: "openlayers" } }, { multi: true });' | mongo ss > /dev/null

runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake cms:generate_nodes"
check_command_runuser
runuser -l shirasagi -c "cd ${SS_DIR};./bin/bundle exec ./bin/rake cms:generate_pages"
check_command_runuser

cat >> crontab << "EOF"
*/15 * * * * /bin/bash -l -c 'cd /var/www/shirasagi && /usr/local/rvm/wrappers/default/bundle exec rake cms:release_pages && /usr/local/rvm/wrappers/default/bundle exec rake cms:generate_nodes' >/dev/null
0 * * * * /bin/bash -l -c 'cd /var/www/shirasagi && /usr/local/rvm/wrappers/default/bundle exec rake cms:generate_pages' >/dev/null
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

check_command_succeeded "${SYSTEMCTL_RESTART_NGINX}"
check_command_succeeded "${SYSTEMCTL_RESTART_MONGOD}"
check_command_succeeded "${SYSTEMCTL_RESTART_SHIRASAGI_UNICORN}"

#### firewalld stuff

echo "${FIREWALL_CMD_ADD_PORT_HTTP_TCP}"
firewall-cmd --add-port=http/tcp --permanent
echo "${FIREWALL_CMD_ADD_PORT_PORT_UNICORN}"
firewall-cmd --add-port=${PORT_UNICORN}/tcp --permanent
echo "${FIREWALL_CMD_ADD_PORT_PORT_COMPA}"
firewall-cmd --add-port=${PORT_COMPA}/tcp --permanent
echo "${FIREWALL_CMD_ADD_PORT_PORT_CHILD}"
firewall-cmd --add-port=${PORT_CHILD}/tcp --permanent
echo "${FIREWALL_CMD_ADD_PORT_PORT_OPEND}"
firewall-cmd --add-port=${PORT_OPEND}/tcp --permanent
echo "${FIREWALL_CMD_RELOAD}"
firewall-cmd --reload

####  relabel the directory (at this moment, hopefully any relabeling should not be occured)

restorecon -Rv /var/www

#### echo installer finished

echo_installer_has_finished

#### Back from the directory which was only convenient  

popd

##################### end main part ###################
