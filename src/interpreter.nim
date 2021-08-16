import sequtils, tables, strutils
import lexer

type Pair = tuple[a: Term, b: Term]

func `$`(p: Pair): string =
  $p[0] & " = " & $p[1]

type Unification = seq[tuple[a: Term, b: Term]]

func unify(c: Clause, u: Unification): Clause =
  let unificationTable = u.toTable
  c.map(proc(l: Literal): Literal =
    let arguments = l.arguments.mapIt(
      if it.kind == Variable: unificationTable[it]
      else: it
    )
    Literal(
      isNegative: l.isNegative,
      name: l.name,
      arguments: arguments))

type Interpreter* = seq[Clause]

proc resolute(c1, c2: Clause): Clause =
  if c1.len >= c2.len:
    c1.filter(proc (l: Literal): bool =
      not c2.anyIt(it === ¬ l))
  else:
    c2.filter(proc (l: Literal): bool =
      not c1.anyIt(it === ¬ l))

proc canUnify(l1, l2: Literal): bool =
  var i = 0
  l1.arguments.all(
    proc(t: Term): bool =
    result = if t.kind == Atom and l2.arguments[i].kind == Atom: t.atomValue ==
        l2.arguments[i].atomValue
               else: true
    i.inc
  )

proc makeUnification(l1, l2: Literal): Unification =
  var i = 0
  l1.arguments.map(
    proc(t: Term): tuple[a: Term, b: Term] =
    result = (t, l2.arguments[i])
    i.inc
  )

proc searchClue(interpreter: Interpreter, target: Literal): Clause =
  let ¬target = ¬ target
  for c in interpreter:
    if c[0] == ¬target and canUnify(c[0], target):
      return c

  @[]

proc isContradiction(interpreter: Interpreter, targetClause: Clause): bool =
  let clueClause = searchClue(interpreter, targetClause[0])

  if clueClause == @[]: return false

  let
    u = makeUnification(clueClause[0], targetClause[0])
    resolutedClause = clueClause.unify(u)
    resolvent = resolute(resolutedClause, targetClause)

  if resolvent == @[]:
    true
  else:
    isContradiction(interpreter, resolvent)

proc switch(u: Unification): Unification =
  u.mapIt((it.b, it.a))

proc searchSolution(interpreter: Interpreter, literal: Literal): Unification =
  let clueClause = searchClue(interpreter, literal)
  if clueClause == @[]: return @[]

  let
    u = makeUnification(clueClause[0], literal).switch
    resolutedClause = @[literal].unify(u)
    resolvent = resolute(resolutedClause, clueClause)

  if resolvent == @[]:
    concat(
      u.filterIt((it.a.kind, it.b.kind) == (Variable, Atom)),
      searchSolution(interpreter.filterIt(it !== clueClause), literal)
    )
  else:
    searchSolution(interpreter, resolvent[0])

proc searchSolutions(i: Interpreter, c: Clause): Unification =
  c.mapIt(i.searchSolution(it)).foldl(concat(a.filterIt(b.contains(it)),
      b)).deduplicate

proc run*(i: var Interpreter) =
  var parsed: seq[string]
  var tokenized: seq[Literal]

  while true:
    write(stdout, ">> ")
    parsed = readLine(stdin).replace("\n", "").parse
    tokenized = parsed.tokenize
    if parsed[0] == ":-":
      if tokenized.anyIt(it.haveVariable):
        echo i.searchSolutions(tokenized)
      else:
        echo i.isContradiction(tokenized)
    else:
      i.add(tokenized)
