#! /bin/bash
# SquidGuard blacklist builder .
# Update SquidGaurd path for respective installations squid install dir.
# Below is source compiled squid under /usr/local/squid.
 
if [ -d "/usr/local/squid/share/squidGuard" ] ;then
cd /usr/local/squid/share/squidGuard/
rm -f -f bl.tar.gz
mv /usr/local/squid/share/squidGuard/db/blacklists /usr/local/squid/share/squidGuard/db/blacklists.old
 
# Free blacklist 1
wget -O bl.tar.gz http://ftp.tdcnorge.no/pub/www/proxy/squidGuard/contrib/blacklists.tar.gz
tar --ungzip --extract --exclude=*.diff --directory=/usr/local/squid/share/squidGuard/db --verbose -f bl.tar.gz
rm -f -f bl.tar.gz
# Free contirb blacklist 2
wget -O bl.tar.gz ftp://ftp.univ-tlse1.fr/pub/reseau/cache/squidguard_contrib/blacklists.tar.gz
tar --ungzip --extract --exclude=*.diff --directory=/usr/local/squid/share/squidGuard/db --verbose -f bl.tar.gz
rm -f -f bl.tar.gz
# Free blacklist 3
 
wget -O bl.tar.gz http://squidguard.mesd.k12.or.us/blacklists.tgz
tar --ungzip --extract --exclude=*.diff --directory=/usr/local/squid/share/squidGuard/db --verbose -f bl.tar.gz
rm -f -f bl.tar.gz
# Shalla blacklist 4 [free personal use]
wget -O bl.tar.gz http://www.shallalist.de/Downloads/shallalist.tar.gz
tar --ungzip --extract --exclude=*.diff --directory=/usr/local/squid/share/squidGuard/db --verbose -f bl.tar.gz
rm -f -f bl.tar.gz
 
# Contrib blacklist free 5
wget -O bl.tar.gz http://www.bn-paf.de/filter/de-blacklists.tar.gz
tar --ungzip --extract --exclude=*.diff --directory=/usr/local/squid/share/squidGuard/db --verbose -f bl.tar.gz
rm -f -f bl.tar.gz
# Free blacklist 6
wget -O bl.tar.gz ftp://ftp.univ-tlse1.fr/pub/reseau/cache/squidguard_contrib/blacklists.tar.gz
tar --ungzip --extract --exclude=*.diff --directory=/usr/local/squid/share/squidGuard/db --verbose -f bl.tar.gz
rm -f -f bl.tar.gz
# Commercial free personal use blacklist 7
BL_URL="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download&file=bigblacklist"
wget -Onv bl.tar.gz ${BL_URL}
tar --ungzip --extract --exclude=*.diff --directory=/usr/local/squid/share/squidGuard/db --verbose -f bl.tar.gz
rm -f -f bl.tar.gz
 
# build squidsuard db
/usr/local/squid/share/bin/squidGuard -c /usr/local/squid/share/squidGuard/squidGuard.conf -C all
chown -R squid:squid /usr/local/squid/share/squidGuard/db
 
# insure permissions
find /usr/local/squid/share/squidGuard/db |xargs chmod 755
rm -rf /usr/local/squid/share/squidGuard/db/blacklists/global_usage
rm -rf /usr/local/squid/share/squidGuard/db/blacklists/README
 
else
echo "Path not found "
 
fi
 
list_of_f=(`ls /usr/local/squid/share/squidGuard/db/blacklists`)
for (( i = 0 ; i < ${#list_of_f[*]}; i++ )) do serch=`ls /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]} |grep -w urls` if [ "$serch" == "" ]; then echo " /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]} : urls not present " echo " So adding it : `touch /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]}/urls && echo "warex.com" >touch /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]}/urls`"
else
echo "hi $serch"
fi
 
serch1=`ls /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]} |grep -w domains`
if [ "$serch1" == "" ]; then
 
echo " /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]} : domains not present "
echo " So adding it : `touch /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]}/domains && echo " So adding it : `touch /usr/local/squid/share/squidGuard/db/blacklists/${list_of_f[i]}/domains`"`"
else
echo "hi $serch1"
fi
 
done
chown -R squid:squid /usr/local/squid/share/squidGuard/db/*
 
find /usr/local/squid/share/squidGuard/db/blacklists |xargs chmod 755
rm -rf /usr/local/squid/share/squidGuard/db/blacklists/global_usage
rm -rf /usr/local/squid/share/squidGuard/db/blacklists/README
 
chmod 755 /usr/local/squid/share/squidGuard/squidGuard.conf
 
chmod -R 777 /usr/local/squid/share/squidGuard/db/blacklists
 
chmod -R 777 /usr/local/squid/share/squidGuard/log
 
find /usr/local/squid/share/squidGuard/db/blacklists -type d -exec chmod 755 \{\} \; -print
 
chmod 777 /usr/local/squid/share/squidGuard/log