import gleeunit
import gleeunit/should
import glm_cidr/cidr.{
  Ipv4, Ipv4NetMask, Ipv4Subnet, Ipv6, Ipv6NetMask, Ipv6Subnet,
}

pub fn main() -> Nil {
  gleeunit.main()
}

//  # python
//  >>> for x in range(0, 33):
//  ...     mask = (2**x -1) << (32 -x)
//  ...     print(f"const ipv4_two_exp_{x}_netmask = {mask}")


//const ipv4_two_exp_1_netmask = 2_147_483_648
//
//const ipv4_two_exp_2_netmask = 3_221_225_472
//
//const ipv4_two_exp_3_netmask = 3_758_096_384
//
//const ipv4_two_exp_4_netmask = 4_026_531_840
//
//const ipv4_two_exp_5_netmask = 4_160_749_568
//
//const ipv4_two_exp_6_netmask = 4_227_858_432
//
//const ipv4_two_exp_7_netmask = 4_261_412_864
//
//const ipv4_two_exp_8_netmask = 4_278_190_080
//
//const ipv4_two_exp_9_netmask = 4_286_578_688
//
//const ipv4_two_exp_10_netmask = 4_290_772_992
//
//const ipv4_two_exp_11_netmask = 4_292_870_144
//
//const ipv4_two_exp_12_netmask = 4_293_918_720
//
//const ipv4_two_exp_13_netmask = 4_294_443_008
//
//const ipv4_two_exp_14_netmask = 4_294_705_152
//
//const ipv4_two_exp_15_netmask = 4_294_836_224
//
//const ipv4_two_exp_16_netmask = 4_294_901_760
//
//const ipv4_two_exp_17_netmask = 4_294_934_528
//
//const ipv4_two_exp_18_netmask = 4_294_950_912
//
//const ipv4_two_exp_19_netmask = 4_294_959_104
//
//const ipv4_two_exp_20_netmask = 4_294_963_200
//
//const ipv4_two_exp_21_netmask = 4_294_965_248
//
//const ipv4_two_exp_22_netmask = 4_294_966_272
//
//const ipv4_two_exp_23_netmask = 4_294_966_784
//
const ipv4_two_exp_24_netmask = 4_294_967_040
//
//const ipv4_two_exp_25_netmask = 4_294_967_168
//
//const ipv4_two_exp_26_netmask = 4_294_967_232
//
//const ipv4_two_exp_27_netmask = 4_294_967_264
//
//const ipv4_two_exp_28_netmask = 4_294_967_280
//
//const ipv4_two_exp_29_netmask = 4_294_967_288
//
//const ipv4_two_exp_30_netmask = 4_294_967_292
//
//const ipv4_two_exp_31_netmask = 4_294_967_294

const ipv4_two_exp_32_netmask = 4_294_967_295

//  # python
//  >>> for x in range(0, 33):
//  ...     mask = (2**x -1) << (32 -x)
//  ...     print(f"// ipv4_two_exp_{x}_netmask (bitstring) -> {bin(mask)}")

// ipv4_two_exp_1_netmask (bitstring) -> 0b10000000000000000000000000000000
// ipv4_two_exp_2_netmask (bitstring) -> 0b11000000000000000000000000000000
// ipv4_two_exp_3_netmask (bitstring) -> 0b11100000000000000000000000000000
// ipv4_two_exp_4_netmask (bitstring) -> 0b11110000000000000000000000000000
// ipv4_two_exp_5_netmask (bitstring) -> 0b11111000000000000000000000000000
// ipv4_two_exp_6_netmask (bitstring) -> 0b11111100000000000000000000000000
// ipv4_two_exp_7_netmask (bitstring) -> 0b11111110000000000000000000000000
// ipv4_two_exp_8_netmask (bitstring) -> 0b11111111000000000000000000000000
// ipv4_two_exp_9_netmask (bitstring) -> 0b11111111100000000000000000000000
// ipv4_two_exp_10_netmask (bitstring) -> 0b11111111110000000000000000000000
// ipv4_two_exp_11_netmask (bitstring) -> 0b11111111111000000000000000000000
// ipv4_two_exp_12_netmask (bitstring) -> 0b11111111111100000000000000000000
// ipv4_two_exp_13_netmask (bitstring) -> 0b11111111111110000000000000000000
// ipv4_two_exp_14_netmask (bitstring) -> 0b11111111111111000000000000000000
// ipv4_two_exp_15_netmask (bitstring) -> 0b11111111111111100000000000000000
// ipv4_two_exp_16_netmask (bitstring) -> 0b11111111111111110000000000000000
// ipv4_two_exp_17_netmask (bitstring) -> 0b11111111111111111000000000000000
// ipv4_two_exp_18_netmask (bitstring) -> 0b11111111111111111100000000000000
// ipv4_two_exp_19_netmask (bitstring) -> 0b11111111111111111110000000000000
// ipv4_two_exp_20_netmask (bitstring) -> 0b11111111111111111111000000000000
// ipv4_two_exp_21_netmask (bitstring) -> 0b11111111111111111111100000000000
// ipv4_two_exp_22_netmask (bitstring) -> 0b11111111111111111111110000000000
// ipv4_two_exp_23_netmask (bitstring) -> 0b11111111111111111111111000000000
// ipv4_two_exp_24_netmask (bitstring) -> 0b11111111111111111111111100000000
// ipv4_two_exp_25_netmask (bitstring) -> 0b11111111111111111111111110000000
// ipv4_two_exp_26_netmask (bitstring) -> 0b11111111111111111111111111000000
// ipv4_two_exp_27_netmask (bitstring) -> 0b11111111111111111111111111100000
// ipv4_two_exp_28_netmask (bitstring) -> 0b11111111111111111111111111110000
// ipv4_two_exp_29_netmask (bitstring) -> 0b11111111111111111111111111111000
// ipv4_two_exp_30_netmask (bitstring) -> 0b11111111111111111111111111111100
// ipv4_two_exp_31_netmask (bitstring) -> 0b11111111111111111111111111111110
// ipv4_two_exp_32_netmask (bitstring) -> 0b11111111111111111111111111111111

//  # python
//  >>> for x in range(0, 129,16):
//  ...     mask = (2**x -1) << (128 -x)
//  ...     print(f"const ipv6_two_exp_{x}_netmask = {mask}")

//const ipv6_two_exp_0_netmask = 0
//const ipv6_two_exp_16_netmask = 340277174624079928635746076935438991360
//const ipv6_two_exp_32_netmask = 340282366841710300949110269838224261120
//const ipv6_two_exp_48_netmask = 340282366920937254537554992802593505280
const ipv6_two_exp_64_netmask = 340282366920938463444927863358058659840
//const ipv6_two_exp_80_netmask = 340282366920938463463374325956791500800
//const ipv6_two_exp_96_netmask = 340282366920938463463374607427473244160
//const ipv6_two_exp_112_netmask = 340282366920938463463374607431768145920
const ipv6_two_exp_128_netmask = 340282366920938463463374607431768211455

//  # python
//  >>> for x in range(0, 129,16):
//  ...     mask = (2**x -1) << (128 -x)
//  ...     # print(f"const ipv6_two_exp_{x}_netmask = {mask}")
//  ...     print(f"// ipv6_two_exp_{x}_netmask (bitstring) -> {bin(mask)}")

// ipv6_two_exp_0_netmask (bitstring) -> 0b0
// ipv6_two_exp_16_netmask (bitstring) -> 0b11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// ipv6_two_exp_32_netmask (bitstring) -> 0b11111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// ipv6_two_exp_48_netmask (bitstring) -> 0b11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
// ipv6_two_exp_64_netmask (bitstring) -> 0b11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
// ipv6_two_exp_80_netmask (bitstring) -> 0b11111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000
// ipv6_two_exp_96_netmask (bitstring) -> 0b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000
// ipv6_two_exp_112_netmask (bitstring) -> 0b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
// ipv6_two_exp_128_netmask (bitstring) -> 0b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

pub fn valid_ipv4_subnet_test() {
  should.equal(
    should.be_ok(cidr.subnet("192.168.1.1/32")),
    Ipv4Subnet(Ipv4(192, 168, 1, 1), Ipv4NetMask(ipv4_two_exp_32_netmask)),
  )
  should.equal(
    should.be_ok(cidr.subnet("10.0.0.1/24")),
    Ipv4Subnet(Ipv4(10, 0, 0, 1), Ipv4NetMask(ipv4_two_exp_24_netmask)),
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
    Ipv6Subnet(
      Ipv6(0, 0, 0, 0, 0, 0, 0, 1),
      Ipv6NetMask(ipv6_two_exp_128_netmask),
    ),
  )
  should.equal(
    should.be_ok(cidr.subnet("1:2:3:4:5:6:7:8/128")),
    Ipv6Subnet(
      Ipv6(1, 2, 3, 4, 5, 6, 7, 8),
      Ipv6NetMask(ipv6_two_exp_128_netmask),
    ),
  )
  should.equal(
    should.be_ok(cidr.subnet("1:2:3:4:5:6:7:8/64")),
    Ipv6Subnet(
      Ipv6(1, 2, 3, 4, 5, 6, 7, 8),
      Ipv6NetMask(ipv6_two_exp_64_netmask),
    ),
  )
  should.equal(
    should.be_ok(cidr.subnet("1A:2B:3C:4D:DD:FF:A1:11/64")),
    Ipv6Subnet(
      Ipv6(26, 43, 60, 77, 221, 255, 161, 17),
      Ipv6NetMask(ipv6_two_exp_64_netmask),
    ),
  )
}

pub fn invalid_ipv6_subnet_test() {
  should.be_error(cidr.subnet("i am a cat"))
  should.be_error(cidr.subnet("i:am:a:cat:with/9 lives"))
  should.be_error(cidr.subnet("2B:3C:4D:DD:FF:A1:11/64"))
  should.be_error(cidr.subnet("XX:2B:3C:4D:DD:FF:A1:11/64"))
}
