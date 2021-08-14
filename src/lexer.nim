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

func `==`*(t, u: Term): bool =
  if t.kind != u.kind: return false

  case t.kind
  of Variable:
    t.variableName == u.variableName
  of Atom:
    t.atomValue == u.atomValue

type Literal* = ref object
  is_negative*: bool
  name*: string
  arguments*: seq[Term]

proc new_literal*(is_negative = false, name = "", arguments: seq[Term] = @[]): Literal =
  Literal(
    is_negative: is_negative,
    name: name,
    arguments: arguments
  )

func `¬`*(literal: Literal): Literal =
  Literal(
    is_negative: not literal.is_negative,
    name: literal.name,
    arguments: literal.arguments)

func `$`*(l: Literal): string =
  let prefix = if l.is_negative: "¬" else: ""
  result = prefix & l.name & $l.arguments

func `==`*(l, m: Literal): bool = 
  l.is_negative == m.is_negative and l.name == m.name

func `===`*(l, m: Literal): bool =
  l == m and (l.arguments == m.arguments)

proc have_variable*(l: Literal): bool =
  l.arguments.anyIt(it.kind == Variable)

type Clause* = seq[Literal]

func `!==`*(c1, c2: Clause): bool =
  not zip(c1, c2).allIt(it[0] === it[1])

proc parse*(program: string): seq[string] =
  let chars = program.split(re"")

  var tokens = @[""]
  var token_number = 0
  for c in chars:
    if c == " ":
      tokens.add("")
      token_number.inc
    elif @["(", ")"].contains(c):
      tokens.add(c)
      tokens.add("")
      token_number += 2
    else:
      tokens[token_number] &= c.replace(".", "").replace(",", "")
  
  tokens

proc tokenize*(tokens: seq[string]): Clause =
  var clause: seq[Literal]
  var literal = new_literal()
  var is_analyzing_arguments = false
  var in_antecedent = false

  for t in tokens:
    case t:
    of ":-":
      in_antecedent = true
      literal.is_negative = true
      continue
    of "(":
      is_analyzing_arguments = true
      continue
    of ")":
      is_analyzing_arguments = false
      clause.add(literal)
      literal = new_literal(is_negative = in_antecedent)
      continue

    if is_analyzing_arguments and t[0].isUpperAscii:
      literal.arguments.add(Term(
        kind: Variable,
        variableName: t
      ))
    elif is_analyzing_arguments and t[0].isLowerAscii:
      literal.arguments.add(Term(
        kind: Atom,
        atomValue: t
      ))
    else:
      literal.name = t
  clause.add(literal)
  clause
