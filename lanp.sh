#!/bin/bash
echo "It will install lanp."
##check last command is OK or not.
check_ok() {
if [ $? != 0 ]
then
    echo "Error, Check the error log."
    exit 1
fi
}

##close seliux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 
selinux_s=`getenforce`
if [ $selinux_s == "enforcing" ]
then
    setenforce 0
fi
##close iptables
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
service iptables save

##if the packge installed ,then omit.
myum() {
if ! rpm -qa|grep -q "^$1"
then
    yum install -y $1
    check_ok
else
    echo $1 already installed.
fi
}

## install some packges.
for p in gcc wget perl perl-devel libaio libaio-devel pcre-devel zlib-devel
do
    myum $p
done

##install epel.
if rpm -qa epel-release >/dev/null
then
    rpm -e epel-release
fi
if ls /etc/yum.repos.d/epel-6.repo* >/dev/null 2>&1
then
    rm -f /etc/yum.repos.d/epel-6.repo*
fi
wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/epel-6.repo

##function of install httpd.
install_httpd() {
echo "Install apache version 2.4.20"
cd /usr/local/src
tar zxf  httpd-2.4.20.tar.gz
wget http://apache.fayea.com/apr/apr-1.5.2.tar.bz2 && tar jxf apr-1.5.2.tar.bz2
wget http://apache.fayea.com/apr/apr-util-1.5.4.tar.bz2 && tar jxf apr-util-1.5.4.tar.bz2
cp -r apr-1.5.2 httpd-2.4.20/srclib/apr
cp -r apr-util-1.5.4 httpd-2.4.20/srclib/apr-util
cd httpd-2.4.20
./configure \
--prefix=/usr/local/apache \
--with-mpm=worker \
--with-included-apr \
--enable-so \
--enable-deflate=shared \
--enable-expires=shared \
--enable-rewrite=shared \
--enable-headers \
--enable-mime-magic \
--enable-ssl=shared \
--enable-static-support \
--disable-userdir \
--with-crypto \
--with-ssl \
--with-pcre
check_ok
make && make install
check_ok
cp /usr/local/apache/bin/apachectl /etc/init.d/httpd
sed -i '/#!\/bin\/sh/a\# chkconfig: - 50 15' /etc/init.d/httpd
check_ok
sed -i '/# chkconfig: - 50 15/a\# description: Apache is a World Wide Web server' /etc/init.d/httpd
check_ok
chmod 755 /etc/init.d/httpd
chkconfig --add httpd
check_ok
}

##function of install php.
install_php() {
echo "Install php version 5.6.21"
cd /usr/local/src/
tar zxf php-5.6.21.tar.gz && mv php-5.6.21 php-5.6
cd php-5.6
for p in openssl-devel bzip2-devel libxml2-devel curl-devel libpng-devel libjpeg-devel freetype-devel libmcrypt-devel libtool-ltdl-devel perl-devel
do
   myum $p
done

./configure \
--prefix=/usr/local/php \
--with-apxs2=/usr/local/apache/bin/apxs \
--with-config-file-path=/usr/local/php/etc \
--enable-mysqlnd \
--with-mysql=mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-libxml-dir \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--with-iconv-dir \
--with-zlib-dir \
--with-bz2 \
--with-openssl \
--with-mcrypt \
--with-curl \
--with-xmlrpc \
--with-gettext \
--with-mhash \
--enable-ftp \
--enable-bcmath \
--enable-shmop \
--enable-sockets \
--enable-zip \
--enable-opcache \
--enable-mbstring \
--enable-soap \
--enable-gd-native-ttf \
--enable-mbstring \
--enable-sockets \
--enable-exif \
--enable-xml \
--disable-debug \
--disable-ipv6
check_ok
make && make install
check_ok
[ -f /usr/local/php/etc/php.ini ] || /bin/cp php.ini-production  /usr/local/php/etc/php.ini
check_ok
}


##function of apache and php configue.
join_apa_php() {
useradd -M -s /sbin/nologin www
sed -i 's/User daemon/User www/' /usr/local/apache/conf/httpd.conf
sed -i 's/Group daemon/Group www/' /usr/local/apache/conf/httpd.conf
check_ok
sed -i '/AddType .*.gz .tgz$/a\AddType application\/x-httpd-php .php' /usr/local/apache/conf/httpd.conf
check_ok
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html index.htm/' /usr/local/apache/conf/httpd.conf
check_ok
sed -i 's/#ServerName www.example.com:80/ServerName www.example.com:80/' /usr/local/apache/conf/httpd.conf
check_ok
if /usr/local/php/bin/php -i |grep -iq 'date.timezone => no value'
then
    sed -i '/;date.timezone =$/a\date.timezone = "Asia\/Chongqing"'  /usr/local/php/etc/php.ini
    check_ok
fi
}


##function of install nginx
install_nginx() {
cd /usr/local/src
tar zxf nginx-1.9.11.tar.gz && cd nginx-1.9.11
./configure --prefix=/usr/local/nginx --with-http_realip_module --with-http_sub_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_ssl_module --with-pcre
check_ok
make && make install
check_ok
if [ -f /etc/init.d/nginx ]
then
    /bin/mv /etc/init.d/nginx  /etc/init.d/nginx_`date +%s`
fi
curl http://www.apelearn.com/study_v2/.nginx_init -o /etc/init.d/nginx
check_ok
chmod 755 /etc/init.d/nginx
chkconfig --add nginx
curl http://www.apelearn.com/study_v2/.nginx_conf -o /usr/local/nginx/conf/nginx.conf
check_ok
sed -i 's/user nobody nobody;/user www www;/' /usr/local/nginx/conf/nginx.conf
check_ok
}

##function of install php-fpm
install_phpfpm() {
echo "Install php-fpm version 5.6.21"
cd /usr/local/src/
tar zxf php-5.6.21.tar.gz && mv php-5.6.21 php-fpm-5.6
cd php-fpm-5.6
if ! grep -q '^php-fpm:' /etc/passwd
then
    useradd -M -s /sbin/nologin php-fpm
    check_ok
fi
./configure \
--prefix=/usr/local/php-fpm \
--with-config-file-path=/usr/local/php-fpm/etc \
--enable-fpm \
--with-fpm-user=php-fpm \
--with-fpm-group=php-fpm \
--enable-mysqlnd \
--with-mysql=mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-libxml-dir \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--with-iconv-dir \
--with-zlib-dir \
--with-bz2 \
--with-openssl \
--with-mcrypt \
--with-curl \
--with-xmlrpc \
--with-gettext \
--with-mhash \
--enable-ftp \
--enable-bcmath \
--enable-shmop \
--enable-sockets \
--enable-zip \
--enable-opcache \
--enable-mbstring \
--enable-soap \
--enable-gd-native-ttf \
--enable-mbstring \
--enable-sockets \
--enable-exif \
--enable-xml \
--disable-debug \
--disable-ipv6
check_ok
make && make install
check_ok
    [ -f /usr/local/php-fpm/etc/php.ini ] || /bin/cp php.ini-production  /usr/local/php-fpm/etc/php.ini
     if /usr/local/php-fpm/bin/php -i |grep -iq 'date.timezone => no value'
     then
         sed -i '/;date.timezone =$/a\date.timezone = "Asia\/Chongqing"'  /usr/local/php-fpm/etc/php.ini
         check_ok
     fi
    [ -f /usr/local/php-fpm/etc/php-fpm.conf ] || curl http://www.apelearn.com/study_v2/.phpfpm_conf -o /usr/local/php-fpm/etc/php-fpm.conf
    [ -f /etc/init.d/php-fpm ] || /bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod 755 /etc/init.d/php-fpm
    chkconfig --add php-fpm
}


##function of check service is running or not, example nginx, httpd, php-fpm.
check_service() {
if [ "$1" == "phpfpm" ]
then
    s="php-fpm"
else
    s=$1
fi
n=`ps aux |grep "$s"|wc -l`
if [ $n -gt 1 ]
then
    echo "$s service is already started."
else
    if [ -f /etc/init.d/$s ]
    then
        /etc/init.d/$s start
        check_ok
    else
        install_$1
    fi
fi
}

##function of install lanp
lanp() {
check_service httpd
install_php
join_apa_php
check_service nginx
check_service phpfpm
echo "LANP compelete"
}
lanp
