import Editor from "@monaco-editor/react";
import * as monaco from "monaco-editor";
import { useCallback, useRef } from "react";

export const Editors: React.FC = () => {
  const tsEditorRef = useRef<monaco.editor.IStandaloneCodeEditor>(null!);
  const onChange = useCallback((value: string | undefined, ev: monaco.editor.IModelContentChangedEvent) => {
     console.log("onChange");
    tsEditorRef.current.setValue(value || "");
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
