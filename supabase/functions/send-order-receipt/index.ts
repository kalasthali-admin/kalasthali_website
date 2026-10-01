import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type ReceiptItem = {
  product_name: string;
  product_code: string;
  quantity: number;
  unit_price: number;
  line_total: number;
};

type SaleRecord = {
  order_id: string;
  customer_email: string | null;
  customer_phone: string | null;
  user_address: string;
  amount: number;
  razorpay_payment_id: string | null;
  items: ReceiptItem[] | null;
  invoice_sent_at: string | null;
};

type WebhookPayload = {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  schema: string;
  table: string;
  record: SaleRecord | null;
};

const jsonHeaders = { 'Content-Type': 'application/json' };

function response(status: number, body: Record<string, string | boolean>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function escapeHtml(value: string) {
  return value.replace(/[&<>'"]/g, (character) => {
    const entities: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      "'": '&#39;',
      '"': '&quot;',
    };
    return entities[character];
  });
}

function rupees(amount: number) {
  return `Rs. ${amount.toLocaleString('en-IN')}`;
}

function validItems(value: unknown): value is ReceiptItem[] {
  return (
    Array.isArray(value) &&
    value.length > 0 &&
    value.every(
      (item) =>
        typeof item?.product_name === 'string' &&
        typeof item?.product_code === 'string' &&
        Number.isSafeInteger(item?.quantity) &&
        item.quantity > 0 &&
        Number.isSafeInteger(item?.unit_price) &&
        item.unit_price >= 0 &&
        Number.isSafeInteger(item?.line_total) &&
        item.line_total >= 0,
    )
  );
}

function receiptHtml(sale: SaleRecord, items: ReceiptItem[]) {
  const rows = items
    .map(
      (item) => `
        <tr>
          <td style="padding:10px 0;border-bottom:1px solid #ead4b7;">
            <strong>${escapeHtml(item.product_name)}</strong><br />
            <span style="color:#765f4b;font-size:12px;">${escapeHtml(item.product_code)}</span>
          </td>
          <td style="padding:10px 0;border-bottom:1px solid #ead4b7;text-align:center;">${item.quantity}</td>
          <td style="padding:10px 0;border-bottom:1px solid #ead4b7;text-align:right;">${rupees(item.line_total)}</td>
        </tr>`,
    )
    .join('');
  const paymentId = sale.razorpay_payment_id
    ? `<p style="margin:8px 0;color:#765f4b;font-size:13px;">Payment ID: ${escapeHtml(sale.razorpay_payment_id)}</p>`
    : '';

  return `
    <main style="max-width:640px;margin:0 auto;padding:32px 24px;background:#fff7e8;color:#2f241d;font-family:Arial,sans-serif;">
      <h1 style="margin:0 0 8px;color:#5b351a;font-family:Georgia,serif;">Kalasthali By Nisha</h1>
      <h2 style="margin:0 0 24px;color:#5b351a;font-family:Georgia,serif;">Order receipt</h2>
      <p>Thank you for your order. Your payment has been received successfully.</p>
      <p style="color:#765f4b;">Order ID: ${escapeHtml(sale.order_id)}</p>
      <h3 style="color:#5b351a;font-family:Georgia,serif;">Delivery address</h3>
      <p style="white-space:pre-line;">${escapeHtml(sale.user_address)}</p>
      <table style="width:100%;border-collapse:collapse;margin-top:24px;">
        <thead><tr><th style="text-align:left;">Item</th><th>Qty</th><th style="text-align:right;">Total</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
      <p style="margin-top:24px;font-size:20px;font-weight:700;text-align:right;">Amount paid: ${rupees(sale.amount)}</p>
      ${paymentId}
    </main>`;
}

Deno.serve(async (request) => {
  const webhookSecret = Deno.env.get('ORDER_RECEIPT_WEBHOOK_SECRET');
  if (!webhookSecret) {
    console.error('Order receipt webhook secret is not configured.');
    return response(500, { error: 'Receipt service is not configured.' });
  }
  if (request.headers.get('x-order-receipt-secret') !== webhookSecret) {
    console.warn('Rejected order receipt webhook with an invalid secret.');
    return response(401, { error: 'Unauthorized.' });
  }

  let payload: WebhookPayload;
  try {
    payload = await request.json();
  } catch (_) {
    return response(400, { error: 'Invalid webhook payload.' });
  }

  if (
    payload.type !== 'INSERT' ||
    payload.schema !== 'public' ||
    payload.table !== 'sales' ||
    !payload.record
  ) {
    return response(202, { skipped: true });
  }

  const sale = payload.record;
  if (sale.invoice_sent_at) {
    console.info('Receipt already recorded as sent.', { orderId: sale.order_id });
    return response(200, { skipped: true });
  }
  if (
    !sale.order_id ||
    !sale.customer_email ||
    !sale.user_address ||
    !Number.isSafeInteger(sale.amount) ||
    sale.amount < 1 ||
    !validItems(sale.items)
  ) {
    console.error('Receipt webhook received an incomplete sale.', {
      orderId: sale.order_id || 'unknown',
    });
    return response(400, { error: 'Incomplete sale record.' });
  }

  const resendApiKey = Deno.env.get('RESEND_API_KEY');
  const resendFromEmail = Deno.env.get('RESEND_FROM_EMAIL');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!resendApiKey || !resendFromEmail || !supabaseUrl || !serviceRoleKey) {
    console.error('Receipt service secrets are not fully configured.');
    return response(500, { error: 'Receipt service is not configured.' });
  }

  const resendResponse = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      'Content-Type': 'application/json',
      'Idempotency-Key': `order-receipt/${sale.order_id}`,
    },
    body: JSON.stringify({
      from: resendFromEmail,
      to: [sale.customer_email],
      subject: `Kalasthali order receipt ${sale.order_id}`,
      html: receiptHtml(sale, sale.items),
    }),
  });

  if (!resendResponse.ok) {
    console.error('Receipt email provider rejected the request.', {
      orderId: sale.order_id,
      status: resendResponse.status,
    });
    return response(502, { error: 'Could not send receipt email.' });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { error } = await supabase
    .from('sales')
    .update({ invoice_sent_at: new Date().toISOString() })
    .eq('order_id', sale.order_id)
    .is('invoice_sent_at', null);
  if (error) {
    console.error('Receipt email sent but sale timestamp was not updated.', {
      orderId: sale.order_id,
    });
    return response(500, { error: 'Could not record receipt delivery.' });
  }

  console.info('Order receipt sent.', { orderId: sale.order_id });
  return response(200, { success: true });
});
