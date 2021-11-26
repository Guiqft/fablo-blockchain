# About the project

This project was made as a study of permissioned blockchains with Hyperledger Fabric. We opt to use [Fablo](https://github.com/softwaremill/fablo) to configure our network topology, combined with [Fablo REST](https://github.com/softwaremill/fablo-rest/) to make invocations using REST protocol, along with [Hyperledger Explorer](https://github.com/hyperledger/blockchain-explorer) to visualize ou blockchain blocks and transactions.

# The Blockchain

Our blockchain configuration stays all into `fabric-config.json`. We opt to set our blockchain in the following way:

-   2 channels `channel-org1` and `channel-org2`
-   2 organizations `Org1` and `Org2`, each one on your own channel
-   2 chaincodes, a [simple key-value store](https://github.com/softwaremill/fablo/blob/main/samples/chaincodes/chaincode-kv-node-1.4/) and the fabric [fabcar example](https://github.com/hyperledger/fabric-samples/tree/main/chaincode/fabcar/javascript), running on `channel-org1` and `channel-org2`, respectivaly

So, with that topology, `Org1` is responsible for creating blockings that sets a new key-value on the blockchain.
While `Org2` can manage a full list of cars, creating new cars and querying them.

# Running

After configuring our `fablo-config.json` to follow our topology pattern, we can run the follow command generate our docker images configurations (make sure that you already have installed Fablo on our machine)

```bash
fablo generate
```

This command creates the folder `fablo-target/`, which contains all our docker images configurations, with our network environment variables and certificates.

Now, we can start our network (you need Docker to be installed)

```bash
fablo up
```

> After that, you can run `docker ps` to check if your blockchain containers are running

🎉 That's it! You can now make HTTP requests following the [Fablo REST endpoints](https://github.com/softwaremill/fablo-rest#endpoints) patterns to enroll users, invoke chaincodes and more.

## The Hyperledger Explorer

With your network properly running, you can start the Hyperledger Explorer service to visualize your blockchain channels, blocks and transactions.

> If you changes the Fablo network configuration, you need to re-configure the files: `blockchain-explorer.yaml`, `connection-profile/*` and `config.json`. You can always check the [Explorer documentation](https://github.com/hyperledger/blockchain-explorer).

To start the Explorer service, first make sure that you have Docker Compose installed, then run

```bash
docker-compose -f blockchain-explorer.yaml up -d
```

Now you can go to your `localhost:8080`, insert your explorer admin credentials and visualize your entire blockchain!

# More

You can read [our text](https://www.notion.so/Projeto-com-Hyperledger-Fabric-ffc274ebfeaf4c07a3ccbabd22b2a513) (pt-BR) about the Hyperledger Fabric technology, along with printscreens presenting how we used this code in the practice.
