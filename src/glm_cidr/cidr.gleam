import gleam/string
import glm_cidr/constants.{
  address_not_contained_in_subnet_error, malformed_address_string,
  subnet_full_error,
}
import glm_cidr/errors.{type CIDRError, AddressError}
import glm_cidr/internal/cidr_private.{
  parse_ipv4_subnet, parse_ipv6_subnet, subnet_contains_address,
}
import glm_cidr/types.{
  type InetAddress, type Subnet, Ipv4InetAddress, Ipv6InetAddress,
}

// -------------------------------------------------------------------------------
// public api
// -------------------------------------------------------------------------------

// NOTE: ipv6 is not yet implemented

/// parse an address string and return the subnet
pub fn parse(address: String, mask: Int) -> Result(Subnet, CIDRError) {
  case address |> string.contains(":"), address |> string.contains(".") {
    True, False -> parse_ipv6_subnet(address, mask)
    False, True -> parse_ipv4_subnet(address, mask)
    _, _ ->
      Error(AddressError(malformed_address_string <> ", address: " <> address))
  }
}

/// given a subnet and an address, parse the address and return True
/// if the address is contained by the subnet, otherwise return False
pub fn contains(subnet: Subnet, address: String) -> Result(Bool, CIDRError) {
  case cidr_private.contains(subnet, address) {
    Error(e) -> Error(e)
    Ok(tuple) -> {
      let #(v, _) = tuple
      // stripp the inet address off
      Ok(v)
    }
  }
}

/// given a subnet and an address, parse the address and return the next
/// address within that subnet, or an error if there are no more addresses in that subnet
pub fn next(subnet: Subnet, address: String) -> Result(InetAddress, CIDRError) {
  case cidr_private.contains(subnet, address) {
    Error(e) -> Error(e)
    Ok(tuple) -> {
      let #(contains, inet_address) = tuple
      case contains {
        False -> Error(AddressError(address_not_contained_in_subnet_error))
        True -> {
          case inet_address {
            Ipv6InetAddress(address:) -> {
              let next_address = Ipv6InetAddress(address + 1)
              case subnet_contains_address(subnet, next_address) {
                Error(e) -> Error(e)
                Ok(False) ->
                  Error(AddressError(
                    subnet_full_error <> string.inspect(next_address),
                  ))
                Ok(True) -> Ok(next_address)
              }
            }
            Ipv4InetAddress(address:) -> {
              let next_address = Ipv4InetAddress(address + 1)
              case subnet_contains_address(subnet, next_address) {
                Error(e) -> Error(e)
                Ok(False) ->
                  Error(AddressError(
                    subnet_full_error <> string.inspect(next_address),
                  ))
                Ok(True) -> Ok(next_address)
              }
            }
          }
        }
      }
    }
  }
}
