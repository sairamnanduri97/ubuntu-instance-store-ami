# Hardened Ubuntu16.04 AMI
## What do you need to run
 - packer
 - make
 - AWS account with admin rights

## How to run

```
make ubuntu16
```

If you need to build the ami in a private subnet, update makefile to provide the target subnet_id before run ```make ubuntu16```
```
subnet_id ?=  subnet-123454
```
## How to test
Run below to get a ec2 created with latest ami owned by current accout.
Need to update sg and key name.
```
make test
```

