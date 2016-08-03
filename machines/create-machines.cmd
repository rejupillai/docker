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
set  allnodes=%servers%%kvstore%

echo master   - %master%
echo workers  - %workers%
echo kvstore  - %kvstore%
echo servers  - %servers%
echo allnodes - %allnodes%

@REM Remove master and workers
rem for %%i in (%allnodes%) do (
rem 	docker-machine rm %%i --force
rem  )

@REM - Step 1 : Create a node for Keystore to be used by Consul  
rem  
@REM - Get the generated IP-Addr for the Consul's Keystore
set kvstore-ip-expr="docker-machine ip kvstore"
@FOR /F %%i IN ( '%kvstore-ip-expr%' ) DO  set kvstore-ip=%%i


@REM -Step 2 : Create all master machines...

for %%i in (%master%) do (

echo "Creating machine ............" %%i
docker-machine create -d virtualbox  --virtualbox-memory "2048" --swarm --swarm-master --swarm-discovery="consul://%kvstore-ip%:8500" --engine-label nodename=dh-%%i --engine-opt="cluster-store=consul://%kvstore-ip%:8500" --engine-opt="cluster-advertise=eth1:2376" %%i

)

docker-machine ls 
@REM -Step 3 : Create all worker morker machines...

for %%i in (%workers%) do (

echo "Configuring machine ............" %%i
docker-machine create -d virtualbox  --virtualbox-memory "2048" --swarm  --swarm-discovery="consul://%kvstore-ip%:8500" --engine-label nodename=dh-%%i --engine-opt="cluster-store=consul://%kvstore-ip%:8500" --engine-opt="cluster-advertise=eth1:2376" %%i



@REM Configure machine for NAT Port forwarding for few HTTP Ports
VBoxManage controlvm %%i natpf1 "%%i_1,tcp,127.0.0.1,1080,,1080"
VBoxManage controlvm %%i natpf1 "%%i_2,tcp,127.0.0.1,2080,,2080"
VBoxManage controlvm %%i natpf1 "%%i_3,tcp,127.0.0.1,3080,,3080"
VBoxManage controlvm %%i natpf1 "%%i_4,tcp,127.0.0.1,4080,,4080"
VBoxManage controlvm %%i natpf1 "%%i_5,tcp,127.0.0.1,5080,,5080"
VBoxManage controlvm %%i natpf1 "%%i_6,tcp,127.0.0.1,6080,,6080"
VBoxManage controlvm %%i natpf1 "%%i_7,tcp,127.0.0.1,7080,,7080"


@REM Configure machine for shared folders on Windows
docker-machine stop %%i
VBoxManage sharedfolder add %%i --name "%%i"-data --hostpath "%docker-data-host-path%"%%i --automount
docker-machine start %%i


echo "Successfully configured machine ............" %%i


)


echo "All machines created successfully ............"

