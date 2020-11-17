PACKER_BINARY ?= packer
PACKER_VARIABLES := aws_region ami_name binary_bucket_name binary_bucket_region source_ami_id source_ami_owners arch instance_type security_group_id additional_yum_repos subnet_id encrypted kms_key_id
AMI_VERSION := 1.0


ami_name ?= Ubuntu-16.04-hardened-instance-store2-$(AMI_VERSION)-v$(shell date +'%Y%m%d')
arch ?= x86_64
aws_region ?= us-east-1
subnet_id ?= subnet-0a3b6b913ce139461
account_id=$(shell aws sts get-caller-identity --query "Account" --output text)
encrypted ?= false
#kms_key_id ?= alias/aws/ebs
source_ami_id ?= $(shell aws ec2 describe-images \
      --region $(aws_region) \
      --owners 099720109477 \
      --filters 'Name=name,Values=ubuntu/images/ubuntu-xenial-16.04-amd64-server-20201014' \
      --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
      --output text)

ifeq ($(arch), arm64)
instance_type ?= a1.large
else
instance_type ?= m1.large
endif

T_RED := \e[0;31m
T_GREEN := \e[0;32m
T_YELLOW := \e[0;33m
T_RESET := \e[0m


.PHONY: validate
validate:
	$(PACKER_BINARY) validate $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) ubuntu-16.04-hardened.json

.PHONY: 
ubuntu16: validate
	@echo "$(T_GREEN)Building $(T_YELLOW)$(ami_name)$(T_GREEN) on $(T_YELLOW)$(arch)$(T_RESET)"
	$(PACKER_BINARY) build $(foreach packerVar,$(PACKER_VARIABLES), $(if $($(packerVar)),--var $(packerVar)='$($(packerVar))',)) ubuntu-16.04-hardened.json

.PHONY: test
test:
	./tools/run_ec2.sh -k amazon-linux2-ami -r $(aws_region) -s sg-921194d0  -t t2.micro -p "Arn=arn:aws:iam::329935618861:instance-profile/SSMInstanceProfile"

clean-ec2:
	AWS_DEFAULT_REGION=$(aws_region) aws ec2 describe-instances \
        --query "Reservations[].Instances[]|[?State.Name!='terminated'].[InstanceId, Tags[?Key=='Name'].Value|[0]]" \
        --output text  | grep "testvm-$(USER)-test-ec2" | awk '{print $$1}'  | \
      xargs -I {} aws ec2 terminate-instances --region $(aws_region) --instance-ids {}

clean-ami:
	AWS_DEFAULT_REGION=$(aws_region) aws ec2 describe-images \
        --filter Name=owner-id,Values=$(account_id) \
        --query "reverse(sort_by(Images, &CreationDate))[*].[ImageId, Tags[?Key=='Name'].Value|[0]]" \
        --output text | grep "Ubuntu-16.04-hardened" | awk '{print $$1}' | \
      xargs -I {} aws ec2 deregister-image --region $(aws_region) --image-id {}

clean-snapshot:
	AWS_DEFAULT_REGION=$(aws_region) aws ec2 describe-snapshots \
        --filter Name=owner-id,Values=$(account_id) \
        --query "Snapshots[].[SnapshotId, Tags[?Key=='Name'].Value|[0]]" \
        --output text | grep "Ubuntu-16.04-hardened" | awk '{print $$1}' | \
      xargs -I {} aws ec2 delete-snapshot --region $(aws_region) --snapshot-id {}

clean-all: clean-ec2 clean-ami clean-snapshot
