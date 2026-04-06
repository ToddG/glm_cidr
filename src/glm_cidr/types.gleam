////  let <<ainteger, b/integer, c/integer, d/integer>> = address

import glm_cidr/mask

pub type InetAddress {
  Ipv4InetAddress(address: Int)
  Ipv6InetAddress(address: Int)
}

pub type InetAddressElement {
  Ipv4InetAddressElement(address: Int)
  Ipv6InetAddressElement(address: Int)
}

pub type Subnet {
  Ipv4Subnet(
    address: InetAddress,
    mask: mask.Mask,
    first: InetAddress,
    last: InetAddress,
    count: Int,
  )
  Ipv6Subnet(
    address: InetAddress,
    mask: mask.Mask,
    first: InetAddress,
    last: InetAddress,
    count: Int,
  )
}

// TODO: not sure how to use bitstrings...doh
//pub fn pretty_print(inet_address: InetAddress) -> String {
//  case inet_address {
//    Ipv6InetAddress(<<
//        a:size(16),
//        b:size(16),
//        c:size(16),
//        d:size(16),
//        e:size(16),
//        f:size(16),
//        g:size(16),
//        h:size(16)
//      >>) -> {
//      [a,b,c,d,e,f,g,h]
//      |> list.map(int.to_base16)
//      |> string.join(":")
//    }
//    Ipv4InetAddress(address) -> {
//      let <<
//      a:size(8),
//      b:size(8),
//      c:size(8),
//      d:size(8),
//      >> = <<address:size(32)>>
//      [a,b,c,d]
//      |> list.map(int.to_string)
//      |> string.join(".")
//    }
//  }
//}
