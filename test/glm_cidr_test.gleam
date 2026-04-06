import gleam/int
import gleam/string
import gleeunit
import gleeunit/should
import glm_cidr/cidr
import glm_cidr/internal/cidr_private.{ipv4_address, ipv4_address_element}
import glm_cidr/internal/mask_private.{
  create_mask_bits, shift_ipv4_mask_bits, shift_ipv6_mask_bits,
}
import glm_cidr/mask
import glm_cidr/types

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_test() {
  let assert Ok(mask_32) = mask.ipv4_mask_from_int(32)
  assert cidr.parse("1.0.0.1", 32)
    == Ok(types.Ipv4Subnet(
      address: types.Ipv4InetAddress(address: 16_777_217),
      mask: mask_32,
      first: types.Ipv4InetAddress(address: 16_777_217),
      last: types.Ipv4InetAddress(address: 16_777_217),
      count: 1,
    ))
  let assert Ok(mask_31) = mask.ipv4_mask_from_int(31)
  assert cidr.parse("1.0.0.1", 31)
    == Ok(types.Ipv4Subnet(
      address: types.Ipv4InetAddress(address: 16_777_217),
      mask: mask_31,
      first: types.Ipv4InetAddress(address: 16_777_216),
      last: types.Ipv4InetAddress(address: 16_777_217),
      count: 2,
    ))
  let assert Ok(mask_30) = mask.ipv4_mask_from_int(30)
  assert cidr.parse("1.0.0.1", 30)
    == Ok(types.Ipv4Subnet(
      address: types.Ipv4InetAddress(address: 16_777_217),
      mask: mask_30,
      first: types.Ipv4InetAddress(address: 16_777_217),
      last: types.Ipv4InetAddress(address: 16_777_218),
      count: 2 * 2 - 2,
    ))
  let assert Ok(mask_29) = mask.ipv4_mask_from_int(29)
  let assert Ok(parsed) = cidr.parse("1.0.0.1", 29)
  assert parsed
    == types.Ipv4Subnet(
      address: types.Ipv4InetAddress(address: 16_777_217),
      mask: mask_29,
      first: types.Ipv4InetAddress(address: 16_777_217),
      last: types.Ipv4InetAddress(address: 16_777_222),
      count: 2 * 2 * 2 - 2,
    )
}

pub fn contains_test(){
  let assert Ok(subnet) = cidr.parse("10.0.0.1", 24)
  should.be_true(should.be_ok(cidr.contains(subnet, "10.0.0.0")))
  should.be_true(should.be_ok(cidr.contains(subnet, "10.0.0.1")))
  should.be_true(should.be_ok(cidr.contains(subnet, "10.0.0.255")))
  should.be_false(should.be_ok(cidr.contains(subnet, "10.0.1.255")))
  should.be_false(should.be_ok(cidr.contains(subnet, "10.1.0.255")))
  should.be_false(should.be_ok(cidr.contains(subnet, "1.0.0.255")))
}

//pub fn next_test(){
//  let assert Ok(subnet) = cidr.parse("10.0.0.1", 24)
//  should.equal(should.be_ok(cidr.next(subnet, "10.0.0.1")), "10.0.0.2")
//}

pub fn create_mask_bits_test() {
  should.be_error(create_mask_bits(0))
  should.equal(should.be_ok(create_mask_bits(1)), 1)
  should.equal(should.be_ok(create_mask_bits(2)), 3)
  should.equal(should.be_ok(create_mask_bits(3)), 7)
  should.equal(should.be_ok(create_mask_bits(8)), 255)
  should.equal(should.be_ok(create_mask_bits(16)), 65_535)
  should.equal(should.be_ok(create_mask_bits(32)), 4_294_967_295)
}

pub fn create_ipv4_mask_test() {
  should.be_error(shift_ipv4_mask_bits(0))
  should.equal(
    should.be_ok(shift_ipv4_mask_bits(1)) |> int.to_base2,
    "10000000000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv4_mask_bits(2)) |> int.to_base2,
    "11000000000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv4_mask_bits(3)) |> int.to_base2,
    "11100000000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv4_mask_bits(8)) |> int.to_base2,
    "11111111000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv4_mask_bits(16)) |> int.to_base2,
    "11111111111111110000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv4_mask_bits(31)) |> int.to_base2,
    "11111111111111111111111111111110",
  )
  should.equal(
    should.be_ok(shift_ipv4_mask_bits(32)) |> int.to_base2,
    "11111111111111111111111111111111",
  )
}

pub fn create_ipv6_mask_test() {
  should.be_error(shift_ipv6_mask_bits(0))
  should.equal(
    should.be_ok(shift_ipv6_mask_bits(1)) |> int.to_base2,
    "10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv6_mask_bits(2)) |> int.to_base2,
    "11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv6_mask_bits(3)) |> int.to_base2,
    "11100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv6_mask_bits(8)) |> int.to_base2,
    "11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  )
  should.equal(
    should.be_ok(shift_ipv6_mask_bits(128)) |> int.to_base2,
    "11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
  )
}

pub fn ipv4_address_element_test() {
  should.be_error(ipv4_address_element("text"))
  should.be_error(ipv4_address_element("-1"))
  should.be_error(ipv4_address_element("256"))
  should.equal(should.be_ok(ipv4_address_element("1")).address, 1)
  should.equal(should.be_ok(ipv4_address_element("255")).address, 255)
}

pub fn ipv4_address_test() {
  should.equal(
    should.be_ok(ipv4_address(["0", "0", "0", "1"], 0, 0)).address,
    1,
  )
  should.equal(
    should.be_ok(ipv4_address(["0", "0", "0", "255"], 0, 0)).address,
    255,
  )
  should.equal(
    should.be_ok(ipv4_address(["0", "0", "255", "255"], 0, 0)).address,
    255 * 256 + 255,
  )
  should.equal(
    should.be_ok(ipv4_address(["0", "0", "1", "0"], 0, 0)).address,
    1 * 256,
  )
  should.equal(
    should.be_ok(ipv4_address(["0", "1", "0", "0"], 0, 0)).address,
    1 * 256 * 256,
  )
  should.equal(
    should.be_ok(ipv4_address(["1", "0", "0", "0"], 0, 0)).address,
    1 * 256 * 256 * 256,
  )
  should.equal(
    should.be_ok(ipv4_address(["1", "0", "0", "1"], 0, 0)).address,
    1 * 256 * 256 * 256 + 1,
  )
  should.equal(
    should.be_ok(ipv4_address(["1", "0", "1", "1"], 0, 0)).address,
    1 * 256 * 256 * 256 + 1 * 256 + 1,
  )
  should.equal(
    should.be_ok(ipv4_address(["1", "1", "1", "1"], 0, 0)).address,
    1 * 256 * 256 * 256 + 1 * 256 * 256 + 1 * 256 + 1,
  )
  should.equal(
    should.be_ok(ipv4_address(["1", "255", "255", "255"], 0, 0)).address
      |> int.to_base2
      |> string.pad_start(32, "0"),
    "00000001111111111111111111111111",
  )
  should.equal(
    should.be_ok(ipv4_address(["255", "255", "255", "255"], 0, 0)).address
      |> int.to_base2
      |> string.pad_start(32, "0"),
    "11111111111111111111111111111111",
  )
}
