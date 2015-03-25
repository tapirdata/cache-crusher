http = require('http');
express = require('express');

app = express();
app.use('/static', express.static('dist/client'));
app.get('/*', function(req, res) {
  res.redirect('/static/pages/main.html');
});

http.createServer(app).listen(8000, function() {
  console.log('Express server listening on port 8000');
});


