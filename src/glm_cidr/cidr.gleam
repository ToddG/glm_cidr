import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

/// IP Address
pub type IpAddress {
  /// The IPV4 representation of an IP Address (4 8 bit integers)
  Ipv4(a: Int, b: Int, c: Int, d: Int)
  /// The IPV6 representation of an IP Address (8 16 bit integers)
  Ipv6(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int)
}

/// The mask to apply to an IP Address to differentiate the network from the host address.
pub type NetMask {
  /// A 32 bit integer value
  Ipv4NetMask(mask: Int)
  /// A 128 bit integer value
  Ipv6NetMask(mask: Int)
}

/// A subnet defines a network using an IP Address and a NetMask
pub type Subnet {
  /// An IPV4 Subnet has 32 bits for the network and host address
  Ipv4Subnet(address: IpAddress, netmask: NetMask)
  /// An IPV6 Subnet has 128 bits for the network and host address
  Ipv6Subnet(address: IpAddress, netmask: NetMask)
}

/// We can derive useful information about a subnet from the subnet itself
pub type SubnetMetadata {
  /// SubnetMetadata about the usable addresses. By usable addresses, we mean the addresses that
  /// are not already allocated by the networking system, e.g. the network address and the broadcast address.
  ///
  /// Special cases:
  ///   IPV4 /32 -> single host           -> 1 address
  ///   IPV4 /31 -> point-to-point link   -> 2 addresses
  SubnetMetadata(
    /// Every subnet has a first usable address (which might be the same as the last address)
    first: IpAddress,
    /// Every subnet has a last usable address (which might be the same as the first address)
    last: IpAddress,
    /// Every subnet has a count of the usable addresses
    count: Int,
  )
}

/// Parse errors are any error encontered while trying to parse user input into a subnet.
pub type ParseError {
  /// Unknown (default) Parse Error when we don't know what happened
  UnknownParseError
  /// Parse failed and fallback(s) also failed
  ParseErrors(errors: List(ParseError))
  /// Failed to split the address from the mask, probably missing the "/" separator
  SplitAddressFromMaskParseError
  /// The net mask is probably not parsing to an integer
  MaskParseError(Nil)
  /// The net mask can be <= 128 for ipv6, and <= 32 for  ipv4
  MaskTooLargeParseError(value: Int)
  /// The mask must be > 0
  MaskTooSmallParseError(value: Int)
  /// After splitting the address on ":" for ipv6 or "." for ipv4, there are too many strings
  AddressTooManyComponentsParseError(count: Int)
  /// After splitting the address on ":" for ipv6 or "." for ipv4, there are too few strings
  AddressTooFewComponentsParseError(count: Int)
  /// Parsing the hex string failed, max length 4 characters
  AddressComponentStringToIntParseError(s: String)
  /// Addresses must be between 0 and 2**16 for ipv6 or 0 and 2**8 for ipv4
  AddressComponentValueTooSmallParseError(value: Int)
  /// Addresses must be between 0 and 2**16 for ipv6 or 0 and 2**8 for ipv4
  AddressComponentValueTooLargeParseError(value: Int)
}

/// IPV6 num_bits (128)
const ipv6_num_bits = 128

/// IPV6 address components are 16 bit (2**16)
const max_ipv6_address_component = 65_536

/// IPV6 address has 8 components
const ipv6_num_components = 8

/// IPV6 address component separator
const ipv6_component_separator = ":"

/// IPV6 number of characters in a component
const ipv6_num_component_characters = 4

/// IPV4 num_bits (32)
const ipv4_num_bits = 32

/// IPV4 address components are 8 bit (2**8)
const max_ipv4_address_component = 256

/// IPV4 address has 4 components
const ipv4_num_components = 4

/// IPV4 address component separator
const ipv4_component_separator = "."

/// IPV4 number of characters in a component
const ipv4_num_component_characters = 2

/// Parse a string with the address and mask delimited with a slash "/".
///
/// ## Examples
///
/// ```gleam
/// subnet("10.0.0.1/24")
/// -> Ok(IPV4 SUBNET)
/// subnet(":::::::1/128")
/// -> Ok(IPV6 SUBNET)
/// ```
///
pub fn subnet(s: String) -> Result(Subnet, ParseError) {
  case s |> string.split_once(on: "/") {
    Error(_) -> Error(SplitAddressFromMaskParseError)
    Ok(#(a, b)) -> parse_address_and_mask_strings(a, b)
  }
}

// ==================================================================
// PRIVATE FUNCTIONS
// ==================================================================

/// Try to parse an IPV4 address and mask. Return the corresponding IPV4 subnet if the parsing succeeds.
/// If parsing an IPV4 subnet fails, then try to parse an IPV6 address and mask. Return the corresponding
/// IPV6 subnet if the parsing succeeds. If both parsing attempts fail, then returns both ParseErrors.
///
/// NOTE: this means that in the error case, you'll get an error for IPV4 **and for IPV6, even though you
/// are only trying to parse one or the other. However, the parsing will fail for both, and so both errors
/// are returned.
fn parse_address_and_mask_strings(
  address: String,
  mask_length: String,
) -> Result(Subnet, ParseError) {
  result.try_recover(parse_ipv4(address, mask_length), fn(ipv4_parse_error) {
    case parse_ipv6(address, mask_length) {
      Ok(subnet) -> Ok(subnet)
      Error(ipv6_parse_error) ->
        Error(ParseErrors([ipv4_parse_error, ipv6_parse_error]))
    }
  })
}


// ------------------------------------------------------------------
// internal ipv6 functions
// ------------------------------------------------------------------

/// parse an ipv6 address and mask
fn parse_ipv6(
  address: String,
  mask_length: String,
) -> Result(Subnet, ParseError) {
  parse_ipv6_subnet(
    parse_ipv6_address_string(address),
    parse_ipv6_mask_string(mask_length),
  )
}

/// parse an ipv6 mask. valid values are 1 to 128.
///
fn parse_ipv6_mask_string(count: String) -> Result(NetMask, ParseError) {
  count
  |> int.parse
  |> result.map_error(MaskParseError)
  |> result.try(fn(bits) {
    case bits {
      b if b <= 0 -> Error(MaskTooSmallParseError(b))
      b if b > ipv6_num_bits -> Error(MaskTooLargeParseError(b))
      b -> {
        int.power(2, b |> int.to_float)
        |> result.map_error(MaskParseError)
        |> result.map(float.truncate)
        |> result.map(fn(q) { q - 1 })
        |> result.map(int.bitwise_shift_left(_, ipv6_num_bits - b))
        |> result.map(Ipv6NetMask)
      }
    }
  })
}

fn parse_ipv6_address_string(address: String) -> Result(IpAddress, ParseError) {
  let address_list = address |> string.split(ipv6_component_separator)
  let address_list_length = address_list |> list.length
  case address_list_length {
    l if l > ipv6_num_components -> Error(AddressTooManyComponentsParseError(l))
    l if l < ipv6_num_components -> Error(AddressTooFewComponentsParseError(l))
    _ -> parse_ipv6_address_string_components(address_list)
  }
}

fn parse_ipv6_address_string_components(
  ipv6_addresses: List(String),
) -> Result(IpAddress, ParseError) {
  case
    ipv6_addresses
    |> list.map(parse_ipv6_address_component_string)
    |> list.partition(result.is_error)
  {
    #([], results) ->
      results |> list.filter_map(fn(x) { x }) |> new_ipv6address
    #(errors, _) ->
      errors
      |> list.map(fn(x) {
        result.unwrap_error(x, or: UnknownParseError)
      })
      |> ParseErrors
      |> Error
  }
}

fn new_ipv6address(components: List(Int)) -> Result(IpAddress, ParseError) {
  let list_length = components |> list.length
  case components, list_length{
    [a, b, c, d, e, f, g, h], _ -> Ok(Ipv6(a, b, c, d, e, f, g, h))
    _, l if l > ipv6_num_components -> Error(AddressTooManyComponentsParseError(l))
    _, l if l < ipv6_num_components -> Error(AddressTooFewComponentsParseError(l))
    _, _ -> Error(UnknownParseError)
  }
}

fn parse_ipv6_address_component_string(
  component: String,
) -> Result(Int, ParseError) {
  case component {
    "" -> Ok(0)
    _ -> {
      component
      |> int.base_parse(16)
      |> result.map_error(fn(_) {
        AddressComponentStringToIntParseError(
        component |> string.slice(at_index: 0, length: ipv6_num_component_characters),
        )
      })
      |> result.try(fn(v) {
        case v {
          v if v < 0 -> Error(AddressComponentValueTooLargeParseError(v))
          v if v >= max_ipv6_address_component ->
          Error(AddressComponentValueTooLargeParseError(v))
          v -> Ok(v)
        }
      })
    }
  }
}

fn parse_ipv6_subnet(
  address: Result(IpAddress, ParseError),
  mask: Result(NetMask, ParseError),
) -> Result(Subnet, ParseError) {
  case address, mask {
    Ok(a), Ok(b) -> Ok(Ipv6Subnet(a, b))
    Ok(_), Error(e) -> Error(e)
    Error(e), Ok(_) -> Error(e)
    Error(ea), Error(eb) -> Error(ParseErrors([ea, eb]))
  }
}

// ------------------------------------------------------------------
// internal ipv4 functions
// ------------------------------------------------------------------

/// parse an ipv4 address and mask
fn parse_ipv4(
address: String,
mask_length: String,
) -> Result(Subnet, ParseError) {
  parse_ipv4_subnet(
  parse_ipv4_address_string(address),
  parse_ipv4_mask_string(mask_length),
  )
}

/// parse an ipv4 mask. valid values are 1 to 32.
///
fn parse_ipv4_mask_string(count: String) -> Result(NetMask, ParseError) {
  count
  |> int.parse
  |> result.map_error(MaskParseError)
  |> result.try(fn(bits) {
    case bits {
      b if b <= 0 -> Error(MaskTooSmallParseError(b))
      b if b > ipv4_num_bits -> Error(MaskTooLargeParseError(b))
      b -> {
        int.power(2, b |> int.to_float)
        |> result.map_error(MaskParseError)
        |> result.map(float.truncate)
        |> result.map(fn(q) { q - 1 })
        |> result.map(int.bitwise_shift_left(_, ipv4_num_bits - b))
        |> result.map(Ipv4NetMask)
      }
    }
  })
}

fn parse_ipv4_address_string(address: String) -> Result(IpAddress, ParseError) {
  let address_list = address |> string.split(ipv4_component_separator)
  let address_list_length = address_list |> list.length
  case address_list_length {
    l if l > ipv4_num_components -> Error(AddressTooManyComponentsParseError(l))
    l if l < ipv4_num_components -> Error(AddressTooFewComponentsParseError(l))
    _ -> parse_ipv4_address_string_components(address_list)
  }
}

fn parse_ipv4_address_string_components(
ipv4_addresses: List(String),
) -> Result(IpAddress, ParseError) {
  case
  ipv4_addresses
  |> list.map(parse_ipv4_address_component_string)
  |> list.partition(result.is_error)
  {
    #([], results) ->
    results |> list.filter_map(fn(x) { x }) |> new_ipv4address
    #(errors, _) ->
    errors
    |> list.map(fn(x) {
      result.unwrap_error(x, or: UnknownParseError)
    })
    |> ParseErrors
    |> Error
  }
}

fn new_ipv4address(components: List(Int)) -> Result(IpAddress, ParseError) {
  let list_length = components |> list.length
  case components, list_length{
    [a, b, c, d], _ -> Ok(Ipv4(a, b, c, d))
    _, l if l > ipv4_num_components -> Error(AddressTooManyComponentsParseError(l))
    _, l if l < ipv4_num_components -> Error(AddressTooFewComponentsParseError(l))
    _, _ -> Error(UnknownParseError)
  }
}

fn parse_ipv4_address_component_string(
component: String,
) -> Result(Int, ParseError) {
  component
  |> int.parse
  |> result.map_error(fn(_) {
    AddressComponentStringToIntParseError(
    component |> string.slice(at_index: 0, length: ipv4_num_component_characters),
    )
  })
  |> result.try(fn(v) {
    case v {
      v if v < 0 -> Error(AddressComponentValueTooLargeParseError(v))
      v if v >= max_ipv4_address_component ->
      Error(AddressComponentValueTooLargeParseError(v))
      v -> Ok(v)
    }
  })
}

fn parse_ipv4_subnet(
address: Result(IpAddress, ParseError),
mask: Result(NetMask, ParseError),
) -> Result(Subnet, ParseError) {
  case address, mask {
    Ok(a), Ok(b) -> Ok(Ipv4Subnet(a, b))
    Ok(_), Error(e) -> Error(e)
    Error(e), Ok(_) -> Error(e)
    Error(ea), Error(eb) -> Error(ParseErrors([ea, eb]))
  }
}
