const http = require('http');

const data = new URLSearchParams({
  'username': 'Marcus TI',
  'password': '123456'
}).toString();

const options = {
  hostname: 'localhost',
  port: 3010,
  path: '/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Content-Length': data.length
  }
};

const req = http.request(options, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
  res.setEncoding('utf8');
  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });
  res.on('end', () => {
    if (body.includes('Usuário ou senha inválidos')) {
      console.log('RESULT: Falha no login');
    } else {
      console.log('RESULT: Login OK, redirecionamento/response obtido');
    }
  });
});

req.on('error', (e) => {
  console.error(`Problem with request: ${e.message}`);
});

req.write(data);
req.end();
