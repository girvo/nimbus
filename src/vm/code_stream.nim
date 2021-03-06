import
  strformat, strutils, sequtils, sets, macros,
  ../logging, ../constants, ../opcode_values

type
  CodeStream* = ref object
    bytes: seq[byte]
    depthProcessed: int
    invalidPositions: HashSet[int]
    pc*: int
    logger: Logger

proc `$`*(b: byte): string =
  $(b.int)

proc newCodeStream*(codeBytes: seq[byte]): CodeStream =
  new(result)
  result.bytes = codeBytes
  result.pc = 0
  result.invalidPositions = initSet[int]()
  result.depthProcessed = 0
  result.logger = logging.getLogger("vm.code_stream")

proc newCodeStream*(codeBytes: string): CodeStream =
  newCodeStream(codeBytes.mapIt(it.byte))

proc read*(c: var CodeStream, size: int): seq[byte] =
  if c.pc + size - 1 < c.bytes.len:
    result = c.bytes[c.pc .. c.pc + size - 1]
    c.pc += size
  else:
    result = @[]
    c.pc = c.bytes.len

proc len*(c: CodeStream): int =
  len(c.bytes)

proc next*(c: var CodeStream): Op =
  var nextOpcode = c.read(1)
  if nextOpcode.len != 0:
    return Op(nextOpcode[0])
  else:
    return Op.STOP

iterator items*(c: var CodeStream): Op =
  var nextOpcode = c.next()
  while nextOpcode != Op.STOP:
    yield nextOpcode
    nextOpcode = c.next()

proc `[]`*(c: CodeStream, offset: int): Op =
  Op(c.bytes[offset])

proc peek*(c: var CodeStream): Op =
  var currentPc = c.pc
  result = c.next()
  c.pc = currentPc

proc updatePc*(c: var CodeStream, value: int) =
  c.pc = min(value, len(c))

macro seek*(c: var CodeStream, pc: int, handler: untyped): untyped =
  let c2 = ident("c")
  result = quote:
    var anchorPc = `c`.pc
    `c`.pc = `pc`
    try:
      var `c2` = `c`
      `handler`
    finally:
      `c`.pc = anchorPc

proc isValidOpcode*(c: var CodeStream, position: int): bool =
  if position >= len(c):
    return false
  if position in c.invalidPositions:
    return false
  if position <= c.depthProcessed:
    return true
  else:
    var i = c.depthProcessed
    while i <= position:
      var opcode = Op(c[i])
      if opcode >= Op.PUSH1 and opcode <= Op.PUSH32:
        var leftBound = (i + 1)
        var rightBound = leftBound + (opcode.int - 95)
        for z in leftBound ..< rightBound:
          c.invalidPositions.incl(z)
        i = rightBound
      else:
        c.depthProcessed = i
        i += 1
    if position in c.invalidPositions:
      return false
    else:
      return true
