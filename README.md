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

You will need to enter the postgres password in Webmin

