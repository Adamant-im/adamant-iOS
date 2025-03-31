# Define variables
CLI_BINARY_ROOT=scripts/AdamantCLI
CLI_BINARY=scripts/AdamantCLI/adamant-cli
CLI_NAME=adamant-cli

$(CLI_BINARY):
	@$(MAKE) -C scripts/AdamantCLI

.PHONY: configure
configure: $(CLI_BINARY)
	@$(MAKE) -C scripts/AdamantCLI -f Makefile
	@CLI_DIR=$(shell pwd)/$(shell dirname $(CLI_BINARY)); \
	if ! grep -q "$$CLI_DIR" $(HOME)/.zshrc; then \
		echo "path+=('$$CLI_DIR')" >> $(HOME)/.zshrc; \
		source $(HOME)/.zshrc; \
		echo "Added $$CLI_DIR/AdamantCLI to PATH"; \
	else \
		echo "Already in PATH"; \
	fi
	@echo "✅ Done. Use '$(CLI_NAME)' without './'."

.PHONY: clean
clean:
	@rm -f $(CLI_BINARY)
	@rm -rf $(CLI_BINARY_ROOT)/build
	@echo "Removed binary: $(CLI_BINARY)"