pub type CIDRError {
  MaskError(error: String)
  AddressError(error: String)
  NotYetImplemented(error: String)
}
