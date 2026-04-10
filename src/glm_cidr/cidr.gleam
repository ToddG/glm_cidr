import gleam/bit_array
import gleam/float
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/string

/// ------------------------------------------------------------------
/// PUBLIC API
/// ------------------------------------------------------------------
/// Given a string with an internet address and network mask delimited with a slash "/", return a subnet.
///
/// ## Examples
///
/// ```gleam
/// subnet("10.0.0.1/24")
/// -> Ok(IPV4 SUBNET)
///
/// subnet(":::::::1/128")
/// -> Ok(IPV6 SUBNET)
/// ```
///
pub fn subnet(s: String) -> Result(Subnet, ParseError) {
  case s |> string.split_once(on: network_and_mask_separator) {
    Error(_) -> Error(SplitAddressFromMaskParseError)
    Ok(#(a, b)) -> parse_address_and_mask_strings(a, b)
  }
}

/// Convert a network subnet to string.
pub fn subnet_to_string(subnet: Subnet) -> String {
  ip_address_to_string(subnet.address)
  <> network_and_mask_separator
  <> subnet.netmask.count |> int.to_string
}

/// Convert an IP Address the same string representation that the API consumes:
///
/// ## Examples
///
/// ```gleam
/// let assert(ipv4_address) = Ipv4(10, 0, 0, 1)
/// ip_address_to_string(ipv4_address)
/// -> "10.0.0.1"
///
/// Note: for IPV6, no smart collapsing is done.
pub fn ip_address_to_string(address: IpAddress) -> String {
  case address {
    Ipv6(a:, b:, c:, d:, e:, f:, g:, h:) -> {
      [a, b, c, d, e, f, g, h]
      |> list.map(int.to_base16)
      |> string.join(ipv6_component_separator)
    }
    Ipv4(a:, b:, c:, d:) -> {
      [a, b, c, d]
      |> list.map(int.to_string)
      |> string.join(ipv4_component_separator)
    }
  }
}

/// Given a subnet and a string with an internet address, determine the relationship between the two.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(subnet) = subnet("10.0.0.1/24")
///
/// relationship(subnet, "10.0.0.66")
/// -> Ok(AddressIsInsideSubnet(prev: 10.0.0.65, next: 10.0.0.67, subnet_metadata: { first: 10.0.0.1, last: 10.0.0.255, count: 254 } )
///
/// relationship(subnet, "10.0.2.1")
/// -> Ok(AddressIsOutsideSubnet, subnet_metadata: { first: 10.0.0.1, last: 10.0.0.255, count: 254 } )
///
/// relationship(subnet, ":::::::1")
/// -> Ok(UnrelatedNetworkTypes, subnet_metadata: { first: 10.0.0.1, last: 10.0.0.255, count: 254 } )
///
/// relationship(subnet, "i:am:a:cat")
/// -> Error(ParseError(...))
/// ```
pub fn relationship(
  subnet: Subnet,
  address: String,
) -> Result(AddressSubnetRelationship, ParseError) {
  case
    result.or(
      parse_ipv4_address_string(address),
      parse_ipv6_address_string(address),
    )
  {
    Error(e) -> Error(e)
    Ok(target_address) -> {
      case target_address, subnet.address {
        Ipv6(_, _, _, _, _, _, _, _), Ipv6(_, _, _, _, _, _, _, _) -> {
          calculate_relationship(subnet, target_address)
        }
        Ipv4(_, _, _, _), Ipv4(_, _, _, _) -> {
          calculate_relationship(subnet, target_address)
        }
        Ipv6(_, _, _, _, _, _, _, _), Ipv4(_, _, _, _) ->
          Ok(UnrelatedNetworkTypes)
        Ipv4(_, _, _, _), Ipv6(_, _, _, _, _, _, _, _) ->
          Ok(UnrelatedNetworkTypes)
      }
    }
  }
}

/// ------------------------------------------------------------------
/// MODELS
/// ------------------------------------------------------------------
/// IP Address
pub type IpAddress {
  /// The IPV4 representation of an IP Address (4 8 bit integers)
  Ipv4(a: Int, b: Int, c: Int, d: Int)
  /// The IPV6 representation of an IP Address (8 16 bit integers)
  Ipv6(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int)
}

/// The number of bits in a network mask.
pub type NetworkMask {
  /// For IPV4, valid values are from 0 to 32
  /// For IPV6, valid values are from 0 to 128
  NetworkMask(count: Int)
}

/// A subnet defines a network using an IP Address and a NetMask
pub type Subnet {
  /// An IPV4 Subnet has 32 bits for the network and host address
  /// An IPV6 Subnet has 128 bits for the network and host address
  Subnet(address: IpAddress, netmask: NetworkMask)
}

/// # SubnetMetadata
///
/// SubnetMetadata about the usable addresses. By usable addresses, we mean the addresses that
/// are not already allocated by the networking system, e.g. the network address and the broadcast address.
///
/// ## Special cases:
///
/// Note that for both IPV4 and IPV6, this function follows the following convention:
///
///   IPV4 /32 -> single host                       -> 1 address
///   IPV4 /31 -> point-to-point link               -> 2 addresses
///   IPV4 /30 -> traditional point-to-point link   -> 2 addresses
///
///
/// ### Single Host Route (/32 | /128)
///
/// If the entire range is masked off, e.g. /32 or /128, then this is deemed to be a single host with no subnet,
/// and the function returns one usable address for both the first and last addresses.
///
/// ### Point-To-Point Links (/31 /127)
///
/// With all but one bit masked off, e.g. /32 or /127, then 2 hosts are returned. This is commonly used for the creation
/// of a point-to-point network with two usable addresses.
///
/// ### Traditional Point-To-Point Links (/30 /126)
///
/// With all but two bits masked off, e.g. /30 or /126, this defines a traditional point-to-point link. The first
/// and last addresses are allocated as network and broadcast addresses. This method returns the two remaining addresses
/// as first and last.
///
/// ### Standard Subnet (/29 /64)
///
/// With three or more bits available (IPV4) or 64 bits (IPV6), the first and last addresses are
/// and last addresses are allocated as network and broadcast addresses. This method returns the two remaining addresses
/// as first and last. The count for IPV4 returns the count of usable addresses, .e.g 2**(32-3) for a /29 IPV4 network and
/// 2**(128-64) for a /64 IPV4 network.
///
/// ## Summary
///
/// To keep things consistent, the behaviour of these special cases follows the same convention for both IPV4 and
/// IPV6. Even though IPV6 does not have a broadcast address, we are treating it as if it did.
///
/// ## Examples
///
/// ```gleam
/// metadata(subnet("10.0.0.1/32"))
/// -> Ok(SubnetMetadata(first: 10.0.0.1, last: 10.0.0.1, count: 1)
///
/// metadata(subnet("10.0.0.1/31"))
/// -> Ok(SubnetMetadata(first: 10.0.0.0, last: 10.0.0.1, count: 2)
///
/// metadata(subnet("10.0.0.1/30"))
/// -> Ok(SubnetMetadata(first: 10.0.0.1, last: 10.0.0.2, count: 2)
///
/// metadata(subnet("10.0.0.1/24"))
/// -> Ok(SubnetMetadata(first: 10.0.0.1, last: 10.0.0.254, count: 254)
///
/// metadata(subnet("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/128"))
/// -> Ok(SubnetMetadata(first: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF, last: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF, count: 1)
///
/// metadata(subnet("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/127"))
/// -> Ok(SubnetMetadata(first: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE, last: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF, count: 2)
///
/// metadata(subnet("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/126"))
/// -> Ok(SubnetMetadata(first: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFD, last: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE, count: 2)
///
/// metadata(subnet("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/112"))
/// -> Ok(SubnetMetadata(first: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:1, last: FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE, count: 65534)
///
pub type SubnetMetadata {
  SubnetMetadata(
    /// The first usable address in the subnet.
    first: IpAddress,
    /// The last usable address in the subnet.
    last: IpAddress,
    /// The count of the usable addresses in the subnet.
    count: Int,
    /// The subnet network
    network: BitArray,
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
  /// Internally inconsistent objects, should never occur
  InternallyInconsistentSubnetIpv6SubnetWithIpv4Netmask
  InternallyInconsistentSubnetIpv4SubnetWithIpv6Netmask
  /// Bit Parsing Errors
  SubnetBitSliceParseError(
    subnet: Subnet,
    bitarray: BitArray,
    bitarray_length: Int,
  )
  TargetAddressSliceParseError(
    subnet: Subnet,
    bitarray: BitArray,
    bitarray_length: Int,
  )
  MalformedBitArray
  NetworkSizeParseError(Nil)
  NetworkAddressParseError(Nil)
  IncrementIpAddressParseError
}

/// The relationship between an IP Address, and an Subnet
pub type AddressSubnetRelationship {
  /// The IP Address lies inside the Subnet. At least one of the Subnet addresses resolves to the IP Address.
  AddressIsInsideSubnet(next: IpAddress, subnet_metadata: SubnetMetadata)
  /// The IP Address lies outside the Subnet. None of the Subnet addresses resolve to the IP Address.
  AddressIsOutsideSubnet(subnet_metadata: SubnetMetadata)
  /// The IP Address does not have a relationship with the Subnet because the IP Address is not the same network type as the Subnet.
  /// If the IP Address is IPV4 and the Subnet is IPV6, they are unrelated. Likewise if the IPAddress is IPV6 and the Subnet
  /// is IPV4, then the two are unrelated.
  UnrelatedNetworkTypes
}

/// IPV6 num_bits (128)
const ipv6_num_bits = 128

/// IPV6 address components are 16 bit (2**16)
const ipv6_address_component_max_size = 65_536

/// IPV6 address has 8 components
const ipv6_num_components = 8

/// IPV6 address component separator
const ipv6_component_separator = ":"

/// IPV6 number of characters in a component
const ipv6_num_component_characters = 4

/// IPV4 num_bits (32)
const ipv4_num_bits = 32

/// IPV4 address components are 8 bit (2**8)
const ipv4_address_component_max_size = 256

/// IPV4 address has 4 components
const ipv4_num_components = 4

/// IPV4 address component separator
const ipv4_component_separator = "."

/// IPV4 number of characters in a component
const ipv4_num_component_characters = 2

const network_and_mask_separator = "/"

// ==================================================================
// PRIVATE FUNCTIONS
// ==================================================================

fn calculate_relationship(
  subnet: Subnet,
  target_address: IpAddress,
) -> Result(AddressSubnetRelationship, ParseError) {
  let subnet_metadata_result = subnet_metadata(subnet)
  let target_address_bit_array = ip_address_to_bit_array(target_address)
  let count = subnet.netmask.count
  let target_address_network_bit_array_result = case target_address_bit_array {
    <<data:bits-size(count), _:bits>> -> {
      Ok(data)
    }
    _ ->
      Error(TargetAddressSliceParseError(
        subnet:,
        bitarray: target_address_bit_array,
        bitarray_length: target_address_bit_array |> bit_array.bit_size,
      ))
  }

  case subnet_metadata_result, target_address_network_bit_array_result {
    Ok(subnet_metadata), Ok(target_address_bit_array) -> {
      let address_compare =
        bit_array.compare(subnet_metadata.network, target_address_bit_array)
      case address_compare {
        order.Lt -> Ok(AddressIsOutsideSubnet(subnet_metadata:))
        order.Gt -> Ok(AddressIsOutsideSubnet(subnet_metadata:))
        order.Eq -> {
          case increment_ip_address(target_address) {
            Error(e) -> Error(e)
            Ok(next) -> {
              Ok(AddressIsInsideSubnet(next:, subnet_metadata:))
            }
          }
        }
      }
    }
    Error(e), _ -> Error(e)
    _, Error(e) -> Error(e)
  }
}

fn subnet_metadata(subnet: Subnet) -> Result(SubnetMetadata, ParseError) {
  let subnet_address_bit_array = subnet.address |> ip_address_to_bit_array
  let subnet_bit_array_length = subnet_address_bit_array |> bit_array.bit_size
  let count = subnet.netmask.count
  let network_result = case subnet_address_bit_array {
    <<data:bits-size(count), _:bits>> -> {
      Ok(data)
    }
    _ ->
      Error(SubnetBitSliceParseError(
        subnet:,
        bitarray: subnet_address_bit_array,
        bitarray_length: subnet_bit_array_length,
      ))
  }
  case subnet.address {
    Ipv6(_, _, _, _, _, _, _, _) -> {
      // --------------------------------------------------------------
      // ipv6
      // --------------------------------------------------------------
      case subnet.netmask.count, network_result {
        128, _ -> {
          Ok(SubnetMetadata(
            first: subnet.address,
            last: subnet.address,
            count: 1,
            network: subnet_address_bit_array,
          ))
        }
        127, Ok(network) -> {
          let first_ip_address_result =
            bit_array.append(network, <<0:size(1)>>)
            |> bit_array_to_ip_address
          let last_ip_address_result =
            bit_array.append(network, <<1:size(1)>>)
            |> bit_array_to_ip_address
          case first_ip_address_result, last_ip_address_result {
            Ok(first), Ok(last) -> {
              Ok(SubnetMetadata(first:, last:, count: 2, network:))
            }
            Error(e), _ -> Error(e)
            _, Error(e) -> Error(e)
          }
        }
        mask, Ok(network) -> {
          let address_size = 128 - mask
          let first_ip_address_result =
            bit_array.append(
              network,
              bit_array.append(bit_array_pad_zero(address_size - 1), <<
                1:size(1),
              >>),
            )
            |> bit_array_to_ip_address
          let last_ip_address_result =
            bit_array.append(
              network,
              bit_array.append(bit_array_pad_one(address_size - 1), <<
                0:size(1),
              >>),
            )
            |> bit_array_to_ip_address
          let network_size_result = calculate_network_size(address_size)
          case
            first_ip_address_result,
            last_ip_address_result,
            network_size_result
          {
            Ok(first), Ok(last), Ok(count) -> {
              Ok(SubnetMetadata(first:, last:, count:, network:))
            }
            Error(e), _, _ -> Error(e)
            _, Error(e), _ -> Error(e)
            _, _, Error(e) -> Error(e)
          }
        }
        _, Error(e) -> Error(e)
      }
    }
    Ipv4(_, _, _, _) -> {
      // --------------------------------------------------------------
      // ipv6
      // --------------------------------------------------------------
      case subnet.netmask.count, network_result {
        32, _ -> {
          Ok(SubnetMetadata(
            first: subnet.address,
            last: subnet.address,
            count: 1,
            network: subnet_address_bit_array,
          ))
        }
        31, Ok(network) -> {
          let first_ip_address_result =
            bit_array.append(network, <<0:size(1)>>)
            |> bit_array_to_ip_address
          let last_ip_address_result =
            bit_array.append(network, <<1:size(1)>>)
            |> bit_array_to_ip_address
          case first_ip_address_result, last_ip_address_result {
            Ok(first), Ok(last) -> {
              Ok(SubnetMetadata(first:, last:, count: 2, network:))
            }
            Error(e), _ -> Error(e)
            _, Error(e) -> Error(e)
          }
        }
        mask, Ok(network) -> {
          let address_size = 32 - mask
          let first_ip_address_result =
            bit_array.append(
              network,
              bit_array.append(bit_array_pad_zero(address_size - 1), <<
                1:size(1),
              >>),
            )
            |> bit_array_to_ip_address
          let last_ip_address_result =
            bit_array.append(
              network,
              bit_array.append(bit_array_pad_one(address_size - 1), <<
                0:size(1),
              >>),
            )
            |> bit_array_to_ip_address
          let network_size_result = calculate_network_size(address_size)
          case
            first_ip_address_result,
            last_ip_address_result,
            network_size_result
          {
            Ok(first), Ok(last), Ok(count) -> {
              Ok(SubnetMetadata(first:, last:, count:, network:))
            }
            Error(e), _, _ -> Error(e)
            _, Error(e), _ -> Error(e)
            _, _, Error(e) -> Error(e)
          }
        }
        _, Error(e) -> Error(e)
      }
    }
  }
}

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
fn parse_ipv6_mask_string(count: String) -> Result(NetworkMask, ParseError) {
  count
  |> int.parse
  |> result.map_error(MaskParseError)
  |> result.try(fn(bits) {
    case bits {
      b if b > ipv6_num_bits -> Error(MaskTooLargeParseError(bits))
      b if b < 1 -> Error(MaskTooSmallParseError(bits))
      _ -> Ok(NetworkMask(bits))
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
    #([], results) -> results |> list.filter_map(fn(x) { x }) |> new_ipv6address
    #(errors, _) ->
      errors
      |> list.map(fn(x) { result.unwrap_error(x, or: UnknownParseError) })
      |> ParseErrors
      |> Error
  }
}

fn new_ipv6address(components: List(Int)) -> Result(IpAddress, ParseError) {
  let list_length = components |> list.length
  case components, list_length {
    [a, b, c, d, e, f, g, h], _ -> Ok(Ipv6(a, b, c, d, e, f, g, h))
    _, l if l > ipv6_num_components ->
      Error(AddressTooManyComponentsParseError(l))
    _, l if l < ipv6_num_components ->
      Error(AddressTooFewComponentsParseError(l))
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
          component
          |> string.slice(at_index: 0, length: ipv6_num_component_characters),
        )
      })
      |> result.try(fn(v) {
        case v {
          v if v < 0 -> Error(AddressComponentValueTooLargeParseError(v))
          v if v >= ipv6_address_component_max_size ->
            Error(AddressComponentValueTooLargeParseError(v))
          v -> Ok(v)
        }
      })
    }
  }
}

fn parse_ipv6_subnet(
  address: Result(IpAddress, ParseError),
  mask: Result(NetworkMask, ParseError),
) -> Result(Subnet, ParseError) {
  case address, mask {
    Ok(a), Ok(b) -> Ok(Subnet(a, b))
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
fn parse_ipv4_mask_string(count: String) -> Result(NetworkMask, ParseError) {
  count
  |> int.parse
  |> result.map_error(MaskParseError)
  |> result.try(fn(bits) {
    case bits {
      b if b > ipv4_num_bits -> Error(MaskTooLargeParseError(bits))
      b if b < 1 -> Error(MaskTooSmallParseError(bits))
      _ -> Ok(NetworkMask(bits))
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
    #([], results) -> results |> list.filter_map(fn(x) { x }) |> new_ipv4address
    #(errors, _) ->
      errors
      |> list.map(fn(x) { result.unwrap_error(x, or: UnknownParseError) })
      |> ParseErrors
      |> Error
  }
}

fn new_ipv4address(components: List(Int)) -> Result(IpAddress, ParseError) {
  let list_length = components |> list.length
  case components, list_length {
    [a, b, c, d], _ -> Ok(Ipv4(a, b, c, d))
    _, l if l > ipv4_num_components ->
      Error(AddressTooManyComponentsParseError(l))
    _, l if l < ipv4_num_components ->
      Error(AddressTooFewComponentsParseError(l))
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
      component
      |> string.slice(at_index: 0, length: ipv4_num_component_characters),
    )
  })
  |> result.try(fn(v) {
    case v {
      v if v < 0 -> Error(AddressComponentValueTooLargeParseError(v))
      v if v >= ipv4_address_component_max_size ->
        Error(AddressComponentValueTooLargeParseError(v))
      v -> Ok(v)
    }
  })
}

fn parse_ipv4_subnet(
  address: Result(IpAddress, ParseError),
  mask: Result(NetworkMask, ParseError),
) -> Result(Subnet, ParseError) {
  case address, mask {
    Ok(a), Ok(b) -> Ok(Subnet(a, b))
    Ok(_), Error(e) -> Error(e)
    Error(e), Ok(_) -> Error(e)
    Error(ea), Error(eb) -> Error(ParseErrors([ea, eb]))
  }
}

fn ip_address_to_bit_array(address: IpAddress) -> BitArray {
  case address {
    Ipv6(a:, b:, c:, d:, e:, f:, g:, h:) -> {
      <<
        a:size(16),
        b:size(16),
        c:size(16),
        d:size(16),
        e:size(16),
        f:size(16),
        g:size(16),
        h:size(16),
      >>
    }
    Ipv4(a:, b:, c:, d:) -> {
      <<
        a:size(8),
        b:size(8),
        c:size(8),
        d:size(8),
      >>
    }
  }
}

fn bit_array_to_ip_address(b: BitArray) -> Result(IpAddress, ParseError) {
  case b {
    <<
      a:int-size(16),
      b:int-size(16),
      c:int-size(16),
      d:int-size(16),
      e:int-size(16),
      f:int-size(16),
      g:int-size(16),
      h:int-size(16),
    >> -> {
      Ok(Ipv6(a, b, c, d, e, f, g, h))
    }
    <<a:int-size(8), b:int-size(8), c:int-size(8), d:int-size(8)>> -> {
      Ok(Ipv4(a, b, c, d))
    }
    _ -> Error(MalformedBitArray)
  }
}

fn bit_array_pad_zero(count: Int) -> BitArray {
  do_bit_array_pad_zero(count, <<>>)
}

fn do_bit_array_pad_zero(count: Int, accum: BitArray) -> BitArray {
  case count {
    0 -> accum
    _ ->
      do_bit_array_pad_zero(count - 1, bit_array.append(accum, <<0:size(1)>>))
  }
}

fn bit_array_pad_one(count: Int) -> BitArray {
  do_bit_array_pad_one(count, <<>>)
}

fn do_bit_array_pad_one(count: Int, accum: BitArray) -> BitArray {
  case count {
    0 -> accum
    _ -> do_bit_array_pad_one(count - 1, bit_array.append(accum, <<1:size(1)>>))
  }
}

fn calculate_network_size(address_size: Int) -> Result(Int, ParseError) {
  address_size
  |> int.to_float
  |> int.power(2, _)
  |> result.map_error(NetworkSizeParseError)
  |> result.map(float.truncate)
  |> result.map(fn(x) { x - 2 })
}

fn increment_ip_address(address: IpAddress) -> Result(IpAddress, ParseError) {
  case address {
    Ipv6(a:, b:, c:, d:, e:, f:, g:, h:) -> {
      let res =
        [a, b, c, d, e, f, g, h]
        |> list.reverse
        |> increment_items(1, ipv6_address_component_max_size)
      case res {
        Ok([a, b, c, d, e, f, g, h]) -> {
          Ok(Ipv6(h, g, f, e, d, c, b, a))
        }
        Error(e) -> Error(e)
        _ -> Error(IncrementIpAddressParseError)
      }
    }
    Ipv4(a:, b:, c:, d:) -> {
      let res =
        [a, b, c, d]
        |> list.reverse
        |> increment_items(1, ipv4_address_component_max_size)
      case res {
        Ok([a, b, c, d]) -> {
          Ok(Ipv4(a, b, c, d))
        }
        Error(e) -> Error(e)
        _ -> Error(IncrementIpAddressParseError)
      }
    }
  }
}

fn increment_items(
  items: List(Int),
  x: Int,
  max_value: Int,
) -> Result(List(Int), ParseError) {
  do_increment_items(items, x, max_value, [])
}

fn do_increment_items(
  items: List(Int),
  x: Int,
  max_value: Int,
  accum: List(Int),
) -> Result(List(Int), ParseError) {
  case items {
    [] -> accum |> Ok
    [head, ..tail] -> {
      let head = head + x
      case head > max_value {
        True -> {
          // rollover
          let carry = max_value - head
          let head = 0
          do_increment_items(tail, carry, max_value, list.append([head], accum))
        }
        False -> {
          do_increment_items(tail, 0, max_value, list.append([head], accum))
        }
      }
    }
  }
}
