import { Editors } from './Editors';
import githubBlack from "./assets/github-mark.svg"
import githubWhite from "./assets/github-mark-white.svg"

function App() {
  return (
    <div style={{
      display: "flex", flexDirection: "column",
      width: "100vw", height: "100vh",
    }}>
      <header style={{
        height: "3.2rem",
        display: "flex", flexDirection: "row", alignItems: "center",
        justifyContent: "space-between",
      }}>
        <h3 style={{ margin: "8pt" }}>
          CodableToTypeScript
        </h3>
        <a href="https://github.com/omochi/CodableToTypeScript" target="_blank">
          <picture style={{ display: "flex", marginInlineEnd: "8pt" }}>
            <source srcSet={githubWhite} media="(prefers-color-scheme: dark)"/>
            <img src={githubBlack} alt="GitHub Link" style={{ maxWidth: "100%", height: "2rem" }}/>
          </picture>
        </a>
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
