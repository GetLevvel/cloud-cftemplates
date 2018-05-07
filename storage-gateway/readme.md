# Storage Gateway and Disaster Recovery Template

## Introduction

The purpose of this project is to create a basic storage gateway configuration with a simulated host environment and gateway using CloudFormation. Optionally, a disaster recovery environment may be used to demonstrate how the Storage Gateway may be used for both a backup and DR solution.

## Scenario 1 - Cached Volume Gateway

Steps to get started:
* **Create EC2 Keys** - Create a set of EC2Keys to be used for the scenario in the AWS us-west-2 Region
* **Clone Repo** - Clone the repository locally
* **Execute Script** - run ./build-environment.sh to build out the environment

Shell arguments:
```
-n = Stack name, just use your initials, example: cmm
-s = Key name in us-west 2, example: cmm-west-2

Example execution: ./build-environment.sh -n cmm -s cmm-west-2
```


### What is created

The following artifacts are created in AWS:

* a VPC in us-west-2
* A Windows 7 image in us-west-2
* A Linux image in us-west-2 (Storage Gateway)
* A Storage Gateway service in us-east-1
