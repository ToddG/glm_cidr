import gleeunit
import gleeunit/should
import glm_cidr/cidr.{Ipv4, Ipv6, NetworkMask, Subnet}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn valid_ipv4_subnet_test() {
  should.equal(
    should.be_ok(cidr.subnet("192.168.1.1/32")),
    Subnet(Ipv4(192, 168, 1, 1), NetworkMask(32)),
  )
  should.equal(
    should.be_ok(cidr.subnet("10.0.0.1/24")),
    Subnet(Ipv4(10, 0, 0, 1), NetworkMask(24)),
  )
}

pub fn invalid_ipv4_subnet_test() {
  should.be_error(cidr.subnet("10.0.0.1/0"))
  should.be_error(cidr.subnet("10.0.0.1/33"))
  should.be_error(cidr.subnet("alpha.0.0.1/33"))
  should.be_error(cidr.subnet(".0.0.1/32"))
  should.be_error(cidr.subnet("10.0.0.1/-32"))
}

pub fn valid_ipv6_subnet_test() {
  should.equal(
    should.be_ok(cidr.subnet(":::::::1/128")),
    Subnet(Ipv6(0, 0, 0, 0, 0, 0, 0, 1), NetworkMask(128)),
  )
  should.equal(
    should.be_ok(cidr.subnet("1:2:3:4:5:6:7:8/128")),
    Subnet(Ipv6(1, 2, 3, 4, 5, 6, 7, 8), NetworkMask(128)),
  )
  should.equal(
    should.be_ok(cidr.subnet("1:2:3:4:5:6:7:8/64")),
    Subnet(Ipv6(1, 2, 3, 4, 5, 6, 7, 8), NetworkMask(64)),
  )
  should.equal(
    should.be_ok(cidr.subnet("1A:2B:3C:4D:DD:FF:A1:11/64")),
    Subnet(Ipv6(26, 43, 60, 77, 221, 255, 161, 17), NetworkMask(64)),
  )
}

pub fn invalid_ipv6_subnet_test() {
  should.be_error(cidr.subnet("i am a cat"))
  should.be_error(cidr.subnet("i:am:a:cat:with/9 lives"))
  should.be_error(cidr.subnet("2B:3C:4D:DD:FF:A1:11/64"))
  should.be_error(cidr.subnet("XX:2B:3C:4D:DD:FF:A1:11/64"))
}

pub fn ipv4_inside_subnet_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("10.0.0.1/24"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, "10.0.0.66")),
    cidr.AddressIsInsideSubnet(
      Ipv4(10, 0, 0, 67),
      cidr.SubnetMetadata(Ipv4(10, 0, 0, 1), Ipv4(10, 0, 0, 254), 254, <<
        10,
        0,
        0,
      >>),
    ),
  )
}

pub fn ipv4_outside_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("10.0.0.1/24"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, "10.0.2.1")),
    cidr.AddressIsOutsideSubnet(
      cidr.SubnetMetadata(Ipv4(10, 0, 0, 1), Ipv4(10, 0, 0, 254), 254, <<
        10, 0, 0,
      >>),
    ),
  )
}

pub fn ipv4_unrelated_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("10.0.0.1/24"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, ":::::::1")),
    cidr.UnrelatedNetworkTypes,
  )
}

pub fn ipv4_error_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("10.0.0.1/24"))
  should.be_error(cidr.relationship(subnet, "i:am:a:cat!!"))
}

pub fn ipv6_inside_subnet_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("AAAA:::::::BBBB/64"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, "AAAA:::::::CCCC")),
    cidr.AddressIsInsideSubnet(
      Ipv6(52_429, 0, 0, 0, 0, 0, 0, 43_690),
      cidr.SubnetMetadata(
        Ipv6(43_690, 0, 0, 0, 0, 0, 0, 1),
        Ipv6(43_690, 0, 0, 0, 65_535, 65_535, 65_535, 65_534),
        18_446_744_073_709_551_614,
        <<170, 170, 0, 0, 0, 0, 0, 0>>,
      ),
    ),
  )
}

pub fn ipv6_outside_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("AAAA:CCCC::::::BBBB/64"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, "AAAA:DDDD::::::BBBB")),
    cidr.AddressIsOutsideSubnet(
      cidr.SubnetMetadata(
        Ipv6(43_690, 52_428, 0, 0, 0, 0, 0, 1),
        Ipv6(43_690, 52_428, 0, 0, 65_535, 65_535, 65_535, 65_534),
        18_446_744_073_709_551_614,
        <<170, 170, 204, 204, 0, 0, 0, 0>>,
      ),
    ),
  )
}

pub fn ipv6_unrelated_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("AAAA:CCCC::::::BBBB/64"))
  should.equal(
    should.be_ok(cidr.relationship(subnet, "192.168.1.1")),
    cidr.UnrelatedNetworkTypes,
  )
}

pub fn ipv6_error_relationship_test() {
  let subnet = should.be_ok(cidr.subnet("AAAA:CCCC::::::BBBB/64"))
  should.be_error(cidr.relationship(subnet, "i:am:a:cat!!"))
}
