#!/bin/bash

dnf update -y
dnf install -y nginx

cat > /usr/share/nginx/html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>${node_name} | AWS HA Demo</title>

  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #0f172a;
      color: #e2e8f0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .container {
      width: min(900px, 90%);
    }

    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 48px;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 40px;
    }

    .eyebrow {
      color: #94a3b8;
      font-size: 14px;
      text-transform: uppercase;
      letter-spacing: 2px;
      margin-bottom: 10px;
    }

    h1 {
      font-size: 42px;
      margin-bottom: 16px;
    }

    .badge {
      background: #14532d;
      color: #86efac;
      padding: 8px 14px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 600;
    }

    .description {
      color: #94a3b8;
      font-size: 17px;
      line-height: 1.7;
      max-width: 650px;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 16px;
      margin-top: 40px;
    }

    .item {
      background: #0f172a;
      border: 1px solid #334155;
      border-radius: 10px;
      padding: 20px;
    }

    .label {
      color: #64748b;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    .value {
      margin-top: 8px;
      font-size: 16px;
      font-weight: 600;
    }

    .footer {
      margin-top: 32px;
      padding-top: 24px;
      border-top: 1px solid #334155;
      color: #64748b;
      font-size: 13px;
    }

    @media (max-width: 650px) {
      .card {
        padding: 30px;
      }

      h1 {
        font-size: 32px;
      }

      .grid {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>

<body>

  <div class="container">

    <div class="card">

      <div class="header">

        <div>
          <div class="eyebrow">
            AWS High Availability Demo
          </div>

          <h1>
            ${node_name}
          </h1>
        </div>

        <div class="badge">
          ● Healthy
        </div>

      </div>

      <p class="description">
        This page is served by an Nginx web server running on a private
        Amazon EC2 instance behind an Application Load Balancer.
      </p>

      <div class="grid">

        <div class="item">
          <div class="label">Node</div>
          <div class="value">${node_name}</div>
        </div>

        <div class="item">
          <div class="label">Service</div>
          <div class="value">Nginx</div>
        </div>

        <div class="item">
          <div class="label">Protocol</div>
          <div class="value">HTTP : 80</div>
        </div>

      </div>

      <div class="footer">
        Traffic is distributed by an AWS Application Load Balancer.
        Refresh the page to observe requests being served by different
        backend nodes.
        Created and managed by Sofonias Aberra
      </div>

    </div>

  </div>

</body>
</html>
HTML

systemctl enable nginx
systemctl start nginx