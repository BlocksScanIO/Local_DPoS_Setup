#!/bin/bash
_interupt() { 
    echo "Shutdown $child_proc"
    kill -TERM $child_proc
    exit
}

trap _interupt INT TERM

touch .pwd
export $(cat .env | xargs)
Bin_NAME=XDC

WORK_DIR=$PWD
PROJECT_DIR="/root/workspace/XDPoSChain"
cd $PROJECT_DIR && make XDC && make bootnode
cd $WORK_DIR

if [ ! -d ./nodes/1/keystore ]
then
  wallet1=$(${PROJECT_DIR}/build/bin/$Bin_NAME account import --password .pwd --datadir ./nodes/1 <(echo ${PRIVATE_KEY_1}) | awk -v FS="({|})" '{print $2}')
  ${PROJECT_DIR}/build/bin/$Bin_NAME --datadir ./nodes/1 init ./genesis/genesis.json
else
  wallet1=$(${PROJECT_DIR}/build/bin/$Bin_NAME account list --datadir ./nodes/1 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=3
GASPRICE="1"
networkid=551
INSTANCE_IP=$(curl https://checkip.amazonaws.com)


echo Starting the bootnode ...
${PROJECT_DIR}/build/bin/bootnode -nodekey ./bootnode.key --addr 0.0.0.0:30301 &
child_proc=$! 

echo Starting the nodes ...
${PROJECT_DIR}/build/bin/$Bin_NAME --bootnodes "enode://1c20e6b46ce608c1fe739e78611225b94e663535b74a1545b1667eac8ff75ed43216306d123306c10e043f228e42cc53cb2728655019292380313393eaaf6e23@185.217.125.200:30301,enode://1c20e6b46ce608c1fe739e78611225b94e663535b74a1545b1667eac8ff75ed43216306d123306c10e043f228e42cc53cb2728655019292380313393eaaf6e23@185.225.232.73:30301,enode://1c20e6b46ce608c1fe739e78611225b94e663535b74a1545b1667eac8ff75ed43216306d123306c10e043f228e42cc53cb2728655019292380313393eaaf6e23@185.217.125.200:30301,enode://1c20e6b46ce608c1fe739e78611225b94e663535b74a1545b1667eac8ff75ed43216306d123306c10e043f228e42cc53cb2728655019292380313393eaaf6e23@209.126.87.15:30301,enode://1c20e6b46ce608c1fe739e78611225b94e663535b74a1545b1667eac8ff75ed43216306d123306c10e043f228e42cc53cb2728655019292380313393eaaf6e23@66.94.125.165:30301,enode://1c20e6b46ce608c1fe739e78611225b94e663535b74a1545b1667eac8ff75ed43216306d123306c10e043f228e42cc53cb2728655019292380313393eaaf6e23@185.225.232.75:30301" --syncmode "full" --datadir ./nodes/1 --networkid "${networkid}" --port 30303 --rpc --rpccorsdomain "*" --ws --wsaddr="0.0.0.0" --wsorigins "*" --wsport 8555 --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts "*" --unlock "${wallet1}" --password ./.pwd --mine --gasprice "${GASPRICE}" --targetgaslimit "420000000" --verbosity ${VERBOSITY} --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS --ethstats "${wallet1}_${INSTANCE_IP}:xdc_xinfin_apothem_network_stats@stats.apothem.network:2000" 

