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
echo images - %images%
echo docker-images-host-path=%docker-images-host-path%

@REM Remove master and workers
for %%i in (%allnodes%) do (
	docker-machine rm %%i --force
 )	

@REM - Step 1 : Create a node for Keystore to be used by Consul  
docker-machine create -d virtualbox  --virtualbox-memory "1048" %kvstore%

@REM - Run the Consul service
docker-machine env %kvstore%
@FOR /f "tokens=*" %%i IN ('docker-machine env %kvstore%') DO @%%i
docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap

echo "-----------------------Created keystore and running Consul successfully  -----------------------------------------------"



@REM - Get the generated IP-Addr for the Consul's Keystore
set kvstore-ip-expr="docker-machine ip %kvstore%"
@FOR /F %%i IN ( '%kvstore-ip-expr%' ) DO  set kvstore-ip=%%i


for %%i in (%master%) do (

docker-machine create -d virtualbox  --virtualbox-memory "2048" --swarm --swarm-master --swarm-discovery="consul://%kvstore-ip%:8500" --engine-label nodename=dh-%%i --engine-opt="cluster-store=consul://%kvstore-ip%:8500" --engine-opt="cluster-advertise=eth1:2376" %%i

)

echo "-----------------------Created swarm master ---------------------------------------------------------------------"


docker-machine ls 
@REM -Step 3 : Create all worker morker machines...

for %%i in (%workers%) do (

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
rem docker-machine stop %%i
rem VBoxManage sharedfolder add %%i --name %%i-data --hostpath "%docker-data-host-path%%%i" --automount
rem docker-machine start %%i

)

echo "-----------------------Configured NAT Port forwaring and sharedfolder for workers -----------------------------------------"



@REM Load images from tar-balls
docker-machine env --swarm  %master%
@FOR /f "tokens=*" %%i IN ('docker-machine env --swarm %master%') DO @%%i

for %%i in (%images%) do (

	echo " command ---> docker load  ..\docker-images\%%i"
	docker load -i C:\Users\pillai\Work\docker\docker-images\%%i
)


echo "----------------------------------Loaded all images----------------------------------------------------"


 docker-compose -f compose\docker-compose.yml up -d 