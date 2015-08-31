# Overview

Create a 3 node Marathon / Mesos cluster with a single master node and 2 slave nodes. Two environments are currently supported.

* Vagrant    - 3 local VMs running CoreOS on VirtualBox or VMware Fusion.
* Packet.net - 3 physical servers running CoreOS. You need an account with [Packet.net](https://packet.net) to do this.

## Vagrant Setup

1) Install dependencies

* [VirtualBox](https://www.virtualbox.org/) 4.3.10 or greater.
* [Vagrant](https://www.vagrantup.com/downloads.html) 1.6 or greater.

2) Clone this project.

```
$ git clone https://github.com/force12/coreos-marathon/
$ cd coreos-marathon
```

3) Startup and SSH

Boxes are named core-01..03.

```
$ vagrant up
$ vagrant ssh core-01
```

4) Access web UIs

Once all the Docker images have been downloaded and started the web UIs will be availabled at.
Note: This can take up to 10 minutes and the images themselves are large.

* Marathon: http://172.17.8.101:8080
* Mesos: http://172.17.8.101:5050

## Vagrant Teardown

1) Delete Vagrant VMs.

```
vagrant destroy
```

## Packet Setup

1) Register for an account with [Packet](https://packet.net).

2) Clone this project.

```
$ git clone https://github.com/force12/coreos-marathon/
$ cd coreos-marathon
```

3) Set API key and config.

```
# .env.packet

API_TOKEN=YOUR_API_KEY
PROJECT_NAME=example
DEVICE_PREFIX=core
PLAN=baremetal_1
# Parsippany, NJ
FACILITY=ewr1
# Either coreos_beta or coreos_alpha
OPERATING_SYSTEM=coreos_beta
```

4) Start cluster of 3 physical servers running CoreOS beta.

```
$ cp .env.packet .env

$ bundle install
$ bundle exec rake packet:cluster:create

Cluster is being provisioned
```

5) Check status of the console in the Packet web UI. Once all 3 servers are provisioned
get the public IP address of the core-01 node. The Marathon web UI is available on port 8080 and Mesos web UI is on port 5050.

## Packet Teardown

1) Shutdown server cluster.

```
$ bundle exec rake packet:cluster:destroy

Cluster has been shutdown
```

### Bootstrapping

* A fresh discovery token is retrieved from discovery.etcd.io for each cluster.
* CoreOS cloud-config starts etcd2 and fleet and a oneshot unit that starts the cluster.
* A 3 node Consul cluster is bootstrapped using the etcd cluster.
* Zookeeper is registered with Consul and accessed via the Consul DNS interface.
* Mesos and Marathon use Zookeeper for service discovery.

## Docker Image

The oneshot unit launches a Docker container using the image [quay.io/rossf7/coreos-marathon:latest](https://quay.io/repository/rossf7/coreos-marathon).
This image is based on Alpine Linux and installs Ruby and the fleetctl binary. The container runs a Ruby script that starts the cluster using fleet.

## Thanks

Thanks to [Packet](https://www.packet.net/) for the great support while we automated the cluster setup.

This template is based upon these projects.

* [coreos-vagrant](https://github.com/coreos/coreos-vagrant) - Vagrant template and boxes provided by CoreOS.
* [consul-coreos](https://github.com/democracyworks/consul-coreos) - bootstraps a Consul cluster using etcd2.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This code is licensed under the [MIT license](LICENSE).
