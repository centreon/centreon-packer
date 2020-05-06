# Amazon EBS Image builder

## Prerequisites

- Amazon account with access key and access
- Packer tool installed
- AWS CLI (Optional)

## How to use

### Change options

Customize some data from the Amazon environment by editing the `centreon-local.json` file in the `amazon-ebs` build block, as in the example below

```
    {
      "type" : "amazon-ebs",
      "access_key": "{{user `aws_access_key`}}",
      "secret_key": "{{user `aws_secret_key`}}",
      "profile" : "default",
      "region" : "us-east-2",
      "instance_type" : "t2.micro",
      "source_ami" : "ami-e0eac385",
      "ssh_username" : "centos",
      "ami_name" : "Centreon 20.04 Build 0.0.1",
      "ami_description" : "Centreon 20.04 OSS",
      "run_tags" : {
          "Name" : "packer-builder-centreon",
          "Tool" : "Packer",
          "Author" : "Luiz Costa <me@luizgustavo.pro.br>"
      }
    }
```

To obtain a list of Centos images (for use in `source_ami` option) available for the region you want to use in creating your image, using Amazon's cli, use the following command (change region for you choice)

```
aws --region us-east-1 ec2 describe-images --owners aws-marketplace --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce
```

always give preference to the most current images

More info: https://wiki.centos.org/Cloud/AWS


### For build image

```
packer build -only="amazon-ebs" \
    -var 'aws_access_key=XXXXXXXXXXXXXXX' \
    -var 'aws_secret_key=XXXXXXXXXXXXXXX' \
    -var-file vars/centreon-2004.json \
    centreon-local.json
```

Change variables `aws_access_key` and `aws_secret_key` for you values

### For make a new instancie of EC2 with image builded

Using AWS cli

```
aws ec2 run-instances --image-id <ami image id> \
    --count 1 --instance-type t2.micro \
    --key-name <you_sshkey> \
    --region us-east-2
```

Change `ami image id` for the id created with the packer command in output, like the example below:

```
==> amazon-ebs: Stopping the source instance...
    amazon-ebs: Stopping instance, attempt 1
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating the AMI: Centreon 20.04 Build 0.0.1
    amazon-ebs: AMI: ami-0272be87c981df307
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Modifying attributes on AMI (ami-0272be87c981df307)...
    amazon-ebs: Modifying: description
==> amazon-ebs: Modifying attributes on snapshot (snap-0aa31ab1b6e36712f)...
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Cleaning up any extra volumes...
==> amazon-ebs: Destroying volume (vol-0cdf083bba031c83a)...
==> amazon-ebs: Deleting temporary security group...
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.
```

See for `amazon-ebs: AMI` pattern
