import sequtils, strutils, re
import interpreter

type LiteralType = enum
  True
  Question

proc parse(program: string): seq[string] =
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
      tokens[token_number] &= c.split(",")[0]
  
  tokens

proc tokenize(tokens: seq[string]): Clause =
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

  clause
