#!/bin/bash

docker pull centos:centos6
packer build -var base_image=centos:centos6 -var output_repository=omnibus/centos -var output_tag=6 centos-packer.json
docker pull centos:centos7
packer build -var base_image=centos:centos7 -var output_repository=omnibus/centos -var output_tag=7 centos-packer.json
docker pull ubuntu:precise
packer build -var base_image=ubuntu:precise -var output_repository=omnibus/ubuntu -var output_tag=precise ubuntu-packer.json
docker pull debian:wheezy
packer build -var base_image=debian:wheezy -var output_repository=omnibus/ubuntu -var output_tag=wheezy ubuntu-packer.json
