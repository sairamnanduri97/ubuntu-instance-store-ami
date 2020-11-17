#!/bin/bash

function usage {
  cat <<EOF
  USAGE:  $0 [-h] [-i image_id] [-i type] [-s sg] [-k ssh_key] [-p iam_profile]
  eg,
          $0 -h                #usage
          $0                   #query last n images then let user select
          $0 -i ami-123e45     #use ami-12345
EOF
  exit
}

function die {
  # die with a message
  echo >&2 "$@"
  exit 1
}

function list_amis(){
  local region_name="$1"
  local account_id="$2"
  aws ec2 describe-images \
    --filters \
    Name=owner-id,Values=$account_id \
    Name=architecture,Values=x86_64 \
    Name=virtualization-type,Values=hvm \
    Name=root-device-type,Values=ebs \
    --query "reverse(sort_by(Images[*], &CreationDate)) [*].[CreationDate,ImageId,Name]" \
    --region "$region_name" \
    --output text
}



function is_ami_exist {
  local ami_id="$1"
  local region_name="$2"
  echo "checking if $ami_id exist"
  local output=$(aws ec2 describe-images \
    --filters \
    Name=image-id,Values=$ami_id \
    --query "Images[*].[CreationDate,ImageId,Name]" \
    --region "$region_name" \
    --output text)

  return $(echo "$output"| wc -l)
}

while getopts "hi:t:s:p:k:r:" o; do
  case "$o" in
    h) usage ;;
    i) opt_i=1; ami="$OPTARG" ;;
    r) opt_r=1; region="$OPTARG" ;;
    t) opt_t=1; type="$OPTARG" ;;
    s) opt_s=1; sg="$OPTARG" ;;
    k) opt_k=1; ssh_key="$OPTARG" ;;
    p) opt_p=1; iam_profile="$OPTARG" ;;
    *) usage ;;
  esac
done

region="${region:-us-east-1}"
type="${type:-m4.large}"
sg="${sg:-sg-098ffba8178c943fc}"
ssh_key="${ssh_key:-amazon-linux2-ami}"
#iam_profile="${iam_profile:-Arn=arn:aws:iam::329935618861:instance-profile/SSMInstanceProfile}"

echo "$type, $sg, $ssh_key, $iam_profile, $ami, $region"


if [ "$opt_i" == "1" ]; then
  # cli input with imageid
  is_ami_exist $ami $region && die "image doesnot exist"
else
  account_id=$(aws sts get-caller-identity --query "Account" --output text)
  last_ami=$(list_amis "$region" $account_id | head -n 1 | awk '{print $2}')

  echo "Latest AMI owned by current account: $last_ami"

fi

echo "Create a ec2 in default vpc"

if [[ "$iam_profile" == ""  ]]; then
  ec2_id=$(aws ec2 run-instances --image-id $last_ami \
           --count 1 --instance-type $type --key-name $ssh_key\
           --region "$region" \
           --security-group-ids $sg \
             --instance-initiated-shutdown-behavior terminate \
             --output text --query 'Instances[*].InstanceId')
else
  ec2_id=$(aws ec2 run-instances --image-id $last_ami \
           --count 1 --instance-type $type --key-name $ssh_key \
           --security-group-ids $sg \
           --iam-instance-profile $iam_profile \
           --network-interfaces '[ { "DeviceIndex": 0, "DeleteOnTermination": true, "AssociatePublicIpAddress": true } ]' \
           --instance-initiated-shutdown-behavior terminate \
           --output text --query 'Instances[*].InstanceId')
fi

aws ec2 create-tags --region $region --resources $ec2_id --tags Key=Name,Value=\"test-ubuntu-$(whoami)-test-ec2\"
echo "Waiting for instance to run"
aws ec2 wait instance-running --instance-ids "$ec2_id"
echo "EC2 $ec2_id is now running"

#aws ec2 associate-iam-instance-profile --instance-id ${ec2_id} --iam-instance-profile Name=bastion
ip_address=$(aws ec2 describe-instances --instance-ids "$ec2_id" --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo "IP address: $ip_address"
echo "ssh -i ~/.ssh/${ssh_key}.pem ubuntu@${ip_address}"
ssh -i ~/.ssh/${ssh_key}.pem ec2-user@${ip_address}
