import sequtils

type TermKind = enum
  Variable
  Atom

type Term = ref object
  case kind: TermKind
  of Variable:
    variableName: string
  of Atom:
    atomValue: string

type Predicate = ref object
  name: string
  arguments: seq[Term]

type Horn = ref object
  consequent: Predicate
  antecedent: seq[Term]

type Interpreter = ref object
  truths: seq[Horn]

func is_true(interpreter: Interpreter, predicate: Predicate): bool =
  interpreter.truths.any(proc (horn: Horn): bool =
    horn.consequent.name == predicate.name and
      zip(horn.consequent.arguments, predicate.arguments).anyIt(
        it[0].kind == Variable or (it[0].kind == Atom and it[0].atomValue == it[1].atomValue)
      )
  )
