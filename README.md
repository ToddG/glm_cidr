# glm_cidr

[![Package Version](https://img.shields.io/hexpm/v/glm_cidr)](https://hex.pm/packages/glm_cidr)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glm_cidr/)

This is a simple library to assist with answering these basic questions:

* Is a given ip address in a given subnet?
* What is the next usable address in a given subnet, after a given address?
* How many usable addresses are in a given subnet?

I'm sure there are other interesting questions related to cidr.

Feel free to fork and/or submit PR's for additional functionality.

```sh
gleam add glm_cidr
use subnet <- result.try(cidr.subnet_from_string("10.0.0.0/24"))
use metadata <- result.try(cidr.metadata(subnet))

// returns metadata like this:
//
// -> cidr.SubnetMetadata(
//      network: cidr.Ipv4(10, 0, 0, 0),
//      broadcast: cidr.Ipv4(10, 0, 0, 255),
//      first_host: cidr.Ipv4(10, 0, 0, 1),
//      last_host: cidr.Ipv4(10, 0, 0, 254),
//      usable_hosts: 254,
//      prefix: 24,
//      hex_netmask: "0xFFFFFF00",
//    ),

use next <- result.try(cidr.next_usable(subnet, cidr.Ipv4(10,0,0,0)))

// returns the next usable ip address:
//
// -> cidr.Ipv4(10, 0, 0, 1)

```

See tests and docs for further details on how to use.

Documentation can be found at <https://hexdocs.pm/glm_cidr>.

## Development

```sh
make
```
