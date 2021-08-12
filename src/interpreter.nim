import sequtils, strformat, tables, hashes

type TermKind = enum
  Variable
  Atom

type Term = ref object
  case kind: TermKind
  of Variable:
    variableName: string
  of Atom:
    atomValue: string

proc hash(t: Term): Hash =
  case t.kind
  of Variable:
    t.variableName.hash
  of Atom:
    t.atomValue.hash

func `$`(t: Term): string =
  case t.kind:
  of Variable: t.variableName
  of Atom: t.atomValue

func `==`(t, u: Term): bool =
  if t.kind != u.kind: return false

  case t.kind
  of Variable:
    t.variableName == u.variableName
  of Atom:
    t.atomValue == u.atomValue

type Literal = ref object
  is_negative: bool
  name: string
  arguments: seq[Term]

func `¬`(literal: Literal): Literal =
  Literal(
    is_negative: not literal.is_negative,
    name: literal.name,
    arguments: literal.arguments)

func `$`(l: Literal): string =
  let prefix = if l.is_negative: "¬" else: ""
  result = prefix & l.name & $l.arguments

func `==`(l, m: Literal): bool = 
  l.is_negative == m.is_negative and l.name == m.name

func `===`(l, m: Literal): bool =
  l == m and (l.arguments == m.arguments)

type Clause = seq[Literal]

type Unificate = seq[tuple[a: Term, b: Term]]

func unificate(c: Clause, u: Unificate): Clause =
  let unification_table = u.toTable
  c.map(proc(l: Literal): Literal =
    let arguments = l.arguments.mapIt(
      if it.kind == Variable: unification_table[it]
      else: it
    )
    Literal(
      is_negative: l.is_negative,
      name: l.name,
      arguments: arguments))

type Interpreter = seq[Clause]

proc resolute(c1, c2: Clause): Clause =
  if c1.len >= c2.len:
    c1.filter(proc (l: Literal): bool =
      not c2.anyIt(it === ¬ l))
  else:
    c2.filter(proc (l: Literal): bool =
      not c1.anyIt(it === ¬ l))

proc can_make_unificate(l1, l2: Literal): bool =
  var i = 0
  l1.arguments.all(
    proc(t: Term): bool =
      result = if t.kind == Atom and l2.arguments[i].kind == Atom: t.atomValue == l2.arguments[i].atomValue
               else: true
      i.inc
  )

proc make_unificate(l1, l2: Literal): Unificate =
  var i = 0
  l1.arguments.map(
    proc(t: Term): tuple[a: Term, b: Term] =
      result = (t, l2.arguments[i])
      i.inc
  )

proc search(interpreter: Interpreter, target: Literal): Clause =
  let ¬target = ¬ target
  for c in interpreter:
    if c[0] == ¬target and can_make_unificate(c[0], target):
      return c
  
  @[]

proc is_contradiction(i: Interpreter, c: Clause): bool =
  let clause = search(i, c[0])

  if clause == @[]: return false

  let
    u = make_unificate(clause[0], c[0])
    resoluted_clause = clause.unificate(u)
    resolvent = resolute(resoluted_clause, c)

  if resolvent == @[]:
    true
  else:
    is_contradiction(i, resolvent)

proc probable(i: Interpreter, l: Literal): bool =
  is_contradiction(i, @[¬ l])

proc switch(u: Unificate): Unificate =
  u.mapIt((it.b, it.a))

proc search_solution(i: Interpreter, l: Literal): Unificate =
  let clause = search(i, l)
  if clause == @[]: return @[]

  let
    u = make_unificate(clause[0], l).switch
    resoluted_clause = @[l].unificate(u)
    resolvent = resolute(resoluted_clause, clause)

  if resolvent == @[]:
    concat(
      u.filterIt((it.a.kind, it.b.kind) == (Variable, Atom)),
      search_solution(i.filterIt(it != clause), l)
    )
  else:
    search_solution(i, resolvent[0])
