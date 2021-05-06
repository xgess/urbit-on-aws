# IAC for your Urbit on AWS

## High Level What Do You Need
* a nice URL that you can go to from any device that can hit your urbit ship
* an ec2 instance to run your ship
* TLS certificate so you have https to the instance
* an ssh key so you can hop on the instance if you want, or be able to run management stuff on there
* a persistent data store that isn't the ephemeral instance for holding your urbit's stateful data
* an s3 bucket (and config) so you can do uploads on landscape
* the ability to manage your infrastrucute using Infrastructure-As-Code
* somewhere to store the state of your IAC

## What is this?
* two terraform projects that implement the above
* the first one (`aws-infra`) is infrastructure for the second one (`aws-ship`).
* a top level makefile that can do everything you need.

### aws-infra
The idea here is to provide some minimal infrastructure for the real project, `aws-ship`. So the terraform state on this one is stored locally, but that shouldn't be too annoying because you really should only need to deploy this once and never think about it again.
* create a remote terraform state backend using a new s3 bucket. this lets `aws-ship` do some nicer things.
* optionally create an ssh key locally (the private key will never leave your device) and push up the public key as a keypair to AWS. This is optional and because I can imagine lots of usecases for which you might not want this project to be managing your ssh keys. and that's totally cool. i'm not offended. But it's also definitely easier to let me do it for you.
* this project will drop a text file into the `aws-ship` project folder so that project knows how to
  use the infrastructure that this one created.

### aws-ship
The idea here is to use terraform to build simple, full web stack for an urbit ship:
* route53 records pointing to a static public IP mapped to an EC2 instance
* nginx and certbot on the instance requesting a cert for TLS from LetsEncrypt
* an EBS volume mounted on the instance for persistent storage
* urbit running on the instance inside a tmux session
* an s3 bucket for uploads, and config for it typed into the dojo
* some convenience make targets for things like pulling down locally a current copy of your urbit

## Use It

### Prerequisites
* You need an AWS account and a user with sufficient permissions
* configure your aws cli. if you only have one aws cli user, the `aws_profile` is probably
  `default`.
* You need a domain with a hosted zone in AWS Route53. you can buy a domain on AWS for like $12/yr.
  Just do it right now. `tyrannosaurbit.com` is available, what are you waiting for?
* You need an urbit comet / planet / star / ... already initialized. I didn't want to mess with a master key of any kind finding its way onto AWS, so just initialize it first locally, then we'll push it up to EC2.
* terraform version 0.15. earlier will probably work too, but YMMV.

^ and i think that's it!

### How to get it done
1. copy `config.mk` and replace the values with what you're into
```
mv config.mk.example config.mk
```
1. make sure your planet has already been launched / initialized. You should have a folder with the name of your planet and a sub-directory called `.urb` in it.
```
open https://urbit.org/getting-started/
```
^ go here and do the very first steps locally
1. move your planet from wherever it is into the `ships/` directory in this project.
1. set up `aws-infra`
```
make aws-infra-terraform.tfvars
make aws-infra-init
make aws-infra-plan
```
^ take a look at the plan and make sure you're comfortable with everything that will be created in
your AWS account.
```
make aws-infra-apply
```
now you have infrastructure for deploying infrastructure as code. cool!
1. set up `aws-ship`
```
make aws-ship-terraform-tfvars
make aws-ship-init
make aws-ship-plan
```
^ take a look at the plan and make sure you're comfortable with everything that will be created in
your AWS account.
```
make aws-ship-apply
```
woop! now you have all of the AWS pieces stood up.
1. Let's push your ship up to the instance. If you don't do this, we'll wind up launching a comet.
This command assumes that you have a ship in the `ships` directory and it's the same one that's in
`config.mk`
```
make push-ship
```
1. now let's start it and get everything else on the instance spun up and ready to go.
```
make ssh-script-start_urbit
make ssh-script-setup_nginx
make ssh-script-add_s3_uploads
```

### And some things to know
* a lot of the management is done with templated scripts that are managed by terraform, dropped on
  the instance, and then called remotely by your local instance.
* it would probably have been better to have the instance inside a private subnet of the VPC, but
  then i'd have to pay for a load balancer or some other way to get through to it, and blech.
* if you wanna hop on the instance, that's a simple `make ssh-go` away.
* i recommend backing up your ship periodically. i might add a module in here to pull it to s3 at
  some interval. you can also do a `make fetch-ship` and persist a copy locally.
* terraform.tfvars is like a cache of your `config.mk` configuration. It's so you can step into
  those directories and run make commands in there for greater control. The downside to this
approach is that, if the configuration changes, you might need to regenerate the terraform.tfvars
files. It should totally regenerate on its own, but nothing is perfect. So you can fix it with:
```
make -B aws-ship-terraform.tfvars
make -B aws-infra-terraform.tfvars
```
* if you wanna tear the whole thing out, do this:
```
make fetch-ship
make aws-ship-destroy
make aws-infra-destroy
```

### Questions
if you have them, open an issue and maybe i'll take a look. no promises. :)

## TODOs
* expose the ames-port as a top-level parameter. it's currently assumed to be something, but it really should be configurable.
* there's an existing urbit ACME flow that can expose your planet at `sampel-palnet.arvo.network` so no reason not to do that also. or maybe even give an option to do that instead of using a custom url.
* use a data.external to create the ssh key if it's not there already. just generally, i can make that little chunk of code a little cleaner.
* encrypt the EBS volume, or consider migrating to EFS which is maybe a better fit

