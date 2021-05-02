REMOTE_URBIT_ROOT=/data/urbit

include ./config.mk

help:
	echo "look at the README"

aws-ship-%: COMMAND=$*
aws-ship-%:
	make -C aws-ship $(COMMAND)

ssh-%: IP_ADDRESS=$(shell cd aws && terraform output --json | jq -r '.ship.value.public_ip')
ssh-go:
	ssh -i $(SSH_KEY_PATH) ubuntu@${IP_ADDRESS}

ssh-push-scripts:
	scp -i $(SSH_KEY_PATH) -r aws/rendered-scripts/ ubuntu@$(IP_ADDRESS):/home/ubuntu/

ssh-script-%: SCRIPT=$*
ssh-script-%:
	ssh -i $(SSH_KEY_PATH) ubuntu@${IP_ADDRESS} 'cd ~/rendered-scripts/$(SHIP) && ./$(SCRIPT).sh'

push-ship: IP_ADDRESS=$(shell cd aws && terraform output --json | jq -r '.ship.value.public_ip')
push-ship:
	@if [ -z "$(SHIP)" ]; then echo 'need $$SHIP set' && exit 1; fi
	@if [ -z "$(SSH_KEY_PATH)" ]; then echo 'need $$SSH_KEY_PATH set' && exit 1; fi
	@if [ -z "$(IP_ADDRESS)" ]; then echo 'need $$IP_ADDRESS set' && exit 1; fi
	scp -i $(SSH_KEY_PATH) -r ./ships/$(SHIP) ubuntu@$(IP_ADDRESS):$(REMOTE_URBIT_ROOT)

fetch-ship: IP_ADDRESS=$(shell cd aws && terraform output --json | jq -r '.ship.value.public_ip')
fetch-ship:
	@if [ -z "$(SHIP)" ]; then echo 'need $$SHIP set' && exit 1; fi
	@if [ -z "$(SSH_KEY_PATH)" ]; then echo 'need $$SSH_KEY_PATH set' && exit 1; fi
	@if [ -z "$(IP_ADDRESS)" ]; then echo 'need $$IP_ADDRESS set' && exit 1; fi
	scp -i $(SSH_KEY_PATH) -r ubuntu@$(IP_ADDRESS):$(REMOTE_URBIT_ROOT)/$(SHIP) ./ships/

build:
	$(MAKE) ssh-push-scripts
	$(MAKE) ssh-script-start_urbit
	$(MAKE) ssh-script-setup_nginx
	$(MAKE) ssh-script-add_s3_uploads

all:
	$(MAKE) aws-ship-terraform.tfvars
	$(MAKE) aws-ship-init
	$(MAKE) aws-ship-plan
	$(MAKE) aws-ship-apply
	$(MAKE) ssh-push-scripts
	$(MAKE) push-ship
	$(MAKE) ssh-script-start_urbit
	$(MAKE) ssh-script-setup_nginx
	$(MAKE) ssh-script-add_s3_uploads

.PHONY: help aws-ship-% %-ship ship-% build all
