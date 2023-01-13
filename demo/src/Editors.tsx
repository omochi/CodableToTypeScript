import Editor from "@monaco-editor/react";
import * as monaco from "monaco-editor";
import { useCallback, useRef } from "react";
import { useC2TS } from "./C2TSContext";
import { C2TS } from "./Gen/C2TS.gen";

export const Editors: React.FC = () => {
  const { isReady } = useC2TS();

  const tsEditorRef = useRef<monaco.editor.IStandaloneCodeEditor>(null!);
  const onChange = useCallback((value: string | undefined, ev: monaco.editor.IModelContentChangedEvent) => {
     if (isReady) {
       const c2ts = new C2TS();
       try {
         const source = c2ts.convert(value || "");
         tsEditorRef.current.setValue(source);
      } catch (e) {
        if (e instanceof Error) {
          tsEditorRef.current.setValue(e.message);
        } else {
          tsEditorRef.current.setValue((e as any).toString());
        }
      }
    }
  }, []);

  return <>
    <div style={{ flex: 1 }}>
      <Editor
        defaultLanguage="swift"
        defaultValue="// some comment"
        options={{
          minimap: {
            enabled: false,
          },
        }}
        onChange={onChange}
      />
    </div>
    <div style={{ flex: 1 }}>
      <Editor
        defaultLanguage="typescript"
        onMount={(e) => { tsEditorRef.current = e}}        
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
