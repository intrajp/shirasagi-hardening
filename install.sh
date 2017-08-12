# install.sh -- install script of shirasagi-hardening
#
# The MIT License (MIT)
#
# Copyright (c) 2014 SHIRASAGI Project
# Copyright (C) Shintaro Fujiwara
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
MONGODB_VERSION="3.4"
INSTALL_TEMPLATE_PATH="install_template_files"
NGINX_CONF_PATH="/etc/nginx/conf.d"
SYSTEMD_CONF_PATH="/etc/systemd/system"
REPO_PATH="/etc/yum.repos.d"

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

#### file templates to be instlled on the box

INSTALL_FILES=("crontab" "drop.conf" "header.conf" "httpd.conf" "mongodb-org-MONGODB-VERSION.repo" "nginx.repo" "shirasagi-unicorn.service" "shirasagi.conf" "virtual.conf")

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
    local comm
    comm=$1
    if [ $? -eq 0 ]; then
        echo "'$comm' succeeded"
    else
        echo "'$comm' failed"
        err_msg
    fi
}

# clean the BUILD directory 

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

COM_1="systemctl start mongod.service"
COM_2="systemctl enable mongod.service"
COM_3="systemctl enable nginx.service"
COM_4="systemctl enable shirasagi-unicorn.service"
COM_5="systemctl daemon-reload"
COM_6="systemctl start nginx.service"
COM_7="bundle exec rake db:drop"
COM_8="bundle exec rake db:create_indexes"
COM_9="bundle exec rake ss:create_site data=\"{ name: \"自治体サンプル\", host: \"www\", domains: \"${SS_HOSTNAME}\" }\""
COM_10="bundle exec rake ss:create_site data=\"{ name: \"企業サンプル\", host: \"company\", domains: \"${SS_HOSTNAME}:${PORT_COMPA}\" }\""
COM_11="bundle exec rake ss:create_site data=\"{ name: \"子育て支援サンプル\", host: \"childcare\", domains: \"${SS_HOSTNAME}:${PORT_CHILD}\" }\""
COM_12="bundle exec rake ss:create_site data=\"{ name: \"オープンデータサンプル\", host: \"opendata\", domains: \"${SS_HOSTNAME}:${PORT_OPEND}\" }\""
COM_13="bundle exec rake db:seed name=demo site=www"
COM_14="bundle exec rake db:seed name=company site=company"
COM_15="bundle exec rake db:seed name=childcare site=childcare"
COM_16="bundle exec rake db:seed name=opendata site=opendata"
COM_17="bundle exec rake db:seed name=gws"
COM_18="bundle exec rake db:seed name=webmail"
COM_19="systemctl start shirasagi-unicorn.service"
COM_20="bundle exec rake cms:generate_nodes"
COM_21="bundle exec rake cms:generate_pages"
COM_22="systemctl restart nginx.service"
COM_23="systemctl restart mongod.service"
COM_24="systemctl restart shirasagi-unicorn.service"
COM_25="firewall-cmd --add-port=http/tcp --permanent"
COM_26="firewall-cmd --add-port=${PORT_COMPA}/tcp --permanent"
COM_27="firewall-cmd --add-port=${PORT_CHILD}/tcp --permanent"
COM_28="firewall-cmd --add-port=${PORT_OPEND}/tcp --permanent"
COM_29="firewall-cmd --reload"
COM_30="rm -rf ${SS_DIR}/BUILD"
COM_31="make"
##################### end functions ###################

#### make log file and logs in root directory

mklog

#### make install template directory

mkdir "${INSTALL_TEMPLATE_PATH}"

pushd ${INSTALL_TEMPLATE_PATH}
    for i in "${INSTALL_FILES[@]}"
    do
        curl https://raw.githubusercontent.com/intrajp/shirasagi-hardening/master/${INSTALL_TEMPLATE_PATH}/${i}
    done
popd

#### echo installer 
echo_installer

#### check OS version and if not ok, exit
check_OS_version

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

cp ${INSTALL_TEMPLATE_PATH}/mongodb-org-MONGODB-VERSION.repo ${REPO_PATH}
sed -i "s/MONGODB-VERSION/${MONGODB_VERSION}/g" ${REPO_PATH}/mongodb-org-MONGODB-VERSION.repo
mv ${REPO_PATH}/mongodb-org-MONGODB-VERSION.repo ${REPO_PATH}/mongodb-org-${MONGODB_VERSION}.repo

#### repo file for Nginx

cp ${INSTALL_TEMPLATE_PATH}/nginx.repo ${REPO_PATH}

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

#### Furigana
mkdir BUILD

pushd BUILD

wget -O mecab-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"
wget -O mecab-ipadic-2.7.0-20070801.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"
wget -O mecab-ruby-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7VUNlczBWVDZJbE0"
wget https://raw.githubusercontent.com/shirasagi/shirasagi/stable/vendor/mecab/mecab-ipadic-2.7.0-20070801.patch

tar xvzf mecab-0.996.tar.gz

pushd mecab-0.996

./configure --enable-utf8-only
#make
${COM_31}
check_function_succeeded "${COM_31}"
make install

popd

tar xvzf mecab-ipadic-2.7.0-20070801.tar.gz

pushd mecab-ipadic-2.7.0-20070801

patch -p1 < ../mecab-ipadic-2.7.0-20070801.patch
./configure --with-charset=UTF-8
#make
${COM_31}
check_function_succeeded "${COM_31}"
make install

popd

tar xvzf mecab-ruby-0.996.tar.gz
pushd mecab-ruby-0.996
ruby extconf.rb
#make
${COM_31}
check_function_succeeded "${COM_31}"
make install

popd

cat >> /etc/ld.so.conf << "EOF"
/usr/local/lib
EOF

ldconfig

#### Voice
popd
pushd BUILD

wget http://downloads.sourceforge.net/hts-engine/hts_engine_API-1.08.tar.gz \
  http://downloads.sourceforge.net/open-jtalk/open_jtalk-1.07.tar.gz \
  http://downloads.sourceforge.net/lame/lame-3.99.5.tar.gz \
  http://downloads.sourceforge.net/sox/sox-14.4.1.tar.gz

tar xvzf hts_engine_API-1.08.tar.gz
pushd hts_engine_API-1.08
./configure
#make
${COM_31}
check_function_succeeded "${COM_31}"
make install

popd

tar xvzf open_jtalk-1.07.tar.gz
pushd open_jtalk-1.07
sed -i "s/#define MAXBUFLEN 1024/#define MAXBUFLEN 10240/" bin/open_jtalk.c
sed -i "s/0x00D0 SPACE/0x000D SPACE/" mecab-naist-jdic/char.def
./configure --with-charset=UTF-8
#make
${COM_31}
check_function_succeeded "${COM_31}"
make install

popd

tar xvzf lame-3.99.5.tar.gz
pushd lame-3.99.5
./configure
#make
${COM_31}
check_function_succeeded "${COM_31}"
make install

popd

tar xvzf sox-14.4.1.tar.gz
pushd sox-14.4.1
./configure
#make
${COM_31}
check_function_succeeded "${COM_31}"
make install

popd

ldconfig

popd

#### setting nginx

cp ${INSTALL_TEMPLATE_PATH}/httpd.conf ${NGINX_CONF_PATH} 

cp ${INSTALL_TEMPLATE_PATH}/header.conf ${NGINX_CONF_PATH} 

mkdir ${NGINX_CONF_PATH}/{common,server}

cp ${INSTALL_TEMPLATE_PATH}/drop.conf ${NGINX_CONF_PATH}/common

cp ${INSTALL_TEMPLATE_PATH}/virtual.conf ${NGINX_CONF_PATH}/conf.d

sed -i "s/SS-HOSTNAME/${SS_HOSTNAME}/g" ${NGINX_CONF_PATH}/virtual.conf
sed -i "s/PORT-COMPA/${PORT_COMPA}}/g" ${NGINX_CONF_PATH}/virtual.conf
sed -i "s/PORT-CHILD/${PORT_CHILD}}/g" ${NGINX_CONF_PATH}/virtual.conf
sed -i "s/PORT-OPEND/${PORT_OPEND}}/g" ${NGINX_CONF_PATH}/virtual.conf
sed -i "s/SS-DIR/${SS_DIR}}/g" ${NGINX_CONF_PATH}/virtual.conf

cp ${INSTALL_TEMPLATE_PATH}/shirasagi.conf ${NGINX_CONF_PATH}/server
sed -i "s/SS-DIR/${SS_DIR}}/g" ${NGINX_CONF_PATH}/shirasagi.conf

cp ${INSTALL_TEMPLATE_PATH}/shirasagi-unicorn.service ${SYSTEMD_CONF_PATH} 
sed -i "s/SS-DIR/${SS_DIR}}/g" ${SYSTEMD_CONF_PATH}/shirasagi-unicorn.service
sed -i "s/SS-USER/${SS_USER}}/g" ${SYSTEMD_CONF_PATH}/shirasagi-unicorn.service
sed -i "s/RVM-HOME/${RVM_HOME}}/g" ${SYSTEMD_CONF_PATH}/shirasagi-unicorn.service

#### daemonize

chown root: /etc/systemd/system/shirasagi-unicorn.service
chmod 644 /etc/systemd/system/shirasagi-unicorn.service

#### start mongod and enable it 

${COM_1}
check_function_succeeded "${COM_1}"
${COM_2}
check_function_succeeded "${COM_2}"

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
            echo "'semanage -m -t http_port_t -p tcp $p_' failed"
            err_msg
        else
            echo "'semanage -m -t http_port_t -p tcp $p_' succeeded"
        fi
    else
        echo "'semanage -a -t http_port_t -p tcp $p_' succeeded"
    fi
done

#### enable nginx 

${COM_3}
check_function_succeeded "${COM_3}"

#### enable shirasagi-unicorn 

${COM_4}
check_function_succeeded "${COM_4}"

#### taking changed configurations from filesystem and regenerationg dependency trees 

${COM_5}
check_function_succeeded "${COM_5}"

#### start nginx

${COM_6}
check_function_succeeded "${COM_6}"

cd $SS_DIR
${COM_7}
check_function_succeeded "${COM_7}"
${COM_8}
check_function_succeeded "${COM_8}"
bundle exec rake ss:create_site data="{ name: \"自治体サンプル\", host: \"www\", domains: \"${SS_HOSTNAME}\" }"
#${COM_9}
check_function_succeeded "${COM_9}"
bundle exec rake ss:create_site data="{ name: \"企業サンプル\", host: \"company\", domains: \"${SS_HOSTNAME}:${PORT_COMPA}\" }"
#${COM_10}
check_function_succeeded "${COM_10}"
bundle exec rake ss:create_site data="{ name: \"子育て支援サンプル\", host: \"childcare\", domains: \"${SS_HOSTNAME}:${PORT_CHILD}\" }"
#${COM_11}
check_function_succeeded "${COM_11}"
bundle exec rake ss:create_site data="{ name: \"オープンデータサンプル\", host: \"opendata\", domains: \"${SS_HOSTNAME}:${PORT_OPEND}\" }"
#${COM_12}
check_function_succeeded "${COM_12}"
${COM_13}
check_function_succeeded "${COM_13}"
${COM_14}
check_function_succeeded "${COM_14}"
${COM_15}
check_function_succeeded "${COM_15}"
${COM_16}
check_function_succeeded "${COM_16}"
${COM_17}
check_function_succeeded "${COM_17}"
${COM_18}
check_function_succeeded "${COM_18}"

#### start shirasagi-unicorn

${COM_19}
check_function_succeeded "${COM_19}"

# use openlayers as default map
echo 'db.ss_sites.update({}, { $set: { map_api: "openlayers" } }, { multi: true });' | mongo ss > /dev/null

${COM_20}
check_function_succeeded "${COM_20}"
${COM_21}
check_function_succeeded "${COM_21}"

cp ${INSTALL_TEMPLATE_PATH}/crontab ${SYSTEMD_CONF_PATH} 

sed -i "s/SS-DIR/${SS_DIR}}/g" ${INSTALL_TEMPLATE_PATH}/crontab
sed -i "s/RVM-HOME/${RVM_HOME}}/g" ${INSTALL_TEMPLATE_PATH}/crontab

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
${COM_22}
check_function_succeeded "${COM_22}"
${COM_23}
check_function_succeeded "${COM_23}"
${COM_24}
check_function_succeeded "${COM_24}"

#### firewalld stuff

${COM_25}
check_function_succeeded "${COM_25}"
${COM_26}
check_function_succeeded "${COM_26}"
${COM_27}
check_function_succeeded "${COM_27}"
${COM_28}
check_function_succeeded "${COM_28}"
${COM_29}
check_function_succeeded "${COM_29}"
${COM_30}
check_function_succeeded "${COM_30}"

#### echo installer finished
echo_installer_finished
