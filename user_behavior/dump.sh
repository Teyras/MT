#!/bin/sh

echo -n "Enter MySQL password: "
read -s mysql_pass
echo

ssh recodex -- MYSQL_PWD="$mysql_pass" mysql -u root -D recodex-api < dump.sql > out.tsv
