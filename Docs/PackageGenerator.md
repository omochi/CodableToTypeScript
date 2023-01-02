# PackageGenerator

PackageGeneratorはTypeScriptコードの一括生成器です。
これは `SwiftTypeReader.Module` を受け取り、
そのモジュールに含まれるSwiftのソースファイルをそれぞれTypeScriptのソースファイルに変換し、
ライブラリとして利用可能なディレクトリを生成します。

モジュールは複数渡すこともできますが、複数のモジュールに同名の型が含まれる状況には対応していません。

生成されたディレクトリには、共通ライブラリの`common.ts`と、個別のソースファイルが含まれます。
例えば読み込んだモジュールに型`a.swift`と`b.swift`があった場合、`a.ts`と`b.ts`が生成されます。

## 外部参照

TypeMapやTypeConverterをカスタムすることによって、外部で定義したTypeScriptコードと連携させる事ができます。
生成するコードがこれらの外部シンボルを正しく`import`できるように、
外部シンボルを登録したSymbolTableを渡してください。
