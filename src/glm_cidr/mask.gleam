import gleam/result
import glm_cidr/errors.{type CIDRError, MaskError}
import glm_cidr/constants.{negative_num_mask_bits_error,zero_num_mask_bits_error,}
import glm_cidr/internal/mask_private

pub opaque type Mask {
  Ipv4Mask(mask: Int)
  Ipv6Mask(mask: Int)
}

pub fn ipv4_mask_from_int(num_bits: Int) -> Result(Mask, CIDRError) {
  case num_bits {
    b if b < 0 -> Error(MaskError(negative_num_mask_bits_error))
    0 -> Error(MaskError(zero_num_mask_bits_error))
    b if b <= 32 -> mask_private.shift_ipv4_mask_bits(b) |> result.map(Ipv4Mask)
    _ -> Error(MaskError(constants.ipv4_large_address_element_error))
  }
}

pub fn ipv6_mask_from_int(num_bits: Int) -> Result(Mask, CIDRError) {
  case num_bits {
    b if b < 0 -> Error(MaskError(negative_num_mask_bits_error))
    0 -> Error(MaskError(zero_num_mask_bits_error))
    b if b <= 128 -> mask_private.shift_ipv6_mask_bits(b) |> result.map(Ipv6Mask)
    _ -> Error(MaskError(constants.ipv6_large_address_element_error))
  }
}

pub fn mask_to_int(m: Mask) -> Int {
  m.mask
}
