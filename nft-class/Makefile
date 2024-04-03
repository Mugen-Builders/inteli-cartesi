-include .env

.PHONY: vouchers deploy env test

info: header

define HEADER

███╗   ██╗███████╗████████╗    ██╗███╗   ██╗████████╗███████╗██╗     ██╗    
████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║╚══██╔══╝██╔════╝██║     ██║    
██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║   ██║   █████╗  ██║     ██║    
██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║   ██║   ██╔══╝  ██║     ██║    
██║ ╚████║██║        ██║       ██║██║ ╚████║   ██║   ███████╗███████╗██║    
╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝╚═╝    

endef

export HEADER

# DEFAULT VARIABLES
START_LOG = @echo "======================================================= START OF LOG ========================================================="
END_LOG = @echo "======================================================== END OF LOG =========================================================="

RPC_URL := $(RPC_URL)
PRIVATE_KEY := $(PRIVATE_KEY)
DEPLOY_NETWORK_ARGS := script/DeployNFT.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(TESTNET_BLOCKSCAN_API_KEY) -v

define test_contracts
	$(START_LOG)
	@forge test
	$(END_LOG)
endef

define deploy_contracts
	$(START_LOG)
	@forge script $(DEPLOY_NETWORK_ARGS)
	$(END_LOG)
endef

setup: .env.tmpl
	forge install
	cp .env.tmpl .env

test:
	@echo "$$HEADER"
	@$(test_contracts)

deploy:
	@echo "$$HEADER"
	@$(deploy_contracts)