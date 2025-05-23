#!/bin/bash

# Exit on first error
set -e

CC_NAME="asset-transfer"
CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/asset-transfer"
CC_VERSION="1.0"
CC_SEQUENCE=1
CC_LABEL="${CC_NAME}_${CC_VERSION}"
CC_PACKAGE_FILE="$CC_NAME.tar.gz"

# Package the chaincode
echo "Packaging chaincode..."
docker exec cli peer lifecycle chaincode package $CC_PACKAGE_FILE --path $CC_SRC_PATH --lang golang --label $CC_LABEL

# Install chaincode on Org1 peers
echo "Installing chaincode on peer0.org1.example.com..."
docker exec cli peer lifecycle chaincode install $CC_PACKAGE_FILE

echo "Installing chaincode on peer1.org1.example.com..."
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 cli peer lifecycle chaincode install $CC_PACKAGE_FILE

# Install chaincode on Org2 peers
echo "Installing chaincode on peer0.org2.example.com..."
docker exec -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer lifecycle chaincode install $CC_PACKAGE_FILE

echo "Installing chaincode on peer1.org2.example.com..."
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer lifecycle chaincode install $CC_PACKAGE_FILE

# Query installed chaincode on Org1 peers
echo "Querying installed chaincode on peer0.org1.example.com..."
docker exec cli peer lifecycle chaincode queryinstalled >&installLog.txt
PACKAGE_ID=$(sed -n "/$CC_LABEL/{s/^Package ID: //; s/, Label:.*$//; p;}" installLog.txt)
rm installLog.txt
echo "Package ID: $PACKAGE_ID"

# Approve chaincode definition for Org1
echo "Approving chaincode definition for Org1..."
docker exec cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID assetchannel --name $CC_NAME --version $CC_VERSION --package-id $PACKAGE_ID --sequence $CC_SEQUENCE

# Approve chaincode definition for Org2
echo "Approving chaincode definition for Org2..."
docker exec -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID assetchannel --name $CC_NAME --version $CC_VERSION --package-id $PACKAGE_ID --sequence $CC_SEQUENCE

# Check commit readiness
echo "Checking commit readiness..."
docker exec cli peer lifecycle chaincode checkcommitreadiness --channelID assetchannel --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE --output json

# Commit chaincode definition
echo "Committing chaincode definition..."
docker exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID assetchannel --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# Query committed status
echo "Querying committed status..."
docker exec cli peer lifecycle chaincode querycommitted --channelID assetchannel --name $CC_NAME

# Initialize chaincode (if needed)
# echo "Initializing chaincode..."
# docker exec cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C assetchannel -n $CC_NAME --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"Init","Args":[]}'

echo "===== Chaincode is deployed ====="
