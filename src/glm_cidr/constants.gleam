// -------------------------------------------------------------------------------
// ipv4 constants
// -------------------------------------------------------------------------------
// 32 bits (4 hex chars)
pub const ipv4_max_mask_bits = 32

pub const negative_num_mask_bits_error = "num mask bits cannot be negative, valid values 1 to 32 for ipv4, 1 to 128 for ipv6"

pub const zero_num_mask_bits_error = "num mask bits cannot be zero, valid values 1 to 32 for ipv4, 1 to 128 for ipv6"

pub const ipv4_large_mask_error = "mask too large, valid values 1 to 32"

// 8 bit words (address elements)
pub const ipv4_max_address_element_value = 0xFF

pub const ipv4_invalid_address_error = "valid address is a string formatted as: '[0-255].[0-255].[0-255].[0-255]'. this is an invalid address list: "


pub const ipv4_address_element_parse_error = "failed to parse address element, values should be (base 10) values between 0 and 255; error: "

pub const ipv4_negative_address_element_error = "address element cannot be negative, ipv4 address elements must be between 0 and 255"

pub const ipv4_large_address_element_error = "address element cannot be greater than 255, ipv4 address elements must be between 0 and 255"

// -------------------------------------------------------------------------------
// ipv6 constants
// -------------------------------------------------------------------------------
// 128 bits (32 hex chars)
pub const ipv6_max_mask_bits = 128

pub const ipv6_negative_mask_error = "mask cannot be negative, valid values 0 to 2**128"

pub const ipv6_large_mask_error = "mask number of bits cannot be greater than 128, valid values 0 to 128"


// 16 bit words (address elements)
pub const ipv6_max_address_element_value = 0xFFFF

pub const ipv6_invalid_address_error = "valid address is a string formatted as 8 4 (or zero) hex character elements
delimited with a ':', like this: 'FFFF:FFFF:FFFF::::FFFF:FFFF'; this is an invalid address list, count: "


pub const ipv6_address_element_parse_error = "failed to parse address element, values should be 4 hex chars with
a value between 2**16; error: "

pub const ipv6_negative_address_element_error = "address element cannot be negative, ipv6 address elements must be
between 0 and 2**16"

pub const ipv6_large_address_element_error = "address element cannot be greater than 2**16, ipv6 address elements
must be between 0 and 2**16"

pub const malformed_address_string = "malformed address string, must contain either ':' delimited ipv6 address,
or '.' delimited ipv4 address"

pub const mismatched_subnet_and_address_error = "mismatched subnet and address both must be ipv4 or ipv6"

pub const address_not_contained_in_subnet_error = "the provided address is not contained by the subnet"

pub const subnet_full_error = "subnet full, next address is not contained within the subnet, address: "
