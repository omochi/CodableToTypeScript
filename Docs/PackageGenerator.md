# PackageGenerator

PackageGeneratorはTypeScriptコードの一括生成器です。
これに `SwiftTypeReader.Module` を渡す事により、そのモジュールに読み込まれたSwiftの型を、
一括でTypeScriptに変換し、ライブラリとして利用可能なソースファイルを含んだディレクトリを生成します。

モジュールは複数渡すこともできますが、複数のモジュールに同名の型が含まれる状況には対応していません。

生成されたディレクトリには、共通ライブラリの`common.ts`、型ごとのソースが含まれます。
例えば読み込んだモジュールに型`struct S`と`enum E`がある場合、`S.ts`と`E.ts`が生成されます。
状況に応じて、`externals.ts`が生成されます。これについては後述します。

## 外部参照

TypeMapやTypeConverterをカスタムすることによって、外部で定義したTypeScriptコードと連携させる事ができます。
この際、コード生成は外部のシンボルが全て`externals.ts`に定義されているものとして行われます。
ここで必要な外部シンボルの一覧と、`externals.ts`の実装は、
ユーザーが`ExternalReference`型のオブジェクトとして`PackageGenerator`に指定します。

例えばTypeMapを使うことで、Swiftの`Date`型をTypeScriptの`Date`型にトランスパイルさせる事ができます。
その際に`Date`型のJSON表現と、JSON表現との相互変換関数を指定します。
そして変換関数として`Date_decode`と`Date_encode`を指定する場合を考えます。

これらの関数は`custom.ts`というファイルに定義され、PackageGeneratorは`swift`ディレクトリにコードを生成するとします。

```
src/
├ custom.ts
└ swift/
　 ├ common.ts
　 ├ S.ts
　 └ externals.ts
```

いや、やっぱり仕様を変えよう。
