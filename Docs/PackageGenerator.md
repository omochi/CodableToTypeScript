# PackageGenerator

PackageGeneratorはTypeScriptコードの一括生成器です。
これに `SwiftTypeReader.Module` を渡す事により、そのモジュールに読み込まれたSwiftの型を、
一括でTypeScriptに変換し、ライブラリとして利用可能なソースファイルを含んだディレクトリを生成します。

モジュールは複数渡すこともできますが、複数のモジュールに同名の型が含まれる状況には対応していません。

生成されたディレクトリには、共通ライブラリの`common.ts`、型ごとのソースが含まれます。
例えば読み込んだモジュールに型`struct S`と`enum E`がある場合、`S.ts`と`E.ts`が生成されます。

## 外部参照

TypeMapやTypeConverterをカスタムすることによって、外部で定義したTypeScriptコードと連携させる事ができます。
生成するコードがこれらの外部シンボルを正しく`import`できるように、
外部シンボルを登録したSymbolTableを渡してください。
