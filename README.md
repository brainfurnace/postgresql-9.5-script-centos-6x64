# postgresql 9.5 script for centos 6.x64

For use on a clean CentOS 6.x64 box only.

This script installs:

- postgresql95 

- postgresql95-devel

- postgresql95-server 

- postgresql95-libs 

- postgresql95-contrib 

- postgresql95-plperl 

- postgresql95-plpython 

- postgresql95-pltcl 

- postgresql94-python 

- postgresql95-odbc 

- postgresql95-jdbc 

- perl-DBD-Pg 

- pgbouncer

- Webmin

- IP tables

The script also creates the following:

- A minimally privilaged user (pgadmin)

- Disables root log in

- Sets IP tables

- Configures Webmin for managing PostgreSQL

- Installs a self-signed SSL

- Updates pga_hba.conf to MD5 and SSL

- Updates postgresql.conf for SSL.

- You can change the SSH port as well as the user name to whatever you like.  You can also add/remove packages.

- Once completed, it will display the new passwords for pgadmin, root, postgres, and ssl as well as write them to an auth.txt file.

Usage: 

1. Download the script to a clean CentOS 6.x64 box or use wget <code>wget https://github.com/DavidGhedini/postgresql-9.5-script-centos-6x64/blob/master/pgsql-9.5-centos-6x-64.sh</code>
2. Make it executable <code> chmod 755 pgsql-9.5-centos-6x-64.sh</code>
3. Execute it <code>./pgsql-9.5-centos-6x-64.sh</code>



Example output at end of script:

Passwords saved in /root/auth.txt

pg pass: DqVnavTlCXcSKfHprgUtjF-20rpfsKui

ssl pass: yxaQJCXgudTw19XEOMPdZzNd5n6rwVOG

pgadmin pass: A0RUHtPfSFC82mHeDP_ixrRavk7itgkE

root pass: RvZDHkZv-AeQS-ce0Mcnif7GxmmJ-zxN


