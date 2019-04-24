# CloudFormation Templates

## Introduction

The purpose of this repository is to maintain a set of reusable CloudFormation templates for the Cloud team.

## Available templates

* **[Storage Gateway w/DR](storage-gateway/readme.md)** - Creates a storage gateway with an optional DR environment
* **[EKS Simple Starter](eks/README.md)** - A simple EKS cluster with two Node Groups
* **[S3 Simple Website](s3/simple-website.yml)** - A simple S3-hosted website
* **[S3 HTTPS-Enabled Website](s3/https-website.yml)** - An SSL-enabled website with optional CloudFront CDN
* **[KMS Encryption Key](secrets/kms.yml)** - Creates a KMS Key for secrets encryption/decryption with a dedicated IAM role to assign for decryption
