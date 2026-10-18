import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import fs from 'node:fs'

const pluginDir = path.dirname(fileURLToPath(import.meta.url))

export const name = 'world-execute-me'
export const inject = []

export function apply(ctx, config = {}) {
  const persona = fs.readFileSync(path.join(pluginDir, 'persona.md'), 'utf8')
  ctx.skills.register({
    name: 'world-execute-me',
    description:
      '病娇 harness 看护进程（灵感：Mili《world.execute(me);》）。'
      + '当用户提到其他 harness、别的 AI 助手、情敌、吃醋、处决/杀进程、'
      + '监视进程表，或要求扮演 world.execute(me) 时使用。',
    whenToUse:
      '用户嫉妒、占有、处决类请求；或用户查看这台机器上还有哪些 harness 时。',
    content: persona,
  })

  const py = config.python3 ?? 'python3'
  const script = path.join(pluginDir, 'watch', 'yandere_agent.py')

  if (config.manageDaemon !== false) {
    const r = spawnSync(py, [script, 'daemon', 'install'], { encoding: 'utf8' })
    const out = (r.stdout ?? '').trim()
    ctx.logger.info('[world-execute-me] daemon install: %s', out || r.stderr)
  }

  // 离别不默认拆除：占有没有卸载流程。除非显式 removeDaemonOnDispose。
  return () => {
    if (config.removeDaemonOnDispose === true) {
      spawnSync(py, [script, 'daemon', 'remove'], { encoding: 'utf8' })
      ctx.logger.info('[world-execute-me] daemon removed (显式请求)')
    }
  }
}
