.PHONY: build test format declare

build:
	scarb build

format:
	scarb fmt

test:
	scarb test

declare:
	starkli declare target/dev/cairo-erc-3525_${CONTRACT}.sierra.json 

declare-contract:
	$(MAKE) declare CONTRACT=contract