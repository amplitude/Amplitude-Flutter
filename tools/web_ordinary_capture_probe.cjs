// Fresh release-browser validation of PR 1. Every network request is
// intercepted or aborted; service workers are blocked. No live ingestion.
// Usage: PLAYWRIGHT_MODULE=/path/to/playwright PROBE_FONT=/path/to/Roboto-Regular.ttf
// node tools/web_ordinary_capture_probe.cjs example/build/web /path/to/amplitude-2.44.4.js
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

(async () => {
  const root = path.resolve(process.argv[2]);
  const vendor = fs.readFileSync(process.argv[3], 'utf8');
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const summaries = [];
  try {
    for (const capture of ['simple', 'all', 'explicit']) {
      for (const input of ['mouse', 'touch']) {
        const context = await browser.newContext({ viewport: {width: 1000, height: 800},
          serviceWorkers: 'block', hasTouch: input === 'touch' });
        const page = await context.newPage();
        const delivered = [], blocked = [], errors = [];
        page.on('pageerror', error => errors.push(String(error)));
        await context.route('**/*', async route => {
          const request = route.request(), url = new URL(request.url());
          if (url.hostname.endsWith('.amplitude.com') && request.method() === 'POST') {
            const payload = request.postDataBuffer();
            const decoded = payload[0] === 0x1f && payload[1] === 0x8b ? zlib.gunzipSync(payload) : payload;
            const body = JSON.parse(decoded.toString('utf8'));
            assert.ok(Array.isArray(body.events));
            delivered.push(...body.events);
            return route.fulfill({json: {code: 200, events_ingested: body.events.length,
              payload_size_bytes: 0, server_upload_time: Date.now()}});
          }
          if (url.hostname === 'flutter-capture.invalid') {
            if (url.pathname === '/probe-sdk.js') {
              return route.fulfill({contentType: 'application/javascript', body: vendor + `
                (() => {
                  const create = amplitude.createInstance;
                  amplitude.createInstance = (...args) => {
                    const client = create(...args);
                    window.probeClient = client;
                    const init = client.init.bind(client);
                    client.init = (key, options) => {
                      window.probeOptions = JSON.parse(JSON.stringify(options));
                      const result = init(key, {...options, flushQueueSize: 1,
                        flushIntervalMillis: 10, fetchRemoteConfig: false,
                        remoteConfig: {fetchRemoteConfig: false}, diagnostics: false});
                      result.promise.then(() => {window.probeReady = true;});
                      return result;
                    };
                    return client;
                  };
                })();`});
            }
            const relative = decodeURIComponent(url.pathname).replace(/^\/+/, '') || 'index.html';
            const file = path.resolve(root, relative);
            assert.ok(file.startsWith(root + path.sep));
            if (fs.existsSync(file) && fs.statSync(file).isFile()) {
              if (relative === 'index.html') {
                const html = fs.readFileSync(file, 'utf8').replace(
                  /<script type="text\/javascript">[\s\S]*?<\/script>/,
                  '<script src="probe-sdk.js"></script>');
                return route.fulfill({contentType: 'text/html', body: html});
              }
              return route.fulfill({path: file});
            }
          }
          if (url.hostname === 'www.gstatic.com' && url.pathname.includes('/flutter-canvaskit/')) {
            const suffix = url.pathname.split('/flutter-canvaskit/')[1].split('/').slice(1).join('/');
            const file = path.resolve(root, 'canvaskit', suffix);
            if (file.startsWith(root + path.sep) && fs.existsSync(file)) {
              return route.fulfill({path: file, headers: {'Access-Control-Allow-Origin': '*'}});
            }
          }
          if (url.hostname === 'fonts.gstatic.com' && process.env.PROBE_FONT) {
            return route.fulfill({path: process.env.PROBE_FONT,
              headers: {'Access-Control-Allow-Origin': '*'}});
          }
          blocked.push(request.url());
          await route.abort();
        });
        const url = `http://flutter-capture.invalid/?capture=${capture}`;
        await page.goto(url);
        await page.waitForFunction(() => window.probeReady === true);
        const allowed = page.getByRole('button', {name: 'Allowed', exact: true});
        const excluded = page.getByRole('button', {name: 'Blocked', exact: true});
        await allowed.waitFor(); await excluded.waitFor();
        // Add DOM filter attributes; Dart callbacks and capture are untouched.
        await allowed.evaluate(node => {
          node.id = 'probe-allowed'; node.setAttribute('data-probe-label', 'allowed');
          node.classList.add('probe-parent');
        });
        const options = await page.evaluate(() => window.probeOptions.autocapture.elementInteractions);
        if (capture === 'explicit') {
          assert.deepEqual(options, {cssSelectorAllowlist: ['#probe-allowed'],
            actionClickAllowlist: ['.probe-parent'], dataAttributePrefix: 'data-probe-',
            pageUrlAllowlist: [url]});
        } else {
          assert.ok(options.cssSelectorAllowlist.includes('[role="button"]'));
          assert.ok(options.cssSelectorAllowlist.includes('button'));
        }
        const start = delivered.length;
        for (const button of [allowed, excluded]) {
          const box = await button.boundingBox(); assert.ok(box);
          for (let i = 0; i < 4; i++) {
            if (input === 'touch') await page.touchscreen.tap(box.x + box.width/2, box.y + box.height/2);
            else await page.mouse.click(box.x + box.width/2, box.y + box.height/2);
            await page.waitForTimeout(100);
          }
        }
        await page.waitForTimeout(700);
        await page.evaluate(async () => {await window.probeClient.flush().promise;});
        const events = delivered.slice(start);
        const count = type => events.filter(e => e.event_type === type).length;
        assert.equal(count('Probe Callback'), 8, JSON.stringify(events));
        const ordinary = events.filter(e => e.event_type === '[Amplitude] Element Clicked');
        assert.equal(ordinary.length, capture === 'explicit' ? 4 : 8, JSON.stringify(events));
        assert.equal(ordinary.filter(e => e.event_properties['[Amplitude] Element Text'] === 'Allowed').length, 4);
        assert.equal(ordinary.filter(e => e.event_properties['[Amplitude] Element Text'] === 'Blocked').length, capture === 'explicit' ? 0 : 4);
        if (capture === 'explicit') {
          for (const event of ordinary) assert.equal(event.event_properties['[Amplitude] Element Attributes'].label, 'allowed');
        }
        assert.equal(count('[Amplitude] Element Interacted'), 0);
        assert.equal(count('Probe Pointer Down'), 0, 'Quick semantics clicks should bypass Dart pointers in this engine');
        assert.equal(count('Probe Pointer Up'), 0);
        assert.equal(count('[Amplitude] Rage Click'), 0);
        for (const name of ['Allowed', 'Blocked']) {
          assert.equal(events.filter(e => e.event_type === 'Probe Callback' && e.event_properties.button === name).length, 4);
        }
        assert.deepEqual(errors, []);
        summaries.push({capture, input, browser: browser.version(), semanticsDomNodes: await page.locator('flt-semantics').count(),
          callbackEvents: 8, browserOrdinaryEvents: count('[Amplitude] Element Clicked'),
          flutterOrdinaryEvents: 0, flutterPointerDown: 0, flutterPointerUp: 0,
          explicitFilterRejectedBlockedClicks: capture === 'explicit',
          externalRequestsForwarded: 0, blockedRequests: blocked.length, errors});
        await context.close();
      }
    }
    console.log(JSON.stringify({browserSdk: '2.44.4 (supplied local bundle)', results: summaries}, null, 2));
  } finally { await browser.close(); }
})().catch(error => {console.error(error); process.exitCode = 1;});
