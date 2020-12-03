What is Packer
==============

Packer is an open source tool for creating identical machine images for multiple platforms from a single source configuration. Packer is lightweight, runs on every major operating system, and is highly performant, creating machine images for multiple platforms in parallel. Packer does not replace configuration management like Chef or Puppet. In fact, when building images, Packer is able to use tools like Chef or Puppet to install software onto the image.

A machine image is a single static unit that contains a pre-configured operating system and installed software which is used to quickly create new running machines. Machine image formats change for each platform. Some examples include AMIs for EC2, VMDK/VMX files for VMware, OVF exports for VirtualBox, etc.

More information: [https://www.packer.io/intro]

Centreon Packer tools
---------------------

This repository contains a series of codes ready to create a complete and configured image of the Centreon environment for various versions using the Packer tool.

Usage
-----

```bash
$ make help
Usage:
  make <target>

Targets:
  18.10                          Build Centreon 18.10
  19.04                          Build Centreon 19.04
  19.04-centos                   Build Centreon 19.04 over Centos ISO
  19.10                          Build Centreon OSS 19.10 over Centos ISO
  20.04                          Build Centreon OSS 20.04 over Centos ISO
  20.10                          Build Centreon OSS 20.10 over Centos ISO
  last                           Build last version available (20.10)

```
