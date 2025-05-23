#!/bin/bash

# Verbose output
VERBOSE=true

# Channel name
CHANNEL_NAME=assetchannel

# Set Fabric binaries and config path
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}

# Function to verify channel join for a peer
check_peer_channel_join() {
  MSP=$1
  PEER_ADDRESS=$2
  MSPCONFIGPATH=$3
  TLS_ROOTCERT_FILE=$4
  PEER_NAME=$5

  export CORE_PEER_LOCALMSPID=$MSP
  export CORE_PEER_ADDRESS=$PEER_ADDRESS
  export CORE_PEER_MSPCONFIGPATH=$MSPCONFIGPATH
  export CORE_PEER_TLS_ROOTCERT_FILE=$TLS_ROOTCERT_FILE

  if [ "$VERBOSE" == "true" ]; then
    echo "-----------------------------------------"
    echo "Checking joined channels for $PEER_NAME..."
  fi

  peer channel list
}

echo "🔍 Starting channel verification for all peers..."

# ---- Org1 Peers ----

check_peer_channel_join "Org1MSP" "peer0.org1.example.com:7051" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
  "peer0.org1"

check_peer_channel_join "Org1MSP" "peer1.org1.example.com:8051" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt" \
  "peer1.org1"

# ---- Org2 Peers ----

check_peer_channel_join "Org2MSP" "peer0.org2.example.com:9051" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
  "peer0.org2"

check_peer_channel_join "Org2MSP" "peer1.org2.example.com:10051" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt" \
  "peer1.org2"

echo "✅ All peer checks complete."
