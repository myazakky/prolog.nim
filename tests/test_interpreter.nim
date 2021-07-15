import unittest

include "../src/interpreter"

test "前件がない場合(変数なし)の真偽判定":
  let proposition = Predicate(
      name: "human",
      arguments: @[Term(kind: Atom, atomValue: "socrates")])

  let socrates_is_human = Horn(consequent: proposition)

  let interpreter = Interpreter(truths: @[socrates_is_human])

  check(interpreter.is_true(proposition))

test "前件が無い場合(変数あり)の真偽判定":
  let proposition = Predicate(
      name: "in_the_world",
      arguments: @[Term(kind: Variable, variableName: "X")])

  let socrates_is_human = Horn(consequent: proposition)

  let interpreter = Interpreter(truths: @[socrates_is_human])

  check(interpreter.is_true(Predicate(
      name: "in_the_world",
      arguments: @[Term(kind: Atom, atomValue: "me")])))

test "前件がある場合の審議判定":
  let truths = @[
    Horn(
      consequent: Predicate(
        name: "human",
        arguments: @[Term(kind: Atom, atomValue: "socrates")]
      )),
    Horn(
      consequent: Predicate(
        name: "will_die",
        arguments: @[Term(kind: Variable, variableName: "X")]
      ),
      antecedent: @[Predicate(
        name: "human",
        arguments: @[Term(kind: Variable, variableName: "X")])])
  ]

  let interpreter = Interpreter(truths: truths)

  let question = Predicate(
    name: "will_die",
    arguments: @[Term(kind: Atom, atomValue: "socrates")]
  )

  check(interpreter.is_true(question))
