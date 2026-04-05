import gleam/float
import gleam/int
import gleam/result
import gleam/string
import glm_cidr/errors.{type CIDRError, MaskError}
import glm_cidr/constants.{ipv6_max_mask_bits,ipv6_large_mask_error}

pub fn shift_ipv4_mask_bits(num_bits: Int) -> Result(Int, CIDRError){
  create_mask_bits(num_bits) |> result.map(int.bitwise_shift_left(_, 32 - num_bits))
}

pub fn shift_ipv6_mask_bits(num_bits: Int) -> Result(Int, CIDRError){
  create_mask_bits(num_bits) |> result.map(int.bitwise_shift_left(_, 128 - num_bits))
}

pub fn create_mask_bits(num_bits: Int) -> Result(Int, CIDRError) {
  case num_bits {
    0 -> Error(MaskError(constants.zero_num_mask_bits_error))
    b if b > ipv6_max_mask_bits ->
      Error(MaskError(
        ipv6_large_mask_error <> ", too many bits: " <> num_bits |> int.to_string,
      ))
    b -> {
      let exponent = b |> int.to_float
      int.power(2, exponent)
      |> result.map(float.truncate)
      |> result.map(fn(x) { x - 1 })
      |> result.map_error(fn(e) {
        MaskError("unknown mask error: " <> string.inspect(e))
      })
    }
  }
}
