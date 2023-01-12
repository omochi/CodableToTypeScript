import reactLogo from './assets/react.svg'
import { Editors } from './Editors';

function App() {
  return (
    <div style={{
      display: "flex", flexDirection: "column",
      width: "100vw", height: "100vh",
    }}>
      <header style={{ 
        height: "3.2rem",
        display: "flex", flexDirection: "row", alignItems: "center"
      }}>
        <h3 style={{ margin: "8pt" }}>
          CodableToTypeScript
        </h3>
      </header>
      <main style={{
        flexGrow: 1,
        display: "flex",
      }}>
        <Editors/>
      </main>
    </div>
  )
}

export default App
