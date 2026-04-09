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
```
```gleam
import glm_cidr as cidr

pub fn main() -> Nil {
  let subnet = cidr.subnet("10.0.0.1/24")
  let relation = cidr.relationship(subnet, "10.0.0.66")
  /// -> Ok(AddressIsInsideSubnet(next: 10.0.0.67, subnet_metadata: { first: 10.0.0.1, last: 10.0.0.255, count: 254 } )
}
```

Further documentation can be found at <https://hexdocs.pm/glm_cidr>.

## Development

```sh
gleam check # Check the project
gleam test  # Run the tests
```