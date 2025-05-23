#!/bin/bash

# Set this to control how verbose the output is
VERBOSE=true

# Exit on first error
set -e

# Don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)

# clean the keystore
rm -rf ./hfc-key-store

# Import environment variables
export PATH="${PWD}/../bin:${PWD}:$PATH"
export FABRIC_CFG_PATH=${PWD}

# Create the channel
if [ "$VERBOSE" == "true" ]; then
  echo
  echo "Creating channel 'assetchannel'..."
  echo
fi

docker exec cli peer channel create -o orderer.example.com:7050 -c assetchannel -f ./channel-artifacts/channel.tx --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Join Org1 peers to the channel
if [ "$VERBOSE" == "true" ]; then
  echo "Joining peer0.org1.example.com to assetchannel..."
fi
docker exec cli peer channel join -b assetchannel.block

if [ "$VERBOSE" == "true" ]; then
  echo "Joining peer1.org1.example.com to assetchannel..."
fi
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 cli peer channel join -b assetchannel.block

# Join Org2 peers to the channel
# Join Org2 peers to the channel
if [ "$VERBOSE" == "true" ]; then
  echo "Joining peer0.org2.example.com to assetchannel..."
fi
docker exec -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
            -e CORE_PEER_LOCALMSPID=Org2MSP \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
            cli peer channel join -b assetchannel.block

if [ "$VERBOSE" == "true" ]; then
  echo "Joining peer1.org2.example.com to assetchannel..."
fi
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
            -e CORE_PEER_LOCALMSPID=Org2MSP \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
            cli peer channel join -b assetchannel.block

# Update anchor peers for Org2
if [ "$VERBOSE" == "true" ]; then
  echo "Updating anchor peers for Org2..."
fi
docker exec -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
            -e CORE_PEER_LOCALMSPID=Org2MSP \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
            cli peer channel update -o orderer.example.com:7050 -c assetchannel \
            -f ./channel-artifacts/Org2MSPanchors.tx --tls \
            --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo
echo "Total execution time : $(($(date +%s) - starttime)) secs"
echo "===== Network is ready ====="
