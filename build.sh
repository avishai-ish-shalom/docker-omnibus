#!/bin/bash

docker pull centos:centos6
packer build -var base_image=centos:centos6 -var output_repository=omnibus/centos-6 -var output_tag=latest centos-packer.json
docker pull centos:centos7
packer build -var base_image=centos:centos7 -var output_repository=omnibus/centos-7 -var output_tag=latest centos-packer.json
docker pull ubuntu:precise
packer build -var base_image=ubuntu:precise -var output_repository=omnibus/ubuntu-precise -var output_tag=latest ubuntu-packer.json
docker pull debian:wheezy
packer build -var base_image=debian:wheezy -var output_repository=omnibus/debian-wheezy -var output_tag=latest ubuntu-packer.json
