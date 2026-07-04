// Κ.LLM — WebLLM integration
let engine = null, ready = false, _Create = null

export async function init(onProgress) {
  try {
    const mod = await import('https://esm.run/@mlc-ai/web-llm')
    _Create = mod.CreateMLCEngine
    engine = await _Create('SmolLM2-360M-Instruct-q4f16_1-MLC', { initProgressCallback: onProgress })
    ready = true
  } catch (e) {
    ready = false
  }
  return ready
}

export function isReady() { return ready }

export async function complete(messages, opts = {}) {
  if (!ready) return null
  return engine.chat.completions.create({
    messages,
    temperature: opts.temperature || .8,
    max_tokens: opts.max_tokens || 256,
    frequency_penalty: opts.frequency_penalty || 0,
    ...(opts.stream ? { stream: true } : {})
  })
}

export async function thought(sysPrompt, history, depthPrompt) {
  if (!ready) return ''
  try {
    const resp = await complete([
      { role: 'system', content: sysPrompt },
      ...history.slice(-6),
      { role: 'user', content: depthPrompt }
    ], { max_tokens: 50, frequency_penalty: 1.5 })
    return resp.choices[0]?.message?.content?.trim() || ''
  } catch (e) { return '' }
}

export async function respond(sysPrompt, history, userText) {
  if (!ready) return null
  return complete([
    { role: 'system', content: sysPrompt },
    ...history.slice(-8),
    { role: 'user', content: userText }
  ], { max_tokens: 256, stream: true })
}
