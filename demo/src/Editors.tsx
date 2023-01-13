import Editor from "@monaco-editor/react";
import * as monaco from "monaco-editor";
import { useCallback, useEffect, useState } from "react";
import { useC2TS } from "./C2TSContext";
import { C2TS } from "./Gen/C2TS.gen";

type ConverterState = {
  isReady: false,
  convert?: never,
} | {
  isReady: true,
  convert: (v: string) => string,
};

const useConverter = (): ConverterState => {
  const { isReady } = useC2TS();

  const [c2ts, setC2ts] = useState<C2TS | null>(null);
  useEffect(() => {
    if (isReady) {
      setC2ts(new C2TS());
    }
  }, [isReady]);

  if (c2ts == null) {
    return { isReady: false }
  }

  return {
    isReady: true,
    convert: c2ts.convert.bind(c2ts),
  }
}

export const Editors: React.FC = () => {
  const { isReady, convert } = useConverter();

  const [swiftEditor, setSwiftEditor] = useState<monaco.editor.IStandaloneCodeEditor | null>(null);
  const [tsEditor, setTsEditor] = useState<monaco.editor.IStandaloneCodeEditor | null>(null);

  const updateTSCode = useCallback(() => {
    if (!isReady || !swiftEditor || !tsEditor) return;
    try {
      const source = convert(swiftEditor.getValue());
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
      updateTSCode();
    }
  }, [isReady, swiftEditor, tsEditor, updateTSCode]);

  return <>
    <div style={{ flex: 1 }}>
      <Editor
        defaultLanguage="swift"
        defaultValue={defaultSwiftCode}
        onMount={setSwiftEditor}
        options={{
          minimap: {
            enabled: false,
          },
        }}
        onChange={updateTSCode}
      />
    </div>
    <div style={{ flex: 1 }}>
      <Editor
        defaultLanguage="typescript"
        defaultValue="Loading CodableToTypeScript wasm binary..."
        onMount={setTsEditor}
        options={{
          readOnly: true,
          minimap: {
            enabled: false,
          },
        }}
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
