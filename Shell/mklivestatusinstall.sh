# Install prerequisites
yum install -y gcc-c++ xinetd

# Download & extract mk-livestatus
wget https://mathias-kettner.de/download/mk-livestatus-1.2.4p5.tar.gz
tar -xvzf mk-livestatus-1.2.4p5.tar.gz 

# Install mk-livestatus
cd mk-livestatus-1.2.4p5
./configure --with-nagios4
/usr/bin/make
/usr/bin/make install

# Configure iptables to allow access for livestatus
iptables -I INPUT 5 -p tcp --dport 6557 -m state --state NEW,ESTABLISHED -j ACCEPT
service iptables save
