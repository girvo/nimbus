import 
  ../constants, ../utils_numeric, ../computation,
  .. / vm / [gas_meter, stack], ../opcode, ../opcode_values,
  helpers, ttmath

proc add*(computation: var BaseComputation) =
  # Addition
  var (left, right) = computation.stack.popInt(2)
  
  var res = (left + right) and constants.UINT_256_MAX
  pushRes()

proc addmod*(computation: var BaseComputation) =
  # Modulo Addition
  var (left, right, arg) = computation.stack.popInt(3)

  var res = if arg == 0: 0.int256 else: (left + right) mod arg
  pushRes()

proc sub*(computation: var BaseComputation) =
  # Subtraction
  var (left, right) = computation.stack.popInt(2)

  var res = (left - right) and constants.UINT_256_MAX
  pushRes()


proc modulo*(computation: var BaseComputation) =
  # Modulo
  var (value, arg) = computation.stack.popInt(2)

  var res = if arg == 0: 0.int256 else: value mod arg
  pushRes()

proc smod*(computation: var BaseComputation) =
  # Signed Modulo
  var (value, arg) = computation.stack.popInt(2)
  value = unsignedToSigned(value)
  arg = unsignedToSigned(value)

  var posOrNeg = if value < 0: -1.int256 else: 1.int256
  var res = if arg == 0: 0.int256 else: ((value.abs mod arg.abs) * posOrNeg) and constants.UINT_256_MAX
  res = signedToUnsigned(res)
  pushRes()

proc mul*(computation: var BaseComputation) =
  # Multiplication
  var (left, right) = computation.stack.popInt(2)

  var res = (left * right) and constants.UINT_256_MAX
  pushRes()

proc mulmod*(computation: var BaseComputation) =
  #  Modulo Multiplication
  var (left, right, arg) = computation.stack.popInt(3)

  var res = if arg == 0: 0.int256 else: (left * right) mod arg
  pushRes()

proc divide*(computation: var BaseComputation) =
  # Division
  var (numerator, denominator) = computation.stack.popInt(2)

  var res = if denominator == 0: 0.int256 else: (numerator div denominator) and constants.UINT_256_MAX
  pushRes()

proc sdiv*(computation: var BaseComputation) =
  # Signed Division
  var (numerator, denominator) = computation.stack.popInt(2)
  numerator = unsignedToSigned(numerator)
  denominator = unsignedToSigned(denominator)

  var posOrNeg = if numerator * denominator < 0: -1.int256 else: 1.int256
  var res = if denominator == 0: 0.int256 else: (posOrNeg * (numerator.abs div denominator.abs))
  res = unsignedToSigned(res)
  pushRes()

# no curry
proc exp*(computation: var BaseComputation) =
  # Exponentiation
  var (base, exponent) = computation.stack.popInt(2)
  
  var bitSize = 0.int256 # TODO exponent.bitLength()
  var byteSize = ceil8(bitSize) div 8
  var res = if base == 0: 0.int256 else: (base ^ exponent.getInt) mod constants.UINT_256_CEILING
  # computation.gasMeter.consumeGas(
  #   gasPerByte * byteSize,
  #   reason="EXP: exponent bytes"
  # )
  pushRes()

proc signextend*(computation: var BaseComputation) =
  # Signed Extend
  var (bits, value) = computation.stack.popInt(2)

  var res: Int256
  if bits <= 31.int256:
    var testBit = bits.getInt * 8 + 7
    var signBit = (1.int256 shl testBit)
    res = if value != 0 and signBit != 0: value or (constants.UINT_256_CEILING - signBit) else: value and (signBit - 1.int256)
  else:
    res = value
  pushRes()
