import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { C2TSProvider } from './C2TSContext'
import './index.css'

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <C2TSProvider>
      <App />
    </C2TSProvider>
  </React.StrictMode>,
)
