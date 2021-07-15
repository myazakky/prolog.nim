import sequtils, tables, hashes

type TermKind = enum
  Variable
  Atom

type Term = ref object
  case kind: TermKind
  of Variable:
    variableName: string
  of Atom:
    atomValue: string

proc `==`(a, b: Term): bool =
  case a.kind
  of Variable:
    a.kind == b.kind and
      a.variableName == b.variableName
  of Atom:
    a.kind == b.kind and
      a.atomValue == b.atomValue

proc hash(t: Term): Hash =
  case t.kind
  of Variable:
    result = !$t.variableName.hash
  of Atom:
    result = !$t.atomValue.hash

type Predicate = ref object
  name: string
  arguments: seq[Term]

type Horn = ref object
  consequent: Predicate
  antecedent: seq[Predicate]

type Interpreter = ref object
  truths: seq[Horn]

proc is_true(interpreter: Interpreter, question: Predicate): bool =
  let can_be_base = interpreter.truths.filterIt(it.consequent.name == question.name)

  can_be_base.any(proc (horn: Horn): bool =
    let assignment = zip(horn.consequent.arguments, question.arguments)
    
    if not assignment.allIt(
      it[0].kind == Variable or (it[0].kind == Atom and it[0].atomValue == it[1].atomValue)
    ): return false

    if horn.antecedent.len == 0: return true

    horn.antecedent.all(proc (predicate: Predicate): bool = 
      let unificated = Predicate(
        name: predicate.name,
        arguments: predicate.arguments.mapIt(assignment.toTable[it])
      )

      interpreter.is_true(unificated)
    )
  )
