import unittest

include "../src/interpreter"

let
  dx = Literal(
    is_negative: false,
    name: "d",
    arguments: @[Term(kind: Variable, variableName: "X")])

  hx = Literal(
    is_negative: false,
    name: "h",
    arguments: @[Term(kind: Variable, variableName: "X")])

  hs = Literal(
    is_negative: false,
    name: "h",
    arguments: @[Term(kind: Atom, atomValue: "s")])

  pxs = Literal(
    is_negative: false,
    name: "p",
    arguments: @[Term(kind: Variable, variableName: "X"),
                 Term(kind: Atom, atomValue: "s")])

  pms = Literal(
    is_negative: false,
    name: "p",
    arguments: @[Term(kind: Atom, atomValue: "m"),
                 Term(kind: Atom, atomValue: "s")])

  dm = Literal(
    is_negative: false,
    name: "d",
    arguments: @[Term(kind: Atom, atomValue: "m")])


  Γpl = Interpreter(@[
    @[dx, ¬ hx],
    @[hs],
    @[hx, ¬ pxs],
    @[pms]
  ])
