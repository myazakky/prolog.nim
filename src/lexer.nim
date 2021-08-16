import sequtils, strutils, re, hashes

type TermKind* = enum
  Variable
  Atom

type Term* = ref object
  case kind*: TermKind
  of Variable:
    variableName*: string
  of Atom:
    atomValue*: string

proc hash*(t: Term): Hash =
  case t.kind
  of Variable:
    t.variableName.hash
  of Atom:
    t.atomValue.hash

func `$`*(t: Term): string =
  case t.kind:
  of Variable: t.variableName & ": Var"
  of Atom: t.atomValue & ": Atom"

func `==`*(t1, t2: Term): bool =
  if t1.kind != t2.kind: return false

  case t1.kind
  of Variable:
    t1.variableName == t2.variableName
  of Atom:
    t1.atomValue == t2.atomValue

type Literal* = ref object
  isNegative*: bool
  name*: string
  arguments*: seq[Term]

proc newLiteral*(isNegative = false, name = "", arguments: seq[Term] = @[]): Literal =
  Literal(
    isNegative: isNegative,
    name: name,
    arguments: arguments
  )

func `¬`*(l: Literal): Literal =
  Literal(
    isNegative: not l.isNegative,
    name: l.name,
    arguments: l.arguments)

func `$`*(l: Literal): string =
  let prefix = if l.isNegative: "¬" else: ""
  result = prefix & l.name & $l.arguments

func `==`*(l1, l2: Literal): bool =
  l1.isNegative == l2.isNegative and l1.name == l2.name

func `===`*(l1, l2: Literal): bool =
  l1 == l2 and (l1.arguments == l2.arguments)

proc haveVariable*(l: Literal): bool =
  l.arguments.anyIt(it.kind == Variable)

type Clause* = seq[Literal]

func `!==`*(c1, c2: Clause): bool =
  not zip(c1, c2).allIt(it[0] === it[1])

proc parse*(program: string): seq[string] =
  let chars = program.split(re"")

  var tokens = @[""]
  var tokenNumber = 0
  for c in chars:
    case c
    of " ":
      tokens.add("")
      tokenNumber.inc
    of "(", ")":
      tokens.add(c)
      tokens.add("")
      tokenNumber += 2
    else:
      tokens[tokenNumber] &= c.replace(".", "").replace(",", "")

  tokens.filterIt(it != "")

proc tokenize*(tokens: seq[string]): Clause =
  var clause: seq[Literal]
  var isAnalyzingArguments = false
  var inAntecedent = false

  for t in tokens:
    case t:
    of ":-":
      inAntecedent = true
      continue
    of "(":
      isAnalyzingArguments = true
      continue
    of ")":
      isAnalyzingArguments = false
      continue

    if isAnalyzingArguments and t[0].isUpperAscii:
      clause[-1].arguments.add(Term(
        kind: Variable,
        variableName: t
      ))
    elif isAnalyzingArguments and not t[0].isUpperAscii:
      clause[-1].arguments.add(Term(
        kind: Atom,
        atomValue: t
      ))
    else:
      clause.add(newLiteral(isNegative = inAntecedent, name = t))

  clause
