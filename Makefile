# create script for deploying contract
deploy :; forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# casting 
cast :: cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "getOffers()"

# offer loan
offer :: cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "offerLoan(uint256,uint256)" 1000 5 --rpc-url http://127.0.0.1:8545 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

cast send 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "offerLoan(uint256,uint256)" 10 5 --rpc-url http://127.0.0.1:8545 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

