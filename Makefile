##################################################################################################################
# 
# This makefile is designed to use release-manager.sh, helm-command-builder.sh, and release.yaml (input).
# This wraps our helm tooling so that the complexity of a helm command is deminished by defining releases in one place (release.yaml)
# 
# Usage:
# 
# make [install, upgrade, template, uninstall, encrypt, decrypt] [namespace] [(optional) release-name]
# 
# Example: 
# 1) To install the nifi release defined in the dia-test namespace run:
#     make install dia-test nifi
# 
# 2) To install all releases defined in dia-test run:
#     make install dia-test
# 
# * The same process will for install, upgrade, template, uninstall, encrypt, decrypt*
# 
# The release manager will run the helm command builder to source files as defined in release.yaml 
# and create and run appropriate helm commands.  
# 
##################################################################################################################

RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)


.PHONY: install, upgrade, template, uninstall, encrypt, decrypt

install:
	./scripts/release-manager.sh install $(RUN_ARGS)

upgrade:
	./scripts/release-manager.sh upgrade $(RUN_ARGS)

template:
	./scripts/release-manager.sh template $(RUN_ARGS)

uninstall:
	./scripts/release-manager.sh uninstall $(RUN_ARGS)

encrypt:
	./scripts/release-manager.sh enc $(RUN_ARGS)
decrypt:
	./scripts/release-manager.sh dec $(RUN_ARGS)

stub-namespace:
	./scripts/stubb-release-from-helm.sh $(RUN_ARGS)

clean-templates:
	@rm -f *-template.yaml

