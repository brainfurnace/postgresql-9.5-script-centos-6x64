#!/bin/bash -e
#Version: 0.5
#MapFig

touch /root/auth.txt

CENTOS_VER=$(lsb_release -sr | cut -f1 -d.)
if [ $(uname -m) == 'x86_64' ]; then
  CENTOS_ARCH='x86_64'
else
  CENTOS_ARCH='i386'
fi

UNPRIV_USER='pgadmin'

function install_postgresql(){
	#1. Install PostgreSQL repo
	if [ ! -f /etc/yum.repos.d/pgdg-95-centos.repo ]; then
		rpm -ivh http://yum.pgrpms.org/9.5/redhat/rhel-${CENTOS_VER}-${CENTOS_ARCH}/pgdg-centos95-9.5-2.noarch.rpm

	fi

	#2. Disable CentOS repo for PostgreSQL
	if [ $(grep -m 1 -c 'exclude=postgresql' /etc/yum.repos.d/CentOS-Base.repo) -eq 0 ]; then
		sed -i.save '/\[base\]/a\exclude=postgresql*' /etc/yum.repos.d/CentOS-Base.repo
		sed -i.save '/\[updates\]/a\exclude=postgresql*' /etc/yum.repos.d/CentOS-Base.repo
	fi

	#3. Install PostgreSQL
	yum install -y postgresql95 postgresql95-devel postgresql95-server postgresql95-libs postgresql95-contrib postgresql95-plperl postgresql95-plpython postgresql95-pltcl postgresql95-python postgresql95-odbc postgresql95-jdbc perl-DBD-Pg

	if [ ! -f /var/lib/pgsql/9.5/data/pg_hba.conf ]; then
		service postgresql-9.5 initdb
	fi

	service postgresql-9.5 start

	#4. Set postgres Password
	if [ $(grep -m 1 -c 'pg pass' /root/auth.txt) -eq 0 ]; then
		PG_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
		sudo -u postgres psql 2>/dev/null -c "alter user postgres with password '${PG_PASS}'"
		echo "pg pass: ${PG_PASS}" > /root/auth.txt
	fi

	#5. Add Postgre variables to environment
	if [ $(grep -m 1 -c 'PGDATA' /etc/environment) -eq 0 ]; then
		cat >>/etc/environment <<CMD_EOF
export PGDATA=/var/lib/pgsql/9.5/data
export PATH=${PATH}:${HOME}/bin:/usr/pgsql-9.5/bin
CMD_EOF
	fi

	#6. Configure ph_hba.conf
	cat >/var/lib/pgsql/9.5/data/pg_hba.conf <<CMD_EOF
local	all all 							md5
host	all all 127.0.0.1	255.255.255.255	md5
host	all all 0.0.0.0/0					md5
host	all all ::1/128						md5
hostssl all all 127.0.0.1	255.255.255.255	md5
hostssl all all 0.0.0.0/0					md5
hostssl all all ::1/128						md5
CMD_EOF
	sed -i.save "s/.*listen_addresses.*/listen_addresses = '*'/" /var/lib/pgsql/9.5/data/postgresql.conf
	sed -i.save "s/.*ssl =.*/ssl = on/" /var/lib/pgsql/9.5/data/postgresql.conf


	#7. Enable Postgre to start on boot
	chkconfig --level 234 postgresql-9.5 on

	#8. Create Symlinks for Backward Compatibility from PostgreSQL 9 to PostgreSQL 8
	ln -sf /usr/pgsql-9.5/bin/pg_config /usr/bin
	ln -sf /var/lib/pgsql/9.5/data /var/lib/pgsql
	ln -sf /var/lib/pgsql/9.5/backups /var/lib/pgsql

	#9. create self-signed SSL certificates
	if [ ! -f /var/lib/pgsql/9.5/data/server.key -o ! -f /var/lib/pgsql/9.5/data/server.crt ]; then
		SSL_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
		if [ $(grep -m 1 -c 'ssl pass' /root/auth.txt) -eq 0 ]; then
			echo "ssl pass: ${SSL_PASS}" >> /root/auth.txt
		else
			sed -i.save "s/ssl pass:.*/ssl pass: ${SSL_PASS}/" /root/auth.txt
		fi
		openssl genrsa -des3 -passout pass:${SSL_PASS} -out server.key 1024
		openssl rsa -in server.key -passin pass:${SSL_PASS} -out server.key

		chmod 400 server.key

		openssl req -new -key server.key -days 3650 -out server.crt -passin pass:${SSL_PASS} -x509 -subj '/C=CA/ST=Frankfurt/L=Frankfurt/O=acuciva-de.com/CN=acuciva-de.com/emailAddress=info@acugis.com'
		chown postgres.postgres server.key server.crt
		mv server.key server.crt /var/lib/pgsql/9.5/data
	fi

	service postgresql-9.5 restart
}

function install_webmin(){
	yum -y install perl-Net-SSLeay
	if [ ! -d /usr/libexec/webmin/ ]; then
		rpm -ivh http://www.webmin.com/download/rpm/webmin-current.rpm
	fi
}


function secure_ssh(){
	if [ $(grep -m 1 -c ${UNPRIV_USER} /etc/passwd) -eq 0 ]; then
		useradd -m ${UNPRIV_USER}
	fi

	if [ $(grep -m 1 -c "${UNPRIV_USER} pass" /root/auth.txt) -eq 0 ]; then
		USER_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
		echo "${UNPRIV_USER}:${USER_PASS}" | chpasswd
		echo "${UNPRIV_USER} pass: ${USER_PASS}" >> /root/auth.txt
	fi

	sed -i.save 's/#\?Port [0-9]\+/Port 3838/' /etc/ssh/sshd_config
	sed -i.save 's/#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
	service sshd restart
}

install_postgresql;
install_webmin;
secure_ssh;

yum -y install pgbouncer

#10. change root password
if [ $(grep -m 1 -c 'root pass' /root/auth.txt) -eq 0 ]; then
	ROOT_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32);
	echo "root:${ROOT_PASS}" | chpasswd
	echo "root pass: ${ROOT_PASS}" >> /root/auth.txt
fi

#11. Set firewall rules
cat >/etc/sysconfig/iptables <<EOF
# Generated
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed
# Generated
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed
# Generated
*filter
:FORWARD ACCEPT [0:0]
:INPUT DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Accept traffic from internal interfaces
-A INPUT ! -i eth0 -j ACCEPT
# Accept traffic with the ACK flag set
-A INPUT -p tcp -m tcp --tcp-flags ACK ACK -j ACCEPT
# Allow incoming data that is part of a connection we established
-A INPUT -m state --state ESTABLISHED -j ACCEPT
# Allow data that is related to existing connections
-A INPUT -m state --state RELATED -j ACCEPT
# Accept responses to DNS queries
-A INPUT -p udp -m udp --dport 1024:65535 --sport 53 -j ACCEPT
# Accept responses to our pings
-A INPUT -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
# Accept notifications of unreachable hosts
-A INPUT -p icmp -m icmp --icmp-type destination-unreachable -j ACCEPT
# Accept notifications to reduce sending speed
-A INPUT -p icmp -m icmp --icmp-type source-quench -j ACCEPT
# Accept notifications of lost packets
-A INPUT -p icmp -m icmp --icmp-type time-exceeded -j ACCEPT
# Accept notifications of protocol problems
-A INPUT -p icmp -m icmp --icmp-type parameter-problem -j ACCEPT
# Allow connections to our SSH server
-A INPUT -p tcp -m tcp --dport 3838 -j ACCEPT
# Allow connections to our IDENT server
-A INPUT -p tcp -m tcp --dport auth -j ACCEPT
# Respond to pings
-A INPUT -p icmp -m icmp --icmp-type echo-request -j ACCEPT
# Allow DNS zone transfers
-A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
# Allow DNS queries
-A INPUT -p udp -m udp --dport 53 -j ACCEPT
# Allow connections to webserver
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
# Allow SSL connections to webserver
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
# Allow connections to mail server
-A INPUT -p tcp -m tcp -m multiport -j ACCEPT --dports 25,587
# Allow connections to FTP server
-A INPUT -p tcp -m tcp --dport 20:21 -j ACCEPT
# Allow connections to POP3 server
-A INPUT -p tcp -m tcp -m multiport -j ACCEPT --dports 110,995
# Allow connections to IMAP server
-A INPUT -p tcp -m tcp -m multiport -j ACCEPT --dports 143,220,993
# Allow connections to Webmin
-A INPUT -p tcp -m tcp --dport 10000:10010 -j ACCEPT
# Allow connections to Usermin
-A INPUT -p tcp -m tcp --dport 20000 -j ACCEPT
# Postgres
-A INPUT -p tcp -m tcp --dport 5432 -j ACCEPT
# pgbouncer
-A INPUT -p tcp -m tcp --dport 6432 -j ACCEPT
# SSH
-A INPUT -p tcp -m tcp --dport 3838 -j ACCEPT
COMMIT
EOF

#12. Set webmin config
cat >/etc/webmin/postgresql/config <<EOF
simple_sched=0
sameunix=1
date_subs=0
max_text=1000
perpage=25
stop_cmd=if [ -r /etc/rc.d/init.d/rhdb ]; then /etc/rc.d/init.d/rhdb stop; else /etc/rc.d/init.d/postgresql-9.5 stop; fi
psql=/usr/bin/psql
pid_file=/var/run/postmaster-9.5.pid
hba_conf=/var/lib/pgsql/9.5/data/pg_hba.conf
setup_cmd=if [ -r /etc/rc.d/init.d/rhdb ]; then /etc/rc.d/init.d/rhdb start; else /etc/rc.d/init.d/postgresql-9.5 initdb ; /etc/rc.d/init.d/postgresql-9.5 start; fi
user=postgres
nodbi=0
max_dbs=50
start_cmd=if [ -r /etc/rc.d/init.d/rhdb ]; then /etc/rc.d/init.d/rhdb start; else /etc/rc.d/init.d/postgresql-9.5 start; fi
repository=/var/lib/pgsql/9.5/backups
dump_cmd=/usr/bin/pg_dump
access=*: *
webmin_subs=0
style=0
rstr_cmd=/usr/bin/pg_restore
access_own=0
login=postgres
basedb=template1
add_mode=1
blob_mode=0
pass=${PG_PASS}
plib=
encoding=
port=
host=
EOF

#display pgadmin, root, postgres, and ssl password and write to auth file
echo "Passwords saved in /root/auth.txt"
cat /root/auth.txt
service sshd restart
/etc/init.d/iptables restart
