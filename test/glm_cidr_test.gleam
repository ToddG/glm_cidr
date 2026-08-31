import gleam/result
import gleeunit
import gleeunit/should
import glm_cidr/cidr.{Ipv4, Ipv6, NetworkMask, Subnet}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn ipaddress_from_string_1_test() {
  let a = "10.0.0.0"
  use address <- result.try(cidr.ip_address_from_string(a))
  let a2 = cidr.ip_address_to_string(address)
  should.equal(a, a2) |> Ok
}

pub fn ipaddress_from_string_2_test() {
  let a = "10.0.0.256"
  should.be_error(cidr.ip_address_from_string(a))
}

pub fn ipaddress_from_string_3_test() {
  let a = "10.0.0"
  should.be_error(cidr.ip_address_from_string(a))
}

pub fn ipaddress_from_string_4_test() {
  let a = "256.0.0.0"
  should.be_error(cidr.ip_address_from_string(a))
}

pub fn subnet_from_string_1_test() {
  let s = "10.0.0.0/24"
  use subnet <- result.try(cidr.subnet_from_string(s))
  let s2 = cidr.subnet_to_string(subnet)
  should.equal(s, s2) |> Ok
}

/// no smart collapsing is done
pub fn subnet_from_string_2_test() {
  let s = "AAAA:CCCC::::::BBBB/64"
  use subnet <- result.try(cidr.subnet_from_string(s))
  let s2 = cidr.subnet_to_string(subnet)
  should.not_equal(s, s2) |> Ok
}

pub fn subnet_from_string_2a_test() {
  let s = "AAAA:CCCC:0:0:0:0:0:BBBB/64"
  use subnet <- result.try(cidr.subnet_from_string(s))
  let s2 = cidr.subnet_to_string(subnet)
  should.equal(s, s2) |> Ok
}

pub fn subnet_from_string_3_test() {
  let s = "i:am:a:cat!!"
  should.be_error(cidr.subnet_from_string(s))
}

pub fn valid_ipv4_subnet_test() {
  validate_subnet("192.168.1.1/32", Ipv4(192, 168, 1, 1), NetworkMask(32))
  validate_subnet("10.0.0.1/24", Ipv4(10, 0, 0, 1), NetworkMask(24))
}

pub fn invalid_ipv4_subnet_test() {
  should.be_error(cidr.subnet_from_string("10.0.0.1/0"))
  should.be_error(cidr.subnet_from_string("10.0.0.1/33"))
  should.be_error(cidr.subnet_from_string("alpha.0.0.1/33"))
  should.be_error(cidr.subnet_from_string(".0.0.1/32"))
  should.be_error(cidr.subnet_from_string("10.0.0.1/-32"))
}

pub fn valid_ipv6_subnet_test() {
  validate_subnet(
    "0:0:0:0:0:0:0:1/128",
    Ipv6(0, 0, 0, 0, 0, 0, 0, 1),
    NetworkMask(128),
  )
  validate_subnet(
    "1:2:3:4:5:6:7:8/128",
    Ipv6(1, 2, 3, 4, 5, 6, 7, 8),
    NetworkMask(128),
  )
  validate_subnet(
    "1:2:3:4:5:6:7:8/64",
    Ipv6(1, 2, 3, 4, 5, 6, 7, 8),
    NetworkMask(64),
  )
  validate_subnet(
    "1A:2B:3C:4D:DD:FF:A1:11/64",
    Ipv6(26, 43, 60, 77, 221, 255, 161, 17),
    NetworkMask(64),
  )
}

pub fn validate_subnet(
  s: String,
  address: cidr.IpAddress,
  mask: cidr.NetworkMask,
) -> Nil {
  let subnet = should.be_ok(cidr.subnet_from_string(s))
  should.equal(s, subnet |> cidr.subnet_to_string)
  should.equal(subnet, Subnet(address, mask))
}

pub fn invalid_ipv6_subnet_test() {
  should.be_error(cidr.subnet_from_string("i am a cat"))
  should.be_error(cidr.subnet_from_string("i:am:a:cat:with/9 lives"))
  should.be_error(cidr.subnet_from_string("2B:3C:4D:DD:FF:A1:11/64"))
  should.be_error(cidr.subnet_from_string("XX:2B:3C:4D:DD:FF:A1:11/64"))
}

pub fn ipv4_inside_subnet_relationship_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.1/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.0.66"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv4_inside_subnet_relationship_2_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv4_inside_subnet_relationship_3_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.255/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv4_inside_subnet_relationship_4_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.99/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.0.1"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv4_inside_subnet_relationship_5_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.0.254"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv4_inside_subnet_relationship_6_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv4_inside_subnet_relationship_7_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.0.255"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv4_outside_relationship_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.1/24"))
  let address = should.be_ok(cidr.ip_address_from_string("10.0.2.1"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsOutsideSubnet,
  )
}

pub fn ipv4_unrelated_relationship_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.1/24"))
  let address = should.be_ok(cidr.ip_address_from_string(":::::::1"))
  should.be_error(cidr.relationship(subnet, address))
}

pub fn ipv6_inside_subnet_relationship_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("AAAA:::::::BBBB/64"))
  let address = should.be_ok(cidr.ip_address_from_string("AAAA:::::::CCCC"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsInsideSubnet,
  )
}

pub fn ipv6_outside_relationship_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("AAAA:CCCC::::::BBBB/64"))
  let address = should.be_ok(cidr.ip_address_from_string("AAAA:DDDD::::::BBBB"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, address)),
    cidr.AddressIsOutsideSubnet,
  )
}

pub fn ipv6_unrelated_relationship_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("AAAA:CCCC::::::BBBB/64"))
  let address = should.be_ok(cidr.ip_address_from_string("192.168.1.1"))
  should.be_error(cidr.relationship(subnet, address))
}

pub fn ipv4_string_test() {
  let ipv4_address = Ipv4(10, 0, 0, 1)
  let ipv4_str = cidr.ip_address_to_string(ipv4_address)
  should.equal(ipv4_str, "10.0.0.1")
}

pub fn ipv6_string_test() {
  let ipv6_address = Ipv6(0, 0, 0, 0, 0, 0, 0, 1)
  let ipv6_str = cidr.ip_address_to_string(ipv6_address)
  should.equal(ipv6_str, "0:0:0:0:0:0:0:1")
}

pub fn ipv4_metadata_1_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let network = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  let broadcast = should.be_ok(cidr.ip_address_from_string("10.0.0.255"))
  let first_host = should.be_ok(cidr.ip_address_from_string("10.0.0.1"))
  let last_host = should.be_ok(cidr.ip_address_from_string("10.0.0.254"))
  let usable_hosts = 254
  let prefix = 24
  let hex_netmask = "0xFFFFFF00"
  should.equal(
    should.be_ok(cidr.metadata(subnet)),
    cidr.SubnetMetadata(
      network:,
      broadcast:,
      first_host:,
      last_host:,
      usable_hosts:,
      prefix:,
      hex_netmask:,
    ),
  )
}

pub fn ipv4_metadata_2_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.1/24"))
  let network = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  let broadcast = should.be_ok(cidr.ip_address_from_string("10.0.0.255"))
  let first_host = should.be_ok(cidr.ip_address_from_string("10.0.0.1"))
  let last_host = should.be_ok(cidr.ip_address_from_string("10.0.0.254"))
  let usable_hosts = 254
  let prefix = 24
  let hex_netmask = "0xFFFFFF00"
  should.equal(
    cidr.metadata(subnet),
    cidr.SubnetMetadata(
      network:,
      broadcast:,
      first_host:,
      last_host:,
      usable_hosts:,
      prefix:,
      hex_netmask:,
    )
      |> Ok,
  )
}

pub fn ipv4_metadata_3_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/25"))
  let network = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  let broadcast = should.be_ok(cidr.ip_address_from_string("10.0.0.127"))
  let first_host = should.be_ok(cidr.ip_address_from_string("10.0.0.1"))
  let last_host = should.be_ok(cidr.ip_address_from_string("10.0.0.126"))
  let usable_hosts = 126
  let prefix = 25
  let hex_netmask = "0xFFFFFF80"
  should.equal(
    cidr.metadata(subnet),
    cidr.SubnetMetadata(
      network:,
      broadcast:,
      first_host:,
      last_host:,
      usable_hosts:,
      prefix:,
      hex_netmask:,
    )
      |> Ok,
  )
}

pub fn ipv4_metadata_4_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/26"))
  let network = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  let broadcast = should.be_ok(cidr.ip_address_from_string("10.0.0.63"))
  let first_host = should.be_ok(cidr.ip_address_from_string("10.0.0.1"))
  let last_host = should.be_ok(cidr.ip_address_from_string("10.0.0.62"))
  let usable_hosts = 62
  let prefix = 26
  let hex_netmask = "0xFFFFFFC0"
  should.equal(
    cidr.metadata(subnet),
    cidr.SubnetMetadata(
      network:,
      broadcast:,
      first_host:,
      last_host:,
      usable_hosts:,
      prefix:,
      hex_netmask:,
    )
      |> Ok,
  )
}

pub fn ipv4_metadata_5_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.64/26"))
  let network = should.be_ok(cidr.ip_address_from_string("10.0.0.64"))
  let broadcast = should.be_ok(cidr.ip_address_from_string("10.0.0.127"))
  let first_host = should.be_ok(cidr.ip_address_from_string("10.0.0.65"))
  let last_host = should.be_ok(cidr.ip_address_from_string("10.0.0.126"))
  let usable_hosts = 62
  let prefix = 26
  let hex_netmask = "0xFFFFFFC0"
  should.equal(
    cidr.metadata(subnet),
    cidr.SubnetMetadata(
      network:,
      broadcast:,
      first_host:,
      last_host:,
      usable_hosts:,
      prefix:,
      hex_netmask:,
    )
      |> Ok,
  )
}

pub fn ipv4_next_1_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let current = should.be_ok(cidr.ip_address_from_string("10.0.0.1"))
  let next = should.be_ok(cidr.ip_address_from_string("10.0.0.2"))
  should.equal(should.be_ok(cidr.next(subnet, current)), next)
}

pub fn ipv4_next_2_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let current = should.be_ok(cidr.ip_address_from_string("10.0.0.253"))
  let next = should.be_ok(cidr.ip_address_from_string("10.0.0.254"))
  should.equal(should.be_ok(cidr.next(subnet, current)), next)
}

pub fn ipv4_next_3_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let current = should.be_ok(cidr.ip_address_from_string("10.0.0.254"))
  let next = should.be_ok(cidr.ip_address_from_string("10.0.0.255"))
  should.equal(should.be_ok(cidr.next(subnet, current)), next)
}

pub fn ipv4_next_usable_1_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let current = should.be_ok(cidr.ip_address_from_string("10.0.0.0"))
  let next = should.be_ok(cidr.ip_address_from_string("10.0.0.1"))
  should.equal(should.be_ok(cidr.next_usable(subnet, current)), next)
}

pub fn ipv4_next_usable_2_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let current = should.be_ok(cidr.ip_address_from_string("10.0.0.252"))
  let next = should.be_ok(cidr.ip_address_from_string("10.0.0.253"))
  should.equal(should.be_ok(cidr.next_usable(subnet, current)), next)
}

pub fn ipv4_next_usable_3_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let current = should.be_ok(cidr.ip_address_from_string("10.0.0.253"))
  let next = should.be_ok(cidr.ip_address_from_string("10.0.0.254"))
  should.equal(should.be_ok(cidr.next_usable(subnet, current)), next)
}

pub fn ipv4_next_usable_4_test() {
  let subnet = should.be_ok(cidr.subnet_from_string("10.0.0.0/24"))
  let current = should.be_ok(cidr.ip_address_from_string("10.0.0.254"))
  should.be_error(cidr.next_usable(subnet, current))
}
// pub fn calculate_number_of_usable_hosts_test() {
//   should.equal(should.be_ok(cidr.calculate_number_of_usable_hosts(0)), 0)
//   should.equal(should.be_ok(cidr.calculate_number_of_usable_hosts(1)), 2)
//   should.equal(should.be_ok(cidr.calculate_number_of_usable_hosts(2)), 2)
//   should.equal(should.be_ok(cidr.calculate_number_of_usable_hosts(3)), 6)
//   should.equal(should.be_ok(cidr.calculate_number_of_usable_hosts(8)), 254)
//   should.equal(
//     should.be_ok(cidr.calculate_number_of_usable_hosts(24)),
//     16_777_214,
//   )
// }
