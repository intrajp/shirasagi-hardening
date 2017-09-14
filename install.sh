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
OS_VERSION2="CentOS Linux release 7.4.1708 (Core)"

#### vars

THIS_USER=""
SELINUX=""

## hostname and user will be ask and set later, so...

SS_HOSTNAME="example.jp"
SS_DIR="/var/www/${PROG_NAME}"
# this variable would be used for deleting directory when command failed
CLEAN_DIR="${SS_DIR}"

#### ports

PORT_UNICORN=3000
PORT_COMPA=8001
PORT_CHILD=8002
PORT_OPEND=8003
SELINUX_PORT_TYPE="http_port_t"

#### log directory 

LOG_DIR="/var/log"

#### logfile

NOW=`date +%Y%m%d%H%M%S`
LOGFILE="${LOG_DIR}/${PROG_NAME}-install_${NOW}.log"

#### list of packages which should be present on the box

RPMS_TO_BE_INSTALLED=()
PACKAGES=("policycoreutils-python" "mongodb-org" "nginx" "gcc" "gcc-c++" "glibc-headers" "openssl-devel" "readline" "libyaml-devel" "readline-devel" "zlib" "zlib-devel" "wget" "git" "ImageMagick" "ImageMagick-devel" "firefox")

NGINX_DIR_COMMON="/etc/nginx/conf.d/common"
NGINX_DIR_SERVER="/etc/nginx/conf.d/server"

#### Ruby related softwares 

# rvm version 

RVM_VERSION="2.3.4"

# Furigana stuff

MECAB="mecab-0.996"
MECAB_IPADIC="mecab-ipadic-2.7.0-20070801"
MECAB_RUBY="mecab-ruby-0.996"
MECAB_IPADIC_PATCH="mecab-ipadic-2.7.0-20070801.patch"

# Voice stuff

HTS_ENGINE="hts_engine_API-1.08"
OPEN_JTALK="open_jtalk-1.07"
LAME="lame-3.99.5"
SOX="sox-14.4.1"

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
# this goes not well
RESTORECON_VAR_WWW="restorecon -Rv /var/www"

MV_TMP_DIR_TO_SS_DIR="mv /home/shirasagi/${NOW}/shirasagi ${SS_DIR}"
IMPORT_RVM_KEY="eval curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -"

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
        if [ "${os_version}" = "${OS_VERSION}" ] || [ "${os_version}" = "${OS_VERSION2}" ]; then
            echo "OS version is ${os_version}"
        else
            echo "Only on ${OS_VERSION} or ${OS_VERSION2} could be installed"
            err_msg
        fi
    else
        echo "Only on ${OS_VERSION} or ${OS_VERSION2} could be installed"
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
        echo ""
        echo "All needed packages are installed for shirasagi on this box. Proceeding..."
        echo ""
        sleep 5
    else
        echo ""
        echo "These packages are needed for shirasagi on this box."
        echo ""
        echo "${RPMS_TO_BE_INSTALLED[@]}"
        echo ""
        echo "Download and install these packages will start in 10 seconds."
        sleep 10 
        echo ""
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
                echo ""
                echo_installer_has_finished
                exit 0 
                ;;
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

# check if directory exists and if not create it
# arg 1: dir_name

check_mkdir()
{
    local dir=$1 
    if [ -d "${dir}" ]; then
        echo "${dir} exists"
    else
        mkdir -p "${dir}" >/dev/null
        if [ $? -ne 0 ]; then
            echo "mkdir -p ${dir} failed"
            err_msg
        else
            echo "mkdir -p ${dir} succeeded"
        fi
    fi
}

# clean the directory 
# arg 1: directory 

clean_dir()
{
    local dir 
    local comm 
    if [ -z "$1" ]; then
        echo "function error"
        err_msg
    fi
    dir="$1"
    comm="rm -rf ${dir}" 
    $(${comm})
    if [ $? -eq 0 ]; then
        echo "'$comm' succeeded"
    else
        echo "'$comm' failed"
        err_msg
    fi
}

# check function succeeded, if function fails and arg 2 (should be directory) is set, deleting arg 2  
# arg 1: command 
# arg 2 (option): directory to be deleted when command failed (also deleting user shirasagi) 

check_command_succeeded()
{
    if [ -z "$1" ]; then
        echo "function error"
        err_msg
    fi
    local comm
    local clean_dir
    comm="${1}"
    clean_dir=$2
    ## exec the command
    $(${comm})
    if [ $? -eq 0 ]; then
        echo "'$comm' succeeded"
    else
        echo "'$comm' failed"
        if [ ! -z "$2" ]; then
            clean_dir "${CLEAN_DIR}"
            rm -rf /home/shirasagi/${NOW} 
        fi
        err_msg
    fi
}

# check function succeeded (for runuser)
# arg 1 (option): directory to be deleted when command failed (also deleting user shirasagi) 

check_command_runuser()
{
    if [ $? -ne 0 ]; then
        echo "runuser command failed"
        if [ ! -z "$1" ]; then
            clean_dir "${CLEAN_DIR}"
            rm -rf /home/shirasagi/${NOW} 
        fi
        err_msg
    else
        echo "runuser command succeeded"
        sleep 5
    fi
}

# check function succeeded (try multiple times)
# arg 1: command 
# arg 2 (option): number (if not set, default is set to 3) 

try_command_multiple_times()
{
    local times=3 
    if [ -z "$1" ]; then
        echo "function error"
        err_msg
    fi
    if [ -z "$2" ]; then
       times=3 
    else
       times="$2" 
    fi
    local comm
    comm="${1}"
    echo "----------"
    echo $comm
    echo "----------"
    for i in $(seq 1 $times)
    do
        ## exec the command
        $(${comm})
        if [ $? -eq 0 ]; then
            echo "'${comm}' succeeded"
            return 1 
        else
            if [ $i = $times ]; then
                echo "'${comm}' failed"
            fi
            sleep 5
        fi
        return 1 
    done
}

# ask domain name

ask_domain_name()
{
    local ans=""
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

# SELinux should be allowed /usr/sbin/httpd to bind to network port <PORT> 
# set each port and if aready set, modify it
# arg 1: SELinux port type 
# arg 2: port number 

semanage_selinux_port()
{
    if [ -z "$1" ]; then
        echo "function error"
        err_msg
    elif [ -z "$2" ]; then
        echo "function error"
        err_msg
    fi
    local selinux_port_type=$1
    local port_num=$2
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

# clean git cloned directory

clean_git_cloned_dir()
{
    rm -rf /home/shirasagi/${NOW}
    if [ $? -eq 0 ];then
        echo "Cleaned git cloned directory"
    else
        echo "Failed cleaning git cloned directory"
    fi
}

# make program with some user
# arg 1: program_name 
# arg 2 (option, set NULL if not needed): configure option 
# arg 3 (option, set NULL if not needed): patching 
# arg 4 (option, set NULL if not needed): configure 
# arg 5 (option, set NULL if not needed): sed command 
# arg 6 (option, set NULL if not needed): sed command 

make_program()
{
    local program=$1
    local configure_option=$2
    local patch=$3
    local configure=$4
    local sed_1=$5
    local sed_2=$6

    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ] ; then
        echo "Function error. Some argument(s) are lacking."
        err_msg
    fi
    if [ "$2" = "NULL" ]; then
       configure_option="" 
    fi
    if [ "$3" = "NULL" ]; then
       patch="" 
    fi
    if [ "$4" = "NULL" ]; then
       configure="&& ./configure" 
    fi
    if [ "$5" != "ON" ]; then
       sed_1="off" 
    fi
    if [ "$6" != "ON" ]; then
       sed_2="off" 
    fi

    runuser -l shirasagi -c "cd ~/${NOW} && tar xvzf ${program}.tar.gz"
    check_command_runuser "${SS_DIR}"
    if [ $sed_1 = "ON" ]; then
        runuser -l shirasagi -c "cd ~/${NOW} && sed -i \"s/#define MAXBUFLEN 1024/#define MAXBUFLEN 10240/\" ${OPEN_JTALK}/bin/open_jtalk.c"
        check_command_runuser "${SS_DIR}"
    fi
    if [ $sed_2 = "ON" ]; then
        runuser -l shirasagi -c "cd ~/${NOW} && sed -i \"s/0x00D0 SPACE/0x000D SPACE/\" ${OPEN_JTALK}/mecab-naist-jdic/char.def"
        check_command_runuser "${SS_DIR}"
    fi
    runuser -l shirasagi -c "cd ~/${NOW}/${program} ${patch} ${configure} ${configure_option} && make"
    check_command_runuser "${SS_DIR}"
    pushd /home/shirasagi/${NOW}/${program}
        make install
    popd
}

# check file numbers in certain directory
# arg 1: directory name
# arg 2: numbers which should be present

check_file_numbers_in_directory()
{
    if [ -z "$1" ] || [ -z "$2" ] ; then
        echo "Function error. Some argument(s) are lacking."
        err_msg
    fi
    directory=$1
    numbers=$2
    if [ `find "${directory}" -maxdepth 1 -type f 2>/dev/null | wc -l` -ne "${numbers}" ];then
        echo ""
        echo "Files should be ${numbers} in ${directory}"
        err_msg
    else
        echo ""
        echo "Files are ${numbers} in ${directory}. It's OK."
        echo ""
    fi
}

##################### end functions ###################

##################### main part ###################

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
    echo "user shirasagi will be used during installation if needed."
    echo ""
fi

#### check_shirasagi directory in /var/www exists, if it exists, ask deleting it or not

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

#### repo file for mongodb for download and installing it

cat > /etc/yum.repos.d/mongodb-org-3.4.repo << "EOF"
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOF

#### repo file for Nginx for download and installing it

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
echo "######## All needed RPM package(s) are install on this box ########"

#### making temporary directory in /home/shirasagi 

runuser -l shirasagi -c "cd ~ && mkdir ${NOW}"
check_command_runuser

#### downloading furigana and voice packages

pushd /home/shirasagi/${NOW}
    wget --no-check-certificate -O "${MECAB}.tar.gz" "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"
    wget --no-check-certificate -O "${MECAB_IPADIC}.tar.gz" "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"
    wget --no-check-certificate -O "${MECAB_RUBY}.tar.gz" "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7VUNlczBWVDZJbE0"
    wget https://raw.githubusercontent.com/shirasagi/shirasagi/stable/vendor/mecab/"${MECAB_IPADIC_PATCH}"
    chown shirasagi:shirasagi *.tar.gz
    chown shirasagi:shirasagi "${MECAB_IPADIC_PATCH}"
popd

ls -l /home/shirasagi/${NOW}
check_file_numbers_in_directory "/home/shirasagi/${NOW}" 4
sleep 10

runuser -l shirasagi -c "cd ~/${NOW} && wget --no-check-certificate http://downloads.sourceforge.net/hts-engine/${HTS_ENGINE}.tar.gz \
    http://downloads.sourceforge.net/open-jtalk/${OPEN_JTALK}.tar.gz \
    http://downloads.sourceforge.net/lame/${LAME}.tar.gz \
    http://downloads.sourceforge.net/sox/${SOX}.tar.gz"
check_command_runuser "${SS_DIR}"

ls -l /home/shirasagi/${NOW}
check_file_numbers_in_directory "/home/shirasagi/${NOW}" 8
sleep 10

echo ""
echo "######## All needed packages --RPM(s) and sources-- are installed on this box ########"
echo ""

#### start mongod and enable it 

echo "######## Start mongod and enable it ########"

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

try_command_multiple_times "${IMPORT_RVM_KEY}"

echo "#### Got key ####"

#### getting rvm from certain place (this will make /usr/local/rvm)

curl -sSL https://get.rvm.io | bash -s stable

RVM_HOME=/usr/local/rvm

#### installing rvm

export PATH="$PATH:$RVM_HOME/bin"
echo ""
echo "Check env PATH"
echo ""
echo $PATH
echo ""
source $RVM_HOME/scripts/rvm

rvm install "${RVM_VERSION}" 
rvm use ${RVM_VERSION} --default
gem install bundler

#### cloning shirasagi and coping files to dir

#runuser -l shirasagi -c "cd ~ && mkdir ${NOW} && cd ${NOW} && git clone -b stable --depth 1 https://github.com/shirasagi/shirasagi"
runuser -l shirasagi -c "cd ~/${NOW} && git clone -b stable --depth 1 https://github.com/shirasagi/shirasagi"
check_command_runuser
check_mkdir /var/www
check_command_succeeded "${MV_TMP_DIR_TO_SS_DIR}"

echo ""
echo "#### Now, restoring context under /var/www, because when certain directory had been moved, SELinux label would not be 'should be state'."
echo ""
sleep 10

## this does not work, why not?
#check_command_succeeded "${RESTORECON_VAR_WWW}" "${SS_DIR}"
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

#### Furigana (files should be downloaded by this time)

echo "######## Installing furigana stuff ########"

echo "######## mecab ########"

make_program "${MECAB}" "--enable-utf8-only" "NULL" "NULL" "NULL" "NULL"

echo "######## mecab-ipadic ########"

make_program "${MECAB_IPADIC}" "--enable-utf8-only" "&& patch -p1 < ../${MECAB_IPADIC_PATCH}" "NULL" "NULL" "NULL"

echo "######## mecab-ruby ########"

make_program "${MECAB_RUBY}" "NULL" "NULL" "&& ruby extconf.rb" "NULL" "NULL"

echo "######## ldconfig ########"

cat >> /etc/ld.so.conf << "EOF"
/usr/local/lib
EOF

check_command_succeeded ldconfig

#### Voice (files should be downloaded by this time)

echo "######## Installing voice stuff ########"

echo "######## hts_engine ########"

make_program "${HTS_ENGINE}" "NULL" "NULL" "NULL" "NULL" "NULL"

echo "######## open_jtalk ########"

make_program "${OPEN_JTALK}" "NULL" "NULL" "NULL" "ON" "ON"

echo "######## lame ########"

make_program "${LAME}" "NULL" "NULL" "NULL" "NULL" "NULL"

echo "######## sox ########"

make_program "${SOX}" "NULL" "NULL" "NULL" "NULL" "NULL"

echo "######## ldconfig ########"

check_command_succeeded ldconfig

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

check_mkdir "${NGINX_DIR_COMMON}"
check_mkdir "${NGINX_DIR_SERVER}"

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

check_command_succeeded "${SYSTEMCTL_ENABLE_SHIRASAGI_UNICORN}" "${SS_DIR}"

#### taking changed configurations from filesystem and regenerationg dependency trees 

check_command_succeeded "${SYSTEMCTL_DAEMON_RELOAD}" "${SS_DIR}"

runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:drop"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:create_indexes"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"自治体サンプル\", host: \"www\", domains: \"${SS_HOSTNAME}\" }'"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"企業サンプル\", host: \"company\", domains: \"${SS_HOSTNAME}:${PORT_COMPA}\" }'"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"子育て支援サンプル\", host: \"childcare\", domains: \"${SS_HOSTNAME}:${PORT_CHILD}\" }'"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake ss:create_site data='{ name: \"オープンデータサンプル\", host: \"opendata\", domains: \"${SS_HOSTNAME}:${PORT_OPEND}\" }'"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:seed name=demo site=www"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:seed name=company site=company"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:seed name=childcare site=childcare"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:seed name=opendata site=opendata"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:seed name=gws"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake db:seed name=webmail"
check_command_runuser "${SS_DIR}"

#### start shirasagi-unicorn

check_command_succeeded "${SYSTEMCTL_START_SHIRASAGI_UNICORN}" "${SS_DIR}"

# use openlayers as default map
echo 'db.ss_sites.update({}, { $set: { map_api: "openlayers" } }, { multi: true });' | mongo ss > /dev/null

runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake cms:generate_nodes"
check_command_runuser "${SS_DIR}"
runuser -l shirasagi -c "cd ${SS_DIR} && ./bin/bundle exec ./bin/rake cms:generate_pages"
check_command_runuser "${SS_DIR}"

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

check_command_succeeded "${SYSTEMCTL_RESTART_NGINX}" "${SS_DIR}"
check_command_succeeded "${SYSTEMCTL_RESTART_MONGOD}" "${SS_DIR}"
check_command_succeeded "${SYSTEMCTL_RESTART_SHIRASAGI_UNICORN}" "${SS_DIR}"

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

#### cleaning cloned directory 

clean_git_cloned_dir

#### echo installer finished

echo_installer_has_finished

#### Now, exit the program  

exit 0 

##################### end main part ###################
