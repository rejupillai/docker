@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@REM
@REM  Author:	 Reju Pillai
@REM  Email:	 reju.pillai@gmail.com
@REM  Purpose:	 Creates machines with baseimage as boot2docker on a virtualbox Hyper-V. These machines are called nodes
@REM
@REM 			 CI/CD Topology
@REM
@REM  			 dev-master : swarm master for dev.  Schedules build related jobs for the worker nodes
@REM  			 dev-worker-ci : swarm worker for Build Pipeline -  SCM, Build , Test, Coverage, Qaulity etc.  The output is a build packet
@REM  			 dev-worker-test : swarm worker for single node functional tesing
@REM 			 ----------------------------------------------------------------- Firewall 
@REM  			 ops-master :  swarm master for ops,  Schedule deploy, monitoring related jobs for worker nodes
@REM  			 ops-worker-cd : swarm worker to host the CD tools
@REM  			 ops-worker-prod-1 : swarm worker for production environment node-1
@REM  			 ops-worker-prod-2 : swarm worker for production environment node-2
@REM
@REM
@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@echo off
setlocal

for /F "tokens=*" %%i in (.\machines\keyvalue.file) do  @%%i
set  servers=%master%%workers%
set  allnodes=%kvstore%%servers%

echo master   - %master%
echo workers  - %workers%
echo kvstore  - %kvstore%
echo servers  - %servers%
echo allnodes - %allnodes%



@REM Stop all nodes
for %%i in (%allnodes%) do (	
	echo stop  %%i
	docker-machine stop  %%i 
)


@REM re-provision all masters
for %%i in (%master%) do (	
	echo starting %%i
    docker-machine start  %%i
)



@REM re-provision all master and worker nodes.
for %%i in (%workers%) do (	
	echo starting %%i
	docker-machine start  %%i 

 )



echo "All machines re-started successfully ............"


@REM - Start all services 
docker-machine env --swarm %master%
@FOR /f "tokens=*" %%i IN ('docker-machine env --swarm %master%') DO @%%i
docker-compose -f compose\docker-compose.yml up -d