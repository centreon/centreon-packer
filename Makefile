.PHONY: version

help:
	@echo 'Usage:'
	@echo '  make <target>'
	@echo
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_0-9.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo

last: 20.10 ## Build last version available (20.10)
.PHONY: last

18.10:     ## Build Centreon 18.10
	@packer build -parallel=false -var-file vars/centreon-1810.json centreon-local.json

19.04:     ## Build Centreon 19.04
	@packer build -parallel=false -var-file vars/centreon-1904.json centreon-local.json

19.04-centos:     ## Build Centreon 19.04 over Centos ISO
	@packer build -parallel=false -var-file vars/centos-centreon-1904.json centreon-local.json

19.10:     ## Build Centreon OSS 19.10 over Centos ISO
	@packer build -parallel=false -var-file vars/centreon-1910.json centreon-local.json

20.04:     ## Build Centreon OSS 20.04 over Centos ISO
	@packer build -parallel=false -var-file vars/centreon-2004.json centreon-local.json

20.10:     ## Build Centreon OSS 20.10 over Centos ISO
	@packer build -parallel=false -var-file vars/centreon-2010.json centreon-local.json
