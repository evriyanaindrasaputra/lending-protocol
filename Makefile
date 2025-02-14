-include .env

# Clean the repo
clean  :; forge clean

# Install the necessary dependencies
install :; forge install OpenZeppelin/openzeppelin-contracts --no-commit
