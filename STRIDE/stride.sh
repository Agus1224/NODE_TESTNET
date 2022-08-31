#!/bin/bash

while true
do

# Logo

curl -s https://raw.githubusercontent.com/Agus1224/NODE_TESTNET/main/logo_ALFONOVA | bash

# Menu

PS3='Select an action: '
options=(
"Install Node"
"Create wallet"
"UPDATE"
"Synchronize Stride node via StateSync"
"Synchronize Gaia   node via StateSync"
"Delete Node"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install Node")
echo "*********************"
echo -e "\e[1m\e[35m   Lets's begin\e[0m"
echo "*********************"
echo -e "\e[1m\e[32m  Enter your Validator_Name:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read Validator_Name
echo "_|-_|-_|-_|-_|-_|-_|"
echo export Validator_Name=${Validator_Name} >> $HOME/.bash_profile
echo export CHAIN_ID="STRIDE-TESTNET-4" >> $HOME/.bash_profile
source ~/.bash_profile

echo -e "\e[1m\e[32m1. Updating packages and dependencies--> \e[0m" && sleep 1
#UPDATE APT
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop screen unzip bc fail2ban htop -y

echo -e "        \e[1m\e[32m2. Installing GO--> \e[0m" && sleep 1
#INSTALL GO
ver="1.18.3" && \
cd $HOME && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version

echo -e "              \e[1m\e[32m3. Downloading and building binaries--> \e[0m" && sleep 1
#INSTALL
cd $HOME
git clone https://github.com/Stride-Labs/stride
cd stride
git checkout cf4e7f2d4ffe2002997428dbb1c530614b85df1b
make build
sudo cp $HOME/stride/build/strided /usr/local/bin

strided init $Validator_Name --chain-id $CHAIN_ID

wget -O $HOME/.stride/config/genesis.json "https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json"
wget -O $HOME/.stride/config/addrbook.json "https://raw.githubusercontent.com/obajay/nodes-Guides/main/Stride/addrbook.json"

echo -e "                     \e[1m\e[32m4. Node optimization and improvement--> \e[0m" && sleep 1

seeds=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.stride/config/config.toml
peers="54a11c47658ebd5dcbd70eb3c62197b439482d3f@116.202.236.115:21016"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.stride/config/config.toml

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0ustrd\"/;" ~/.stride/config/app.toml
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.stride/config/config.toml
external_address=$(wget -qO- eth0.me) 
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.stride/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 100/g' $HOME/.stride/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 100/g' $HOME/.stride/config/config.toml

# pruning and indexer
pruning="custom" && \
pruning_keep_recent="100" && \
pruning_keep_every="0" && \
pruning_interval="10" && \
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.stride/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.stride/config/app.toml && \
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.stride/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.stride/config/app.toml
indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.stride/config/config.toml


sudo tee /etc/systemd/system/strided.service > /dev/null <<EOF
[Unit]
Description=stride
After=network-online.target

[Service]
User=$USER
ExecStart=$(which strided) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable strided
sudo systemctl restart strided

echo '=============== SETUP FINISHED ==================='
echo -e 'Congratulations:        \e[1m\e[32mSUCCESSFUL NODE INSTALLATION\e[0m'
echo -e 'To check logs:        \e[1m\e[33mjournalctl -u strided -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[35mcurl -s localhost:26657/status\e[0m"

break
;;
"Create wallet")
echo "_|-_|-_|-_|-_|-_|-_|"
echo -e "      \e[1m\e[35m Your WalletName:\e[0m'"
echo "_|-_|-_|-_|-_|-_|-_|"
read Wallet
echo export Wallet=${Wallet} >> $HOME/.bash_profile
source ~/.bash_profile
strided keys add $Wallet
echo -e "      \e[1m\e[32m!!!!!!!!!SAVE!!!!!!!!!!!!!!!!SAVE YOUR MNEMONIC PHRASE!!!!!!!!!SAVE!!!!!!!!!!!!!!!!\e[0m'"

break
;;
"UPDATE")
cd ~
rm -rf $HOME/stride
git clone https://github.com/Stride-Labs/stride.git && cd stride
git checkout 90859d68d39b53333c303809ee0765add2e59dab
make build
mkdir -p $HOME/go/bin
sudo mv build/strided $(which strided)
sudo systemctl restart strided && journalctl -u strided -f -o cat

break
;;
"Synchronize Stride node via StateSync")
peers="cf4e629008be3417081395f4ab6f591a74124d90@141.95.124.151:20086"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.stride/config/config.toml
SNAP_RPC=141.95.124.151:20087
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 500)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.stride/config/config.toml
strided tendermint unsafe-reset-all --home $HOME/.stride
sudo systemctl restart strided && journalctl -u strided -f -o cat

break
;;
"Synchronize Gaia   node via StateSync")
sudo systemctl stop gaiad
PEERS="f42f1908713b97a2106a0872c7a6dbf64b274a77@141.95.124.151:23656"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.gaia/config/config.toml
SNAP_RPC="141.95.124.151:23657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 500)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.gaia/config/config.toml
gaiad tendermint unsafe-reset-all --home $HOME/.gaia
sudo systemctl restart gaiad && journalctl -u gaiad -f -o cat

break
;;
"Delete Node")
sudo systemctl stop strided && \
sudo systemctl disable strided && \
rm /etc/systemd/system/strided.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf .stride && \
rm -rf stride && \
rm -rf $(which strided)

break
;;
"Exit")
exit
esac
done
done
