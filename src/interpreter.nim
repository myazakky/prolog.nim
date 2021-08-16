import sequtils, tables, strutils
import lexer

type Pair = tuple[a: Term, b: Term]

func `$`(p: Pair): string =
  $p[0] & " = " & $p[1]

type Unificate = seq[tuple[a: Term, b: Term]]

func unificate(c: Clause, u: Unificate): Clause =
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

proc canMakeUnificate(l1, l2: Literal): bool =
  var i = 0
  l1.arguments.all(
    proc(t: Term): bool =
    result = if t.kind == Atom and l2.arguments[i].kind == Atom: t.atomValue ==
        l2.arguments[i].atomValue
               else: true
    i.inc
  )

proc makeUnificate(l1, l2: Literal): Unificate =
  var i = 0
  l1.arguments.map(
    proc(t: Term): tuple[a: Term, b: Term] =
    result = (t, l2.arguments[i])
    i.inc
  )

proc search(interpreter: Interpreter, target: Literal): Clause =
  let ¬target = ¬ target
  for c in interpreter:
    if c[0] == ¬target and canMakeUnificate(c[0], target):
      return c

  @[]

proc isContradiction(i: Interpreter, c: Clause): bool =
  let clause = search(i, c[0])

  if clause == @[]: return false

  let
    u = makeUnificate(clause[0], c[0])
    resolutedClause = clause.unificate(u)
    resolvent = resolute(resolutedClause, c)

  if resolvent == @[]:
    true
  else:
    isContradiction(i, resolvent)

proc switch(u: Unificate): Unificate =
  u.mapIt((it.b, it.a))

proc searchSolution(i: Interpreter, l: Literal): Unificate =
  let clause = search(i, l)
  if clause == @[]: return @[]

  let
    u = makeUnificate(clause[0], l).switch
    resolutedClause = @[l].unificate(u)
    resolvent = resolute(resolutedClause, clause)

  if resolvent == @[]:
    concat(
      u.filterIt((it.a.kind, it.b.kind) == (Variable, Atom)),
      searchSolution(i.filterIt(it !== clause), l)
    )
  else:
    searchSolution(i, resolvent[0])

proc searchSolutions(i: Interpreter, c: Clause): Unificate =
  c.mapIt(i.searchSolution(it)).foldl(concat(a.filterIt(b.contains(it)),
      b)).deduplicate

proc run*(i: var Interpreter) =
  var parsed: seq[string]
  while true:
    write(stdout, ">> ")
    parsed = readLine(stdin).replace("\n", "").parse
    if parsed[0] == ":-":
      var tokenized = parsed.tokenize
      if tokenized.anyIt(it.haveVariable):
        echo i.searchSolutions(tokenized)
      else:
        echo i.isContradiction(tokenized)
    else:
      i.add(parsed.tokenize)
