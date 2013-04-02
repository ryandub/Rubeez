Rubeez
======

Ruby utility for creating Rackspace Cloud Servers and using them to generate HTTP traffic to a specified host. Based on the idea from [Bees With Machine Guns](https://github.com/newsapps/beeswithmachineguns).

This is still very much a work-in-progress, so expect some rough edges and terrible error handling.

## Installation
### Vagrant
The easiest way to start using ```Rubeez``` is by using [vagrant](http://docs.vagrantup.com/v2/getting-started/index.html). From the Rubeez repository, type ```vagrant up```. Once the VM is finished booting, type ```vagrant ssh``` to login to the VM. From there, follow the usage instructions to start using ```Rubeez```.

### Build Gem from Source
If you don't want to use vagrant or want to use ```Rubeez``` from your local machine, building the gem from source is pretty simple. From the ```Rubeez``` repository type the following:

```
gem build rubeez.gemspec
gem install rubeez-0.1.gem
```

This will install the ```Rubeez``` gem and any necessary dependencies.

## Usage
```
    -k, --apikey APIKEY              Rackspace Cloud APIKEY (required)
        --attack                     Attack URL designated by --url
    -b, --beez NUMBER_OF_BEEZ        Number of beez (servers) to create
    -c, --concurrency [CONCURRENCY]  Number of concurrent connections each bee will use.
        --kill                       Kill the entire swarm
    -r, --region REGION              Region to deploy into (dfw, ord, lon)
    -q, --requests [REQUESTS]        Number of requests each bee will make.
    -s, --status                     Show swarm status
        --url [URL]                  URL to attack
    -u, --username USERNAME          Rackspace Cloud Username (required)
```

For example, if you wanted to launch a swarm of 10 beez:

```
rubeez -u [USERNAME] -k [APIKEY] -b 10
```
Check status while beez build:

```
rubeez -u [USERNAME] -k [APIKEY] -s
```

Issue an attack command to the swarm:

```
rubeez -u [USERNAME] -k [APIKEY] --attack --url http://example.com/

```
Results:

```
[2013-04-02T09:30:34+00:00] INFO: Attacking http://example.com/ with the following command:
[2013-04-02T09:30:34+00:00] INFO: ab -e /tmp/rubeez.out -r -n 100 -c 10 -C 'sessionid=SomeSessionID'  'http://example.com/'
[2013-04-02T09:30:34+00:00] INFO: If this is your first attack with this swarm, it may take a few minutes before starting
[2013-04-02T09:30:38+00:00] INFO: rubeez-worker-n6: Completed Attack
[2013-04-02T09:30:38+00:00] INFO: rubeez-worker-n4: Completed Attack
[2013-04-02T09:30:38+00:00] INFO: rubeez-worker-n5: Completed Attack
[2013-04-02T09:30:38+00:00] INFO: rubeez-worker-n0: Completed Attack
[2013-04-02T09:30:38+00:00] INFO: rubeez-worker-n3: Completed Attack
[2013-04-02T09:30:38+00:00] INFO: rubeez-worker-n1: Completed Attack
[2013-04-02T09:30:38+00:00] INFO: rubeez-worker-n2: Completed Attack
[2013-04-02T09:30:40+00:00] INFO: Results averaged across the entire swarm:
[2013-04-02T09:30:40+00:00] INFO:
+--------------------------------+
| percentage_served | time_in_ms |
+--------------------------------+
| 0                 |    86.4616 |
| 1                 |    91.3387 |
| 2                 |    93.6229 |
| 3                 |   100.7133 |
| 4                 |   102.4794 |
| 5                 |   109.9067 |
| 6                 |    126.342 |
| 7                 |   136.4471 |
| 8                 |     143.18 |
| 9                 |   145.8517 |
| 10                |    147.688 |
| 11                |   149.1586 |
| 12                |   154.1663 |
| 13                |   161.4649 |
| 14                |   164.2161 |
| 15                |   166.9187 |
| 16                |   170.0076 |
| 17                |   171.5097 |
| 18                |   173.8314 |
| 19                |   176.3294 |
| 20                |   177.4619 |
| 21                |   178.9223 |
| 22                |   180.3234 |
| 23                |     182.56 |
| 24                |   184.1169 |
| 25                |   185.4341 |
| 26                |    187.051 |
| 27                |    187.681 |
| 28                |   189.1819 |
| 29                |   190.9323 |
| 30                |   193.6457 |
| 31                |   195.5391 |
| 32                |   200.5336 |
| 33                |   204.0676 |
| 34                |    211.087 |
| 35                |   213.0233 |
| 36                |   214.4826 |
| 37                |   221.1199 |
| 38                |   224.9361 |
| 39                |   231.9241 |
| 40                |   233.7111 |
| 41                |   235.5519 |
| 42                |   237.0363 |
| 43                |   239.3014 |
| 44                |   240.7333 |
| 45                |   241.9371 |
| 46                |    244.542 |
| 47                |    247.941 |
| 48                |   250.0316 |
| 49                |   252.1181 |
| 50                |   254.6971 |
| 51                |   257.9414 |
| 52                |   262.4321 |
| 53                |   264.3691 |
| 54                |   272.4621 |
| 55                |   273.7351 |
| 56                |   277.2654 |
| 57                |   280.5273 |
| 58                |   285.2021 |
| 59                |   286.7317 |
| 60                |   289.0219 |
| 61                |   294.9449 |
| 62                |   297.0733 |
| 63                |   299.5963 |
| 64                |   305.7287 |
| 65                |   309.7787 |
| 66                |   313.4466 |
| 67                |   317.4957 |
| 68                |   319.0389 |
| 69                |   323.7811 |
| 70                |   326.9001 |
| 71                |   328.6583 |
| 72                |    330.476 |
| 73                |   333.2973 |
| 74                |   338.0079 |
| 75                |   345.3703 |
| 76                |   347.9284 |
| 77                |   350.6577 |
| 78                |   355.8221 |
| 79                |   359.9327 |
| 80                |    364.764 |
| 81                |   368.5699 |
| 82                |    377.289 |
| 83                |   384.4511 |
| 84                |   395.9741 |
| 85                |   397.8344 |
| 86                |   402.6551 |
| 87                |   424.4676 |
| 88                |   432.4786 |
| 89                |   448.9931 |
| 90                |   465.8007 |
| 91                |   489.4371 |
| 92                |   504.6717 |
| 93                |   517.1774 |
| 94                |   526.7933 |
| 95                |   537.1543 |
| 96                |   661.5807 |
| 97                |   693.5109 |
| 98                |   831.2337 |
| 99                |   858.3606 |
+--------------------------------+
```
When you are done, run ```rubeez -u [USERNAME] -k [APIKEY] --kill``` to kill the entire swarm.