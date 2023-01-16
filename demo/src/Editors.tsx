import Editor, { useMonaco } from "@monaco-editor/react";
import * as monaco from "monaco-editor";
import { useCallback, useEffect, useState } from "react";
import { useC2TS } from "./C2TSContext";
import { Generator } from "./Gen/Generator.gen";
import { useColorScheme } from "./Utils";

type GeneratorState = {
  isReady: false,
  generator?: never,
} | {
  isReady: true,
  generator: Generator,
};

const useGenerator = (): GeneratorState => {
  const { isReady } = useC2TS();
  const [g, setG] = useState<Generator | null>(null);
  useEffect(() => {
    if (isReady) {
      setG(new Generator());
    }
  }, [isReady]);

  if (g == null) {
    return { isReady: false };
  }
  return { isReady: true, generator: g };
}

export const Editors: React.FC = () => {
  const monaco = useMonaco();
  const { isReady, generator } = useGenerator();
  const theme = useColorScheme() === "light" ? "light" : "vs-dark";

  const [swiftEditor, setSwiftEditor] = useState<monaco.editor.IStandaloneCodeEditor | null>(null);
  const [tsEditor, setTsEditor] = useState<monaco.editor.IStandaloneCodeEditor | null>(null);

  const updateTSCode = useCallback(() => {
    if (!isReady || !swiftEditor || !tsEditor) return;
    try {
      const source = generator.tsTypes(swiftEditor.getValue());
      tsEditor.setValue(source);
    } catch (e) {
      if (e instanceof Error) {
        tsEditor.setValue(e.message);
      } else {
        tsEditor.setValue((e as any).toString());
      }
    }
  }, [isReady, swiftEditor, tsEditor]);

  useEffect(() => {
    // when all components ready, convert default initial code
    if (isReady && swiftEditor && tsEditor) {
      // install common library
      try {
        monaco?.editor.createModel(
          generator.commonLib(),
          "typescript",
          monaco.Uri.from({ scheme: "file", path: "./common.gen.ts" })
        );
      } catch (e) {console.error(e);}
      updateTSCode();
    }
  }, [isReady, swiftEditor, tsEditor, updateTSCode]);

  return <>
    <div style={{ flex: 1 }}>
      <Editor
        defaultLanguage="swift"
        defaultValue={defaultSwiftCode}
        onMount={setSwiftEditor}
        path="/Types.swift"
        options={{
          minimap: {
            enabled: false,
          },
        }}
        onChange={updateTSCode}
        theme={theme}
      />
    </div>
    <div style={{ flex: 1 }}>
      <Editor
        defaultLanguage="typescript"
        defaultValue="Loading CodableToTypeScript wasm binary..."
        onMount={setTsEditor}
        path="/types.gen.ts"
        options={{
          minimap: {
            enabled: false,
          },
        }}
        theme={theme}
      />
    </div>
  </>
}

const defaultSwiftCode = `// Write swift code here!

enum Language: String, Codable {
  case swift
  case typescript
}

struct User: Codable {
  var name: String
  var favorite: Language
}
`;
