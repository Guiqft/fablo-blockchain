#!/usr/bin/env bash

function generateArtifacts() {
  printHeadline "Generating basic configs" "U1F913"

  printItalics "Generating crypto material for Orderer" "U1F512"
  certsGenerate "$FABLO_NETWORK_ROOT/fabric-config" "crypto-config-orderer.yaml" "peerOrganizations/orderer.com" "$FABLO_NETWORK_ROOT/fabric-config/crypto-config/"

  printItalics "Generating crypto material for Org1" "U1F512"
  certsGenerate "$FABLO_NETWORK_ROOT/fabric-config" "crypto-config-org1.yaml" "peerOrganizations/org1.com" "$FABLO_NETWORK_ROOT/fabric-config/crypto-config/"

  printItalics "Generating crypto material for Org2" "U1F512"
  certsGenerate "$FABLO_NETWORK_ROOT/fabric-config" "crypto-config-org2.yaml" "peerOrganizations/org2.com" "$FABLO_NETWORK_ROOT/fabric-config/crypto-config/"

  printItalics "Generating genesis block for group group1" "U1F3E0"
  genesisBlockCreate "$FABLO_NETWORK_ROOT/fabric-config" "$FABLO_NETWORK_ROOT/fabric-config/config" "Group1Genesis"

  # Create directory for chaincode packages to avoid permission errors on linux
  mkdir -p "$FABLO_NETWORK_ROOT/fabric-config/chaincode-packages"
}

function startNetwork() {
  printHeadline "Starting network" "U1F680"
  (cd "$FABLO_NETWORK_ROOT"/fabric-docker && docker-compose up -d)
  sleep 4
}

function generateChannelsArtifacts() {
  printHeadline "Generating config for 'channel-org1'" "U1F913"
  createChannelTx "channel-org1" "$FABLO_NETWORK_ROOT/fabric-config" "ChannelOrg1" "$FABLO_NETWORK_ROOT/fabric-config/config"
  printHeadline "Generating config for 'channel-org2'" "U1F913"
  createChannelTx "channel-org2" "$FABLO_NETWORK_ROOT/fabric-config" "ChannelOrg2" "$FABLO_NETWORK_ROOT/fabric-config/config"
}

function installChannels() {
  printHeadline "Creating 'channel-org1' on Org1/peer0" "U1F63B"
  docker exec -i cli.org1.com bash -c "source scripts/channel_fns.sh; createChannelAndJoin 'channel-org1' 'Org1MSP' 'peer0.org1.com:7041' 'crypto/users/Admin@org1.com/msp' 'orderer0.group1.orderer.com:7030';"

  printItalics "Joining 'channel-org1' on  Org1/peer1" "U1F638"
  docker exec -i cli.org1.com bash -c "source scripts/channel_fns.sh; fetchChannelAndJoin 'channel-org1' 'Org1MSP' 'peer1.org1.com:7042' 'crypto/users/Admin@org1.com/msp' 'orderer0.group1.orderer.com:7030';"
  printHeadline "Creating 'channel-org2' on Org2/peer0" "U1F63B"
  docker exec -i cli.org2.com bash -c "source scripts/channel_fns.sh; createChannelAndJoin 'channel-org2' 'Org2MSP' 'peer0.org2.com:7061' 'crypto/users/Admin@org2.com/msp' 'orderer0.group1.orderer.com:7030';"

}

function installChaincodes() {
  if [ -n "$(ls "$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node")" ]; then
    local version="0.0.1"
    printHeadline "Packaging chaincode 'kv'" "U1F60E"
    chaincodeBuild "kv" "node" "$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node"
    chaincodePackage "cli.org1.com" "peer0.org1.com:7041" "kv" "$version" "node" printHeadline "Installing 'kv' for Org1" "U1F60E"
    chaincodeInstall "cli.org1.com" "peer0.org1.com:7041" "kv" "$version" ""
    chaincodeInstall "cli.org1.com" "peer1.org1.com:7042" "kv" "$version" ""
    chaincodeApprove "cli.org1.com" "peer0.org1.com:7041" "channel-org1" "kv" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" ""
    printItalics "Committing chaincode 'kv' on channel 'channel-org1' as 'Org1'" "U1F618"
    chaincodeCommit "cli.org1.com" "peer0.org1.com:7041" "channel-org1" "kv" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" "peer0.org1.com:7041" "" ""
  else
    echo "Warning! Skipping chaincode 'kv' installation. Chaincode directory is empty."
    echo "Looked in dir: '$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node'"
  fi
  if [ -n "$(ls "$CHAINCODES_BASE_DIR/./chaincodes/fabcar")" ]; then
    local version="0.0.1"
    printHeadline "Packaging chaincode 'fabcar'" "U1F60E"
    chaincodeBuild "fabcar" "node" "$CHAINCODES_BASE_DIR/./chaincodes/fabcar"
    chaincodePackage "cli.org2.com" "peer0.org2.com:7061" "fabcar" "$version" "node" printHeadline "Installing 'fabcar' for Org2" "U1F60E"
    chaincodeInstall "cli.org2.com" "peer0.org2.com:7061" "fabcar" "$version" ""
    chaincodeApprove "cli.org2.com" "peer0.org2.com:7061" "channel-org2" "fabcar" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" ""
    printItalics "Committing chaincode 'fabcar' on channel 'channel-org2' as 'Org2'" "U1F618"
    chaincodeCommit "cli.org2.com" "peer0.org2.com:7061" "channel-org2" "fabcar" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" "peer0.org2.com:7061" "" ""
  else
    echo "Warning! Skipping chaincode 'fabcar' installation. Chaincode directory is empty."
    echo "Looked in dir: '$CHAINCODES_BASE_DIR/./chaincodes/fabcar'"
  fi

}

function notifyOrgsAboutChannels() {
  printHeadline "Creating new channel config blocks" "U1F537"
  createNewChannelUpdateTx "channel-org1" "Org1MSP" "ChannelOrg1" "$FABLO_NETWORK_ROOT/fabric-config" "$FABLO_NETWORK_ROOT/fabric-config/config"
  createNewChannelUpdateTx "channel-org2" "Org2MSP" "ChannelOrg2" "$FABLO_NETWORK_ROOT/fabric-config" "$FABLO_NETWORK_ROOT/fabric-config/config"

  printHeadline "Notyfing orgs about channels" "U1F4E2"
  notifyOrgAboutNewChannel "channel-org1" "Org1MSP" "cli.org1.com" "peer0.org1.com" "orderer0.group1.orderer.com:7030"
  notifyOrgAboutNewChannel "channel-org2" "Org2MSP" "cli.org2.com" "peer0.org2.com" "orderer0.group1.orderer.com:7030"

  printHeadline "Deleting new channel config blocks" "U1F52A"
  deleteNewChannelUpdateTx "channel-org1" "Org1MSP" "cli.org1.com"
  deleteNewChannelUpdateTx "channel-org2" "Org2MSP" "cli.org2.com"
}

function upgradeChaincode() {
  local chaincodeName="$1"
  if [ -z "$chaincodeName" ]; then
    echo "Error: chaincode name is not provided"
    exit 1
  fi

  local version="$2"
  if [ -z "$version" ]; then
    echo "Error: chaincode version is not provided"
    exit 1
  fi

  if [ "$chaincodeName" = "kv" ]; then
    if [ -n "$(ls "$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node")" ]; then
      printHeadline "Packaging chaincode 'kv'" "U1F60E"
      chaincodeBuild "kv" "node" "$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node"
      chaincodePackage "cli.org1.com" "peer0.org1.com:7041" "kv" "$version" "node" printHeadline "Installing 'kv' for Org1" "U1F60E"
      chaincodeInstall "cli.org1.com" "peer0.org1.com:7041" "kv" "$version" ""
      chaincodeInstall "cli.org1.com" "peer1.org1.com:7042" "kv" "$version" ""
      chaincodeApprove "cli.org1.com" "peer0.org1.com:7041" "channel-org1" "kv" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" ""
      printItalics "Committing chaincode 'kv' on channel 'channel-org1' as 'Org1'" "U1F618"
      chaincodeCommit "cli.org1.com" "peer0.org1.com:7041" "channel-org1" "kv" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" "peer0.org1.com:7041" "" ""

    else
      echo "Warning! Skipping chaincode 'kv' upgrade. Chaincode directory is empty."
      echo "Looked in dir: '$CHAINCODES_BASE_DIR/./chaincodes/chaincode-kv-node'"
    fi
  fi
  if [ "$chaincodeName" = "fabcar" ]; then
    if [ -n "$(ls "$CHAINCODES_BASE_DIR/./chaincodes/fabcar")" ]; then
      printHeadline "Packaging chaincode 'fabcar'" "U1F60E"
      chaincodeBuild "fabcar" "node" "$CHAINCODES_BASE_DIR/./chaincodes/fabcar"
      chaincodePackage "cli.org2.com" "peer0.org2.com:7061" "fabcar" "$version" "node" printHeadline "Installing 'fabcar' for Org2" "U1F60E"
      chaincodeInstall "cli.org2.com" "peer0.org2.com:7061" "fabcar" "$version" ""
      chaincodeApprove "cli.org2.com" "peer0.org2.com:7061" "channel-org2" "fabcar" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" ""
      printItalics "Committing chaincode 'fabcar' on channel 'channel-org2' as 'Org2'" "U1F618"
      chaincodeCommit "cli.org2.com" "peer0.org2.com:7061" "channel-org2" "fabcar" "$version" "orderer0.group1.orderer.com:7030" "" "false" "" "peer0.org2.com:7061" "" ""

    else
      echo "Warning! Skipping chaincode 'fabcar' upgrade. Chaincode directory is empty."
      echo "Looked in dir: '$CHAINCODES_BASE_DIR/./chaincodes/fabcar'"
    fi
  fi
}

function stopNetwork() {
  printHeadline "Stopping network" "U1F68F"
  (cd "$FABLO_NETWORK_ROOT"/fabric-docker && docker-compose stop)
  sleep 4
}

function networkDown() {
  printHeadline "Destroying network" "U1F916"
  (cd "$FABLO_NETWORK_ROOT"/fabric-docker && docker-compose down)

  printf "\nRemoving chaincode containers & images... \U1F5D1 \n"
  docker rm -f $(docker ps -a | grep dev-peer0.org1.com-kv-0.0.1-* | awk '{print $1}') || echo "docker rm failed, Check if all fabric dockers properly was deleted"
  docker rmi $(docker images dev-peer0.org1.com-kv-0.0.1-* -q) || echo "docker rm failed, Check if all fabric dockers properly was deleted"
  docker rm -f $(docker ps -a | grep dev-peer1.org1.com-kv-0.0.1-* | awk '{print $1}') || echo "docker rm failed, Check if all fabric dockers properly was deleted"
  docker rmi $(docker images dev-peer1.org1.com-kv-0.0.1-* -q) || echo "docker rm failed, Check if all fabric dockers properly was deleted"
  docker rm -f $(docker ps -a | grep dev-peer0.org2.com-fabcar-0.0.1-* | awk '{print $1}') || echo "docker rm failed, Check if all fabric dockers properly was deleted"
  docker rmi $(docker images dev-peer0.org2.com-fabcar-0.0.1-* -q) || echo "docker rm failed, Check if all fabric dockers properly was deleted"

  printf "\nRemoving generated configs... \U1F5D1 \n"
  rm -rf "$FABLO_NETWORK_ROOT/fabric-config/config"
  rm -rf "$FABLO_NETWORK_ROOT/fabric-config/crypto-config"
  rm -rf "$FABLO_NETWORK_ROOT/fabric-config/chaincode-packages"

  printHeadline "Done! Network was purged" "U1F5D1"
}
