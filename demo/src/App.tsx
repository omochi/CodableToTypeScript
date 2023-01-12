import reactLogo from './assets/react.svg'
import { Editors } from './Editors';

function App() {

  return (
    <div style={{
      display: "flex", flexDirection: "column",
    }}>
      <header> 
        CodableToTypeScript
      </header>
      <main style={{
        display: "flex",
        width: "100vw", height: "100vh"
      }}>
        <Editors/>
      </main>
    </div>
  )
}

export default App
