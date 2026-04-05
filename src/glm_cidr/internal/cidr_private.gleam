import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glm_cidr/constants.{
  ipv4_address_element_parse_error, ipv4_invalid_address_error,
  ipv4_large_address_element_error, ipv4_max_address_element_value,
  ipv4_negative_address_element_error, ipv6_address_element_parse_error,
  ipv6_invalid_address_error, ipv6_large_address_element_error,
  ipv6_max_address_element_value, ipv6_negative_address_element_error,
  mismatched_subnet_and_address_error,malformed_address_string
}
import glm_cidr/errors.{type CIDRError, AddressError, NotYetImplemented}
import glm_cidr/mask
import glm_cidr/types.{
  type InetAddress, type InetAddressElement, type Subnet, Ipv4InetAddress,
  Ipv4InetAddressElement, Ipv4Subnet, Ipv6InetAddress, Ipv6Subnet,
}

pub fn subnet_contains_address(
  subnet: Subnet,
  target_address: InetAddress,
) -> Result(Bool, CIDRError) {
  case subnet, target_address {
    Ipv6Subnet(_, _, _, _, _), Ipv6InetAddress(_) -> {
      let subnet_network =
        int.bitwise_and(subnet.address.address, subnet.mask |> mask.mask_to_int)
      let target_network =
        int.bitwise_and(target_address.address, subnet.mask |> mask.mask_to_int)
      Ok(subnet_network == target_network)
    }
    Ipv4Subnet(_, _, _, _, _), Ipv4InetAddress(_) -> {
      let subnet_network =
        int.bitwise_and(subnet.address.address, subnet.mask |> mask.mask_to_int)
      let target_network =
        int.bitwise_and(target_address.address, subnet.mask |> mask.mask_to_int)
      Ok(subnet_network == target_network)
    }
    _, _ -> Error(AddressError(mismatched_subnet_and_address_error))
  }
}

/// given a subnet and an address, parse the address and return a tuple of #(True, InetAddress)
/// if the address is contained by the subnet, otherwise return #(False, InetAddress)
pub fn contains(
subnet: Subnet,
address: String,
) -> Result(#(Bool, InetAddress), CIDRError) {
  case address |> string.contains(":"), address |> string.contains(".") {
    True, False -> parse_ipv6_address(address)
    False, True -> parse_ipv4_address(address)
    _, _ ->
    Error(AddressError(malformed_address_string <> ", address: " <> address))
  }
  |> result.try(fn(inet_address) {
    case subnet_contains_address(subnet, inet_address) {
      Error(e) -> Error(e)
      Ok(value) -> Ok(#(value, inet_address))
    }
  })
}


// -------------------------------------------------------------------------------
// ipv4
// -------------------------------------------------------------------------------
pub fn parse_ipv4_subnet(
  address: String,
  num_bits: Int,
) -> Result(Subnet, CIDRError) {
  let ipv4_address = parse_ipv4_address(address)
  let ipv4_mask = mask.ipv4_mask_from_int(num_bits)

  case ipv4_address, ipv4_mask {
    Ok(valid_ipv4_address), Ok(valid_ipv4_mask) -> {
      case valid_addresses(valid_ipv4_address, valid_ipv4_mask) {
        Error(e) -> Error(e)
        Ok(tuple) -> {
          let #(first, last, count) = tuple
          Ok(Ipv4Subnet(
            valid_ipv4_address,
            valid_ipv4_mask,
            first:,
            last:,
            count:,
          ))
        }
      }
    }
    Error(e), _ -> Error(e)
    _, Error(e) -> Error(e)
  }
}

pub fn valid_addresses(
  address: InetAddress,
  opaque_mask: mask.Mask,
) -> Result(#(InetAddress, InetAddress, Int), CIDRError) {
  let assert Ok(mask_32_bits) =
  mask.ipv4_mask_from_int(32) |> result.map(mask.mask_to_int)
  let assert Ok(mask_31_bits) =
  mask.ipv4_mask_from_int(31) |> result.map(mask.mask_to_int)
  case address {
    Ipv6InetAddress(_address) -> {
      Error(NotYetImplemented(
        "TODO: implement address stuff for ipv6, see page 384 of The TCP/IP Guide",
      ))
    }
    Ipv4InetAddress(address:) -> {
      case opaque_mask |> mask.mask_to_int {
        // single host -> return one address
        mask if mask == mask_32_bits ->
          Ok(#(Ipv4InetAddress(address), Ipv4InetAddress(address), 1))
        // point-to-point link -> return two addresses
        mask if mask == mask_31_bits -> {
          let inverse_mask = int.bitwise_exclusive_or(mask, mask_32_bits)
          let ppl_address_1 = int.bitwise_and(address, mask)
          // address with last bit zero
          let ppl_address_2 = int.bitwise_or(address, inverse_mask)
          // address withlast bit one
          Ok(#(
            Ipv4InetAddress(ppl_address_1),
            Ipv4InetAddress(ppl_address_2),
            2,
          ))
        }
        // all others subtract the network and broadcast addresses from the address range
        mask -> {
          let network_address = int.bitwise_and(address, mask)
          let inverse_mask = int.bitwise_exclusive_or(mask, mask_32_bits)
          let broadcast_address = int.bitwise_or(network_address, inverse_mask)
          let first_address = network_address + 1
          let last_address = broadcast_address - 1
          Ok(#(
            Ipv4InetAddress(first_address),
            Ipv4InetAddress(last_address),
            inverse_mask - 1,
          ))
        }
      }
    }
  }
}

pub fn parse_ipv4_address(address: String) -> Result(InetAddress, CIDRError) {
  let address_list = address |> string.split(".")
  case address_list, list.length(address_list) {
    l, 4 -> {
      case ipv4_address(l, 0, 0) {
        Error(e) -> Error(e)
        Ok(valid_ipv4_address) -> Ok(valid_ipv4_address)
      }
    }
    invalid_address, count ->
      Error(AddressError(
        ipv4_invalid_address_error
        <> string.inspect(invalid_address)
        <> ", count: "
        <> count |> int.to_string,
      ))
  }
}

pub fn ipv4_address(
  elements: List(String),
  accum: Int,
  bits: Int,
) -> Result(InetAddress, CIDRError) {
  case elements {
    [] -> Ok(Ipv4InetAddress(accum))
    [h, ..rest] -> {
      h
      |> ipv4_address_element
      |> result.try(fn(e) {
        ipv4_address(
          rest,
          int.bitwise_shift_left(accum, 8) + e.address,
          bits + 8,
        )
      })
    }
  }
}

pub fn ipv4_address_element(
  element: String,
) -> Result(InetAddressElement, CIDRError) {
  case int.base_parse(element, 10) {
    Error(e) ->
      Error(AddressError(ipv4_address_element_parse_error <> string.inspect(e)))
    Ok(value) -> {
      case value {
        value if value < 0 ->
          Error(AddressError(ipv4_negative_address_element_error))
        value if value > ipv4_max_address_element_value ->
          Error(AddressError(ipv4_large_address_element_error))
        value -> Ok(Ipv4InetAddressElement(value))
      }
    }
  }
}

// -------------------------------------------------------------------------------
// ipv6
// -------------------------------------------------------------------------------
pub fn parse_ipv6_subnet(
  address: String,
  num_bits: Int,
) -> Result(Subnet, CIDRError) {
  let ipv6_address = parse_ipv6_address(address)
  let ipv6_mask = mask.ipv6_mask_from_int(num_bits)

  case ipv6_address, ipv6_mask {
    Ok(valid_ipv6_address), Ok(valid_ipv6_mask) -> {
      case valid_addresses(valid_ipv6_address, valid_ipv6_mask) {
        Error(e) -> Error(e)
        Ok(tuple) -> {
          let #(first, last, count) = tuple
          Ok(Ipv6Subnet(
            valid_ipv6_address,
            valid_ipv6_mask,
            first:,
            last:,
            count:,
          ))
        }
      }
    }
    Error(e), _ -> Error(e)
    _, Error(e) -> Error(e)
  }
}

pub fn parse_ipv6_address(address: String) -> Result(InetAddress, CIDRError) {
  let address_list = address |> string.split(":")
  case address_list {
    l -> {
      case list.length(l) {
        8 -> {
          case ipv6_address(l, 0, 0) {
            Error(e) -> Error(e)
            Ok(valid_ipv6_address) -> Ok(valid_ipv6_address)
          }
        }
        count ->
          Error(AddressError(
            ipv6_invalid_address_error <> count |> int.to_string,
          ))
      }
    }
  }
}

pub fn ipv6_address(
  elements: List(String),
  accum: Int,
  bits: Int,
) -> Result(InetAddress, CIDRError) {
  case elements {
    [] -> Ok(Ipv4InetAddress(accum))
    [h, ..rest] -> {
      h
      |> ipv6_address_element
      |> result.try(fn(e) {
        ipv6_address(
          rest,
          int.bitwise_shift_left(accum, 16) + e.address,
          bits + 16,
        )
      })
    }
  }
}

pub fn ipv6_address_element(
  element: String,
) -> Result(InetAddressElement, CIDRError) {
  //  enable compressed addresses
  let element = case element {
    "" -> "0"
    e -> e
  }
  case int.base_parse(element, 16) {
    Error(e) ->
      Error(AddressError(ipv6_address_element_parse_error <> string.inspect(e)))
    Ok(value) -> {
      case value {
        value if value < 0 ->
          Error(AddressError(ipv6_negative_address_element_error))
        value if value > ipv6_max_address_element_value ->
          Error(AddressError(ipv6_large_address_element_error))
        value -> Ok(Ipv4InetAddressElement(value))
      }
    }
  }
}
