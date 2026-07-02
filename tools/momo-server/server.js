const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');
const fetch = require('node-fetch');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// === Momo credentials (keep these safe) ===
const PARTNER_CODE = 'MOMO';
const ACCESS_KEY = 'F8BBA842ECF85';
const SECRET_KEY = 'K951B6PE1waDMi640xX08PD3vg6EkVlz';
const MOMO_ENDPOINT = 'https://test-payment.momo.vn/v2/gateway/api/create';

// Redirect URL reachable by user's browser after payment completes.
// Use http://localhost:3000/payment/result
const DEFAULT_REDIRECT = 'http://localhost:3000/payment/result';

// In-memory paid orders store for demo only.
const paidOrders = new Set();

// POST /create_payment
// Body: { orderId, amount, returnUrl }
// Returns: { payUrl }
app.post('/create_payment', async (req, res) => {
    const { orderId, amount, returnUrl } = req.body;
    if (!orderId || !amount) {
        return res.status(400).json({ error: 'orderId and amount required' });
    }

    const redirectUrl = returnUrl || DEFAULT_REDIRECT;
    const ipnUrl = `${req.protocol}://${req.get('host')}/notify`;

    const requestId = `req_${Date.now()}`;
    const orderInfo = `Payment for order ${orderId}`;
    const extraData = '';
    const requestType = 'captureWallet';

    // Build raw signature string following Momo spec
    const rawSignature = `accessKey=${ACCESS_KEY}&amount=${amount}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${PARTNER_CODE}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;
    const signature = crypto.createHmac('sha256', SECRET_KEY).update(rawSignature).digest('hex');

    const body = {
        partnerCode: PARTNER_CODE,
        accessKey: ACCESS_KEY,
        requestId,
        amount: String(amount),
        orderId,
        orderInfo,
        redirectUrl,
        ipnUrl,
        extraData,
        requestType,
        signature,
    };

    try {
        const r = await fetch(MOMO_ENDPOINT, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
        });

        const json = await r.json();
        if (!r.ok || json.resultCode !== 0) {
            return res.status(500).json({ error: 'Momo create failed', details: json });
        }

        // Momo returns a payUrl we can open in browser
        return res.json({ payUrl: json.payUrl, raw: json });
    } catch (err) {
        return res.status(500).json({ error: String(err) });
    }
});

// Return endpoint that Momo will redirect the user's browser to after payment
app.get('/payment/result', (req, res) => {
    // Momo will append parameters like orderId and resultCode
    const { orderId, resultCode } = req.query;
    if (orderId && String(resultCode) === '0') {
        paidOrders.add(String(orderId));
    }

    const html = `<!doctype html><html><head><meta charset="utf-8"><title>Payment Result</title></head><body style="background:#111;color:#fff;font-family:sans-serif;padding:24px;"><h2>Payment result</h2><p>Order: <strong>${orderId ?? ''}</strong></p><p>Result code: <strong>${resultCode ?? ''}</strong></p><p>You can close this window and return to the app.</p></body></html>`;
    res.set('Content-Type', 'text/html');
    res.send(html);
});

// Notified by momo (IPN) or sandbox when payment completed
app.post('/notify', (req, res) => {
    const { orderId } = req.body;
    if (!orderId) return res.status(400).json({ error: 'orderId required' });
    paidOrders.add(orderId);
    return res.json({ ok: true });
});

// Check payment status
app.get('/check_payment', (req, res) => {
    const { orderId } = req.query;
    if (!orderId) return res.status(400).json({ error: 'orderId required' });
    return res.json({ paid: paidOrders.has(orderId) });
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Momo sandbox demo server running on http://localhost:${port}`));
