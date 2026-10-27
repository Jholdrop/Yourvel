const { spawn, spawnSync } = require('node:child_process');
const testing = process.argv[2] === 'test';
const browser = process.argv[2] === 'browser';
const args = [testing || browser ? 'emulators:exec' : 'emulators:start', '--project', 'demo-yourvel'];
if (testing) args.push('--only', 'auth,firestore',
  'node --test --test-concurrency=1 --test-timeout=240000 --test-force-exit test/local_firestore_rules.test.cjs');
if (browser) args.push('--only', 'auth,firestore', 'node test/browser_smoke.cjs');
const child = spawn(process.execPath, [require.resolve('firebase-tools/lib/bin/firebase.js'), ...args], {
  stdio: 'inherit',
  env: { ...process.env, FUNCTIONS_DISCOVERY_TIMEOUT: process.env.FUNCTIONS_DISCOVERY_TIMEOUT || '120' },
});
child.on('error', () => { console.error('Não foi possível iniciar o Firebase CLI. Execute npm install.'); process.exitCode = 1; });
const ownedJava = new Set();
const captureChildren = () => {
  if (process.platform !== 'win32' || !Number.isInteger(child.pid)) return;
  // O Windows pode interpor cmd.exe entre o CLI e Java. Registrar a árvore
  // enquanto os pais existem evita procurar ou encerrar processos por porta.
  const snapshot = spawnSync('powershell.exe', ['-NoProfile', '-Command',
    `$items=Get-CimInstance Win32_Process; $family=@(${child.pid}); do { $changed=$false; foreach ($item in $items) { if ($family -contains $item.ParentProcessId -and $family -notcontains $item.ProcessId) { $family+= $item.ProcessId; $changed=$true } } } while ($changed); $items | Where-Object { $family -contains $_.ProcessId -and $_.Name -eq 'java.exe' -and ($_.CommandLine -like '*cloud-firestore-emulator*' -or $_.CommandLine -like '*cloud-storage-rules-runtime*') } | ForEach-Object { $_.ProcessId }`],
  { windowsHide: true, encoding: 'utf8' });
  for (const value of (snapshot.stdout || '').trim().split(/\s+/)) {
    const pid = Number(value); if (Number.isInteger(pid) && pid > 0) ownedJava.add(pid);
  }
};
const tracker = (testing || browser) && process.platform === 'win32' ? setInterval(captureChildren, 5000) : null;
child.on('exit', (code) => {
  // Algumas versões do emulador Java mantêm a porta aberta após SIGINT no Windows.
  // Encerrar somente processos Java filhos desta execução de teste, nunca por porta.
  if (tracker) { clearInterval(tracker); captureChildren(); }
  if (ownedJava.size) {
    spawnSync('powershell.exe', ['-NoProfile', '-Command',
      `$owned=@(${[...ownedJava].join(',')}); Get-CimInstance Win32_Process | Where-Object { $owned -contains $_.ProcessId -and $_.Name -eq 'java.exe' -and ($_.CommandLine -like '*cloud-firestore-emulator*' -or $_.CommandLine -like '*cloud-storage-rules-runtime*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }`],
    { windowsHide: true, stdio: 'ignore' });
  }
  process.exitCode = code ?? 1;
});
