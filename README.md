# Prolog.nim

## 概要
Prologのnim実装．  
実際には，prologと呼べる代物ではない．正確に言うと，prolog風構文によるSLD証明戦略の実装．そのため，標準の処理系とはまったくもって異なっている．さらに，カット，ファンクタ，ユーザーによる解の決定も実装していない．これらはいずれ実装するかもしれないが．

## 使い方
```
$ nimble run
Prolog.nim
>> die(X) :- human(X).
>> human(socrates).
>> :- die(socrates).
true
>> :- die(X).
@[X: Var = socrates: Atom]
```

## 構文
```
<Var> ::= (UpperCase)
<Atom> ::= (not UpperCase)
<Term> ::= <Atom>|<Var>
<Literal> = ¬<Literal>|<任意の文字列>(<Term>*)
<Prologram> = <Literal>.|<Literal> :- <Literal>+|:- <Literal>+
```

## 参考
- https://www.jstage.jst.go.jp/article/jjsai/7/3/7_416/_pdf
- https://tamura70.gitlab.io/lect-proplogic/org/proplogic-system.pdf
