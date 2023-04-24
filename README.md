# BenchFaster

BenchFaster automates the deployment and benchmarking of containerized
applications over emulated wide area networks. 


## Overview

<img src="stack.png" alt= “stack” width="700">

BenchFaster consist on four type of nodes:

- Ansible control node: A system from where one or more instances of BenchFaster are
  launched. Components:
  
  - Ansible
  
- Tester node: A remote host from where BenchFaster deployment is launched and the
  performance tests are run. Components:

  - BenchFaster
  - Load testing tool: JMeter, k6

- Head node: A remote host where all the core components of BenchFaster are
  deployed. Components: 

  - Container orchestrator: K3s (master)
  - Serverless framework: OpenFaaS
  - Overlay network (discovery server): Nebula lighthouse

- Worker node: A remote host where serverless functions are deployed.
  Components: 

  - Container orchestrator: K3s (worker node)
  - Serverless functions: OpenFaaS functions ([examples](https://github.com/fcarp10/openfaas-functions))
  - Overlay network (client): Nebula host


## Prerequisites

- `ansible` in the control node.
- SSH access to all nodes.
- Ubuntu Server 22.04 or Arch Linux.
- (Optional) Local container [registry](https://docs.docker.com/registry/deploying/)


## Operation modes

Two operation modes are possible in BenchFaster:

- Hosts mode: Head and worker nodes are remote systems.

- Hypervisor mode: Head and workers nodes are deployed on VMs libvirt/KVM.


## Inventory

Modify the existing ansible `inventory.yml` file or create a new one with the
list of all hosts. Three categories of devices are expected: `hypervisors`,
`machines` and `testers`. The most relevant parameters are:

Common for all type of nodes:
- `ansible_host`: Name of the host to connect from the ansible control node.
- `ansible_user`: User name to connect
- `interface`: Network interface

Head node:
- `num_workers`: Number of expected workers in the cluster 
- `openfaas_functions`: List of OpenbFaaS functions
- `address_benchmark`: Name of the host where to run the performance tests
  against

Hypervisor specific:

- `vm_cpu`: Number of CPUs units per VM
- `vm_mem`: Amount of RAM per VM
- `vm_image`: Name of the Vagrant box


## Install Requirements

Install the requirements for each type of node with:

```shell
ansible-playbook --ask-become-pass -i inventory.yml requirements/${REQ_FILE}.yml
```
where `REQ_FILE` is either `machine`, `tester` or `hypervisor`.


## Run hello-world test

Run a hello-world test with:

```shell
ansible-playbook -i inventory.yml helloworld.yml
```

When using a hypervisor, add `--extra-vars "hvm=true"` to the previous command.
