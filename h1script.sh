#!/bin/bash
# Please see important notes, requirements and usage at the bottom of this script.

#---------------------------------------------------
# Install
#---------------------------------------------------
if [ "$1" = "install" ]; then 
  #install psql on the host
    sudo apt install postgresql-client-common
    sudo apt install postgresql-client-16
  #clone the open source pg-primary-replica project
    git clone https://github.com/eremeykin/pg-primary-replica.git
    exit 0

#---------------------------------------------------
# Start and do QA (can be re-run)
#---------------------------------------------------
elif [ "$1" = "start" ]; then
    #rm replica_export.csv #uncomment to QA the output
    cd ./pg-primary-replica
  
  #Start the PG primary and replica detached (background), do not recreate if running.
    docker compose up -d --no-recreate postgres_primary postgres_replica

  #Get the pw from docker-compose.yaml (but would be from a vault in a production scenario).
    POSTGRES_PASSWORD=$(docker compose config | grep 'POSTGRES_PASSWORD')
    export PGPASSWORD=${POSTGRES_PASSWORD##* } #get the pw value as last item delimited by a space
    sleep 5 #TODO wait until docker img is healthy (docker ps)

  #Create user and db on primary
    psql -h 127.0.0.1 -U user -p 5432 -d postgres -c "\
    CREATE user hive with password 'hive';"
    psql -h 127.0.0.1 -U user -p 5432 -d postgres -c "\
    CREATE DATABASE hive ENCODING 'UTF-8' OWNER hive;"

  #Create schema, table and insert 100 rows into primary
    export PGPASSWORD='hive'
    sleep 5 #TODO wait until docker img is healthy (docker ps)
    
    psql -h 127.0.0.1 -U hive -p 5432 -d hive -c "\
    CREATE SCHEMA IF NOT EXISTS h1 AUTHORIZATION hive;\
    ALTER ROLE hive SET search_path TO public,h1;\
    CREATE TABLE IF NOT EXISTS temps (id serial primary key, dts timestamp, fahrenheit float); \
    DELETE FROM temps; 
    INSERT INTO temps (dts, fahrenheit) VALUES ( \
      generate_series('2007-02-01 13:00:00'::timestamp, '2007-02-01 13:01:39'::timestamp, '1 second'::interval) \
    , (random() * 3.0)-1.5 + 70 \
    );"

  #QA: Export replicated rows to validate synchronization
    psql -h 127.0.0.1 -U hive -p 5433 -d hive -c "\COPY (SELECT * FROM temps) TO '../replica_export.csv' csv header"
    ROWS=$(cat ../replica_export.csv | wc -l)
    if [ "$ROWS" = "101" ] ; then
      echo 'QA PASS'
      exit 0
    else
      echo 'QA FAIL'
      exit 1
    fi

#---------------------------------------------------
# Stop and clean up
#---------------------------------------------------
elif [ "$1" = "stop" ] ; then
    #rm replica_export.csv #uncomment to QA the output
    cd ./pg-primary-replica
    docker compose down -v
    #docker system prune #remove dangling and unreferenced resources
    exit 0

else
    echo 'Demo PG replication via docker compose validating synchronization.'
    echo 'Demo inserts 100 rows in a PG primary which are exported from its replica via docker compose.'
    echo 'In PRODUCTION, users/pw would be from a vault and this called from SysV or as Systemd service.'
    echo ''
    echo 'Host: Ubuntu 24.04 LTS on 2 vcpu and 7.5G ram'
    echo ' - Docker Setup Key Points: (follow https://docs.docker.com/engine/install/ubuntu/)'
    echo '   a.) Uninstall the distro docker, install docker via the official APT repo.'
    echo '   b.) Add your user to docker group:'
    echo '   c.) sudo usermod -aG docker $USER'
    echo '   d.) newgrp docker #run docker hello-world (reboot if socket errors)'
    echo ''
    echo 'Usage: h1script.sh command (example: ./h1script.sh install)'
    echo " commands:"
    echo '  install  Installs the demo by cloning the open source project pg-primary-replica from github'
    echo '  start    Starts the demo, creates 100 rows in the primary and exports them from the replica'
    echo '  stop     Stop the demo'
    exit 1
fi

