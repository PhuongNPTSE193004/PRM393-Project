Momo Sandbox Demo Server

This small Express server simulates a Momo sandbox for local demos.

Setup

1. Install dependencies:

```bash
cd tools/momo-server
npm install
```

2. Run the server:

```bash
node server.js
# or for auto-reload during development:
npx nodemon server.js
```

Endpoints

- POST `/create_payment` — body: `{ orderId, amount, returnUrl }` → returns `{ payUrl }`.
- GET `/sandbox/pay` — a small HTML page to simulate the payment UI.
- POST `/notify` — internal endpoint called by the sandbox page to mark an order paid.
- GET `/check_payment?orderId=...` — returns `{ paid: true|false }`.

Demo flow

1. Client calls `/create_payment` with a generated `orderId` and `returnUrl`.
2. Server returns `payUrl` which points to `/sandbox/pay`.
3. Client opens `payUrl` in a browser; user clicks "Simulate Pay".
4. Sandbox calls `/notify` and redirects to `returnUrl`.
5. Client polls `/check_payment?orderId=...` to confirm payment, then completes the order.

This is a demo server only. For a real Momo sandbox integration, replace the `/create_payment` implementation
with a call to Momo's sandbox APIs and handle real notifications/webhooks.

Using real Momo sandbox credentials

This demo already contains support for calling Momo's test `create` endpoint. The server currently uses the
credentials embedded in `server.js` (for convenience during local demos). To use your own keys, edit the
top of `server.js` and set `PARTNER_CODE`, `ACCESS_KEY`, and `SECRET_KEY`.

The demo uses `http://localhost:3000/payment/result` as the `redirectUrl` by default. When calling
`/create_payment`, the server will pass that redirect URL to Momo; Momo will redirect the user's browser back
to this address after payment. For real external testing you may need to expose this URL (ngrok/localtunnel)
and register it in your Momo sandbox merchant settings.

Security note: Do NOT commit production Momo keys to version control or share them publicly. This demo places
keys in a local file for testing convenience only.
