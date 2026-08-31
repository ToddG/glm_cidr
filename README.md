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

See tests for how to use.

Further documentation can be found at <https://hexdocs.pm/glm_cidr>.

## Development

```sh
gleam check # Check the project
gleam test  # Run the tests
```
