const http = require('http');

const data = new URLSearchParams({
  'username': 'Marcus TI', // user admin
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
  const cookies = res.headers['set-cookie'];
  console.log(`Login STATUS: ${res.statusCode}`);
  console.log(`Cookies:`, cookies);
  
  if (res.statusCode === 302 && cookies) {
    const loc = res.headers['location'];
    const getOptions = {
      hostname: 'localhost',
      port: 3010,
      path: loc,
      method: 'GET',
      headers: {
        'Cookie': cookies[0].split(';')[0]
      }
    };
    
    http.get(getOptions, (res2) => {
       console.log(`Redirect STATUS: ${res2.statusCode}`);
       let body2 = '';
       res2.on('data', c => { body2 += c; });
       res2.on('end', () => {
         if(res2.statusCode === 500) console.log("ERROR OUTPUT:", body2);
         else console.log("Redirect Page loaded completely without 500, length:", body2.length);
       });
    });
  }
});
req.write(data);
req.end();
