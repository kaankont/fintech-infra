import { useEffect, useState } from 'react'

export default function Home(){
  const [health, setHealth] = useState('…')
  const [card, setCard]   = useState<string>('')

  useEffect(()=>{ fetch('/api/health').then(r=>r.text()).then(setHealth).catch(()=>setHealth('down')) },[])

  async function issue() {
    const r = await fetch('/api/v1/cards', {
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ user_id: 'u_demo', product_id: 'p_standard' })
    })
    setCard(await r.text())
  }

  return (
    <main style={{fontFamily:'ui-sans-serif',padding:24}}>
      <h1>Fintech Admin</h1>
      <p>Issuer Gateway health: <b>{health}</b></p>
      <button onClick={issue} style={{padding:8,marginTop:12,border:'1px solid #ddd'}}>Issue Demo Card</button>
      {card && <pre style={{marginTop:12}}>{card}</pre>}
    </main>
  )
}
