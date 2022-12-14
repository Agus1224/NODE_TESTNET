

<p align="center">
  <img height="200" height="auto" src="https://user-images.githubusercontent.com/50621007/192454529-b8070948-6592-4022-96d9-b2adf7169243.png">
</p>

# nois node setup for testnet — nois-testnet-002

Official documentation:
>- [Validator setup instructions](https://docs.nois.network/use-cases/for-validators)

Explorer:
>-  https://explorer.kjnodes.com/nois

## Hardware Requirements
Like any Cosmos-SDK chain, the hardware requirements are pretty modest.

### Minimum Hardware Requirements
 - 4x CPUs; the faster clock speed the better
 - 8GB RAM
 - 100GB of storage (SSD or NVME)
 - Permanent Internet connection (traffic will be minimal during testnet; 10Mbps will be plenty - for production at least 100Mbps is expected)

### Recommended Hardware Requirements 
 - 8x CPUs; the faster clock speed the better
 - 64GB RAM
 - 1TB of storage (SSD or NVME)
 - Permanent Internet connection (traffic will be minimal during testnet; 10Mbps will be plenty - for production at least 100Mbps is expected)

## Set up your nois fullnode
### Option 1 (automatic)
You can setup your nois fullnode in few minutes by using automated script below. It will prompt you to input your validator node name!
```
wget -O nois.sh https://raw.githubusercontent.com/Agus1224/NODE_TESTNET/main/NOIS/nois.sh && chmod +x nois.sh && ./nois.sh
```

### Option 2 (manual)
You can follow [manual guide](https://github.com/Agus1224/NODE_TESTNET/blob/main/NOIS/manual_install.md) if you better prefer setting up node manually

## Post installation

When installation is finished please load variables into system
```bash
source $HOME/.bash_profile
```

Next you have to make sure your validator is syncing blocks. You can use command below to check synchronization status
```bash
noisd status 2>&1 | jq .SyncInfo
```

### (OPTIONAL) State Sync
You can state sync your node in minutes by running commands below
```bash
SNAP_RPC=https://nois-testnet-rpc.polkachu.com:443
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 500)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.noisd/config/config.toml
noisd tendermint unsafe-reset-all --home $HOME/.noisd --keep-addr-book
systemctl restart noisd && journalctl -u noisd -f -o cat
```

### Create wallet
To create new wallet you can use command below. Don’t forget to save the mnemonic
```bash
noisd keys add $WALLET
```

(OPTIONAL) To recover your wallet using seed phrase
```bash
noisd keys add $WALLET --recover
```

To get current list of wallets
```bash
noisd keys list
```

### Save wallet info
Add wallet and valoper address into variables 
```bash
NOIS_WALLET_ADDRESS=$(noisd keys show $WALLET -a)
NOIS_VALOPER_ADDRESS=$(noisd keys show $WALLET --bech val -a)
echo 'export NOIS_WALLET_ADDRESS='${NOIS_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export NOIS_VALOPER_ADDRESS='${NOIS_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Fund your wallet
In order to create validator first you need to fund your wallet with testnet tokens.
```bash
curl --header "Content-Type: application/json" \
--request POST \
--data '{"denom":"unois","address":"'$NOIS_WALLET_ADDRESS'"}' \
http://faucet.noislabs.com/credit
```

### Create validator
Before creating validator please make sure that you have at least 1 nois (1 nois is equal to 1000000 unois) and your node is synchronized

To check your wallet balance:
```bash
noisd query bank balances $NOIS_WALLET_ADDRESS
```
> If your wallet does not show any balance than probably your node is still syncing. Please wait until it finish to synchronize and then continue 

To create your validator run command below
```bash
noisd tx staking create-validator \
  --amount 100000000unois \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.07" \
  --min-self-delegation "1" \
  --pubkey  $(noisd tendermint show-validator) \
  --moniker $NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id $NOIS_CHAIN_ID
```

### Check your validator key
```bash
[[ $(noisd q staking validator $NOIS_VALOPER_ADDRESS -oj | jq -r .consensus_pubkey.key) = $(noisd status | jq -r .ValidatorInfo.PubKey.value) ]] && echo -e "\n\e[1m\e[32mTrue\e[0m\n" || echo -e "\n\e[1m\e[31mFalse\e[0m\n"
```

### Get list of validators
```bash
noisd q staking validators -oj --limit=3000 | jq '.validators[] | select(.status=="BOND_STATUS_BONDED")' | jq -r '(.tokens|tonumber/pow(10; 6)|floor|tostring) + " \t " + .description.moniker' | sort -gr | nl
```

## Get currently connected peer list with ids
```bash
curl -sS http://localhost:${NOIS_PORT}657/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}'
```

## Usefull commands
### Service management
Check logs
```
journalctl -fu noisd -o cat
```

Start service
```
sudo systemctl start noisd
```

Stop service
```
sudo systemctl stop noisd
```

Restart service
```
sudo systemctl restart noisd
```

### Node info
Synchronization info
```
noisd status 2>&1 | jq .SyncInfo
```

Validator info
```
noisd status 2>&1 | jq .ValidatorInfo
```

Node info
```
noisd status 2>&1 | jq .NodeInfo
```

Show node id
```
noisd tendermint show-node-id
```

### Wallet operations
List of wallets
```
noisd keys list
```

Recover wallet
```
noisd keys add $WALLET --recover
```

Delete wallet
```
noisd keys delete $WALLET
```

Get wallet balance
```
noisd query bank balances $NOIS_WALLET_ADDRESS
```

Transfer funds
```
noisd tx bank send $NOIS_WALLET_ADDRESS <TO_NOIS_WALLET_ADDRESS> 10000000unois
```

### Voting
```bash
noisd tx gov vote 1 yes --from $WALLET --chain-id=$NOIS_CHAIN_ID
```

### Staking, Delegation and Rewards
Delegate stake
```bash
noisd tx staking delegate $NOIS_VALOPER_ADDRESS 10000000unois --from=$WALLET --chain-id=$NOIS_CHAIN_ID --gas=auto
```

Redelegate stake from validator to another validator
```bash
noisd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 10000000unois --from=$WALLET --chain-id=$NOIS_CHAIN_ID --gas=auto
```

Withdraw all rewards
```
noisd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$NOIS_CHAIN_ID --gas=auto
```

Withdraw rewards with commision
```
noisd tx distribution withdraw-rewards $NOIS_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$NOIS_CHAIN_ID
```

### Validator management
Unjail validator
```bash
noisd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$NOIS_CHAIN_ID \
  --gas=auto
```

### Delete node
This commands will completely remove node from server. Use at your own risk!
```bash
sudo systemctl stop noisd
sudo systemctl disable noisd
sudo rm /etc/systemd/system/nois* -rf
sudo rm $(which noisd) -rf
sudo rm $HOME/.noisd* -rf
sudo rm $HOME/nois -rf
sed -i '/NOIS_/d' ~/.bash_profile
```

### Pruning for state sync node
```bash
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="2000"
pruning_interval="50"
snapshot_interval="2000"
snapshot_keep_recent="5"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.noisd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.noisd/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.noisd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.noisd/config/app.toml
sed -i -e "s/^snapshot-interval *=.*/snapshot-interval = \"$snapshot_interval\"/" $HOME/.noisd/config/app.toml
sed -i -e "s/^snapshot-keep-recent *=.*/snapshot-keep-recent = \"$snapshot_keep_recent\"/" $HOME/.noisd/config/app.toml
```
