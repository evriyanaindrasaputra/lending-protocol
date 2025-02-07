# create script for deploying contract
deploy :; forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# casting 
cast :: cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getOffers()"
