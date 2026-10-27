const { chromium } = require('playwright-core');
const { spawn } = require('node:child_process');
const fs = require('node:fs/promises');
const assert = require('node:assert/strict');

(async () => {
  const server = spawn(process.execPath, ['scripts/serve-web.cjs'], { stdio: 'inherit' });
  let browser;
  let page;
  try {
    for (let attempt = 0; attempt < 100; attempt++) {
      try { if ((await fetch('http://127.0.0.1:7357')).ok) break; } catch (_) {}
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
    await fs.mkdir('build/screenshots', { recursive: true });
    browser = await chromium.launch({ channel: 'chrome', headless: true, args: ['--enable-unsafe-swiftshader'] });
    page = await browser.newPage({ viewport: { width: 390, height: 844 } });
    page.setDefaultTimeout(45000);
    // O editor Flutter precisa de eventos reais de teclado, não de mutação do DOM.
    const enter = async (label, text) => {
      await page.getByLabel(label, { exact: true }).click();
      // Aguardar a conexão do editor nativo ao campo semântico do Flutter.
      await page.waitForTimeout(150);
      await page.keyboard.press('ControlOrMeta+A');
      await page.keyboard.insertText(text);
      await page.waitForTimeout(100);
      assert.equal(await page.getByLabel(label, { exact: true }).inputValue(), text);
    };
    const errors = [];
    page.on('pageerror', (error) => errors.push(error.message));
    await page.route('https://geocoding-api.open-meteo.com/**', (route) => route.fulfill({
      contentType: 'application/json', body: JSON.stringify({ results: [{ name: 'Recife', admin1: 'Pernambuco', country: 'Brasil', latitude: -8.05, longitude: -34.9 }] }),
    }));
    await page.goto('http://127.0.0.1:7357');
    const semantics = page.locator('flt-semantics-placeholder');
    await semantics.waitFor({ state: 'attached', timeout: 90000 });
    await semantics.evaluate((element) => element.click());
    await page.getByRole('textbox', { name: 'Email', exact: true }).waitFor();
    await page.screenshot({ path: 'build/screenshots/login.png' });
    await page.getByRole('button', { name: 'Ainda não tem conta? Cadastre-se' }).click();
    await enter('Email', `browser-${Date.now()}@test.local`);
    await enter('Senha', 'Senha123!');
    await enter('Confirme a senha', 'Senha123!');
    await page.screenshot({ path: 'build/screenshots/cadastro.png' });
    await page.getByRole('button', { name: 'Criar conta', exact: true }).click();
    await page.getByText('Seu mundo, em memórias.', { exact: true }).waitFor();
    await page.getByRole('button', { name: 'Nova memória', exact: true }).click();
    await enter('Buscar cidade', 'Recife');
    await page.getByRole('button', { name: 'Buscar lugares', exact: true }).click();
    await page.getByText('Recife, Pernambuco, Brasil', { exact: true }).click();
    await enter('Nome do local', 'Meu pôr do sol em Recife');
    await enter('Sua memória', 'Uma caminhada especial durante a viagem.');
    const chooserPromise = page.waitForEvent('filechooser');
    await page.getByRole('button', { name: 'Selecionar foto', exact: true }).click();
    const chooser = await chooserPromise;
    // Fixture PNG válida, produzida pelo próprio navegador; sem fotos pessoais.
    const fixture = await page.evaluate(() => {
      const canvas = document.createElement('canvas'); canvas.width = 320; canvas.height = 180;
      const context = canvas.getContext('2d');
      context.fillStyle = '#206453'; context.fillRect(0, 0, 320, 180);
      context.fillStyle = '#E7B979'; context.beginPath(); context.arc(220, 65, 30, 0, Math.PI * 2); context.fill();
      return canvas.toDataURL('image/png').split(',')[1];
    });
    await chooser.setFiles({ name: 'recife.png', mimeType: 'image/png',
      buffer: Buffer.from(fixture, 'base64') });
    await page.getByRole('button', { name: 'Trocar foto', exact: true }).waitFor();
    const imageLoaded = page.waitForResponse((response) => response.url().includes(':9199/v0/b/') &&
      response.url().includes('alt=media') && response.status() === 200, { timeout: 180000 });
    await page.getByRole('button', { name: 'Guardar memória', exact: true }).click();
    const card = page.locator('flt-semantics[aria-label*="Meu pôr do sol em Recife"]')
      .or(page.getByText('Meu pôr do sol em Recife', { exact: false })).first();
    await card.waitFor({ timeout: 180000 });
    await imageLoaded;
    assert.equal(await page.getByText('Não foi possível abrir a foto.', { exact: true }).count(), 0);
    await page.screenshot({ path: 'build/screenshots/diario.png' });
    await card.click();
    await page.getByText('Sua memória', { exact: true }).waitFor();
    assert.ok(await page.getByText('Coordenadas: -8.05000, -34.90000', { exact: true }).isVisible());
    await page.getByRole('button', { name: 'Excluir memória', exact: true }).click();
    await page.getByRole('button', { name: 'Excluir', exact: true }).click();
    await page.getByText('Seu mundo, em memórias.', { exact: true }).waitFor({ timeout: 180000 });
    await page.getByRole('button', { name: 'Sair', exact: true }).click();
    await page.getByRole('textbox', { name: 'Email', exact: true }).waitFor();
    assert.deepEqual(errors, []);
    console.log('Browser OK: cadastro, busca, galeria, upload, diário, detalhes, exclusão e logout.');
  } catch (error) {
    if (page) {
      await page.screenshot({ path: 'build/screenshots/browser-error.png' }).catch(() => {});
      await fs.writeFile('build/screenshots/browser-dom.html', await page.content()).catch(() => {});
    }
    console.error(error);
    process.exitCode = 1;
  } finally {
    await browser?.close().catch(() => {});
    server.kill();
  }
})();
