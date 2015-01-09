# Install nagios prerequisites
yum install -y wget httpd php gcc glibc glibc-common gd gd-devel make net-snmp

# Download the current stable release of nagios
wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.0.8.tar.gz
tar -xvzf nagios-4.0.8.tar.gz

# Create nagios user and command group
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios

# Install nagios
cd nagios-4.0.8
./configure --with-command-group=nagcmd
make all
make install
make install-init
make install-config
make install-commandmod
make install-webconf

cp -R contrib/eventhandlers/ /usr/local/nagios/libexec
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

# Enable nagios & apache to start on boot
chkconfig --add nagios
chkconfig httpd on

# Configure iptables to allow http access for nagios web admin
iptables -I INPUT 4 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
service iptables save

# Configure selinux to allow apache access to nagios scripts
chcon -Rt httpd_sys_script_exec_t /usr/local/nagios/sbin

# Create a user for web access
htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin Pr0m3th!

# Nagios plugin installation
wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz
tar -xvzf nagios-plugins-2.0.3.tar.gz
cd nagios-plugins-2.0.3
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install

# Create directory for unix sockets
mkdir /usr/local/nagios/var/rw -p
chown nagios.nagios /usr/local/nagios/var/rw
chmod 0775 -R /usr/local/nagios/var/rw