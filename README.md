# pgreplica
Demo - Do PG Replication via Docker Compose

## How to Run the Script
In Ubuntu 24.04 LTS setup according to section "Test Details" below, 
run the bash script with each command below, in order:
1. ./h1script.sh install
2. ./h1script.sh start
3. ./h1script.sh stop
Verify the sync: consoles contains QA PASS and replica_export.csv contains the replicated data.

## Assumptions & Limitations
- This demo leverages https://github.com/eremeykin/pg-primary-replica which is an 
  experimental test bed. The rationale is that it could be valuable for future hive-hive POC's.
- docker-compose.yml is in the pg-primary-replica directory created during install (step 1 above).  
- As a demo, pg-primary-replica has users/pw hardcoded and this effort does the same.
- In production, users/pw would not be hard coded but from a vault and the script called at boot by SysV or Systemd.
- Sleeps would be replaced with fine-grained status events read from the primary.

## Notes
Usage: h1script.sh command (example: ./h1script.sh install)
### commands:
- install: Installs the demo by cloning the open source project pg-primary-replica from github.
- start: Starts the demo, creates 100 rows in the primary, exports them from the replica to replica_export.csv for QA.
- stop: Stop the demo and removes dangling and unreferenced docker resources.
  
### Objective: Demo and validate Postgresql replication
Write a script that:
- Spins up two relational database instances using docker-compose.
- Inserts 100 new rows into the first database
- Syncs the 100 new rows to the second database.
- Verifies the sync
- Tears down the database instances.

### Requirements
- Use Docker Compose to manage the two relational database instances.
- Write the script in a language of your choice.
- Provide clear instructions in a README file on how to run the script, as well as any assumptions
- Provide docker-compose.yml, your script, and a README in a public facing repo.

## Method
Inserts 100 rows in a PG primary which are then exported from its read replica for QA.

This could be used for multiple hives by each having the read replica of its neighbor and FDW's to the
remaining hives. The would result in a small footprint because data isn't duplicated and any hive can union its data
and data from the read replicas of all other hives to have an up-to-date view of the world. 


## Test Details
Host: Tested on Ubuntu 24.04 LTS on 2 vcpu's, 7.5G ram and 20G disk.
 - Host Docker Setup Key Points: (follow https://docs.docker.com/engine/install/ubuntu/)
   Uninstall the distro docker, install docker via the official APT repo.
   
   Add your user to docker group:
   - sudo usermod -aG docker $USER
   - newgrp docker #run docker hello-world (reboot if socket errors)

