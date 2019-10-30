var express = require("express");
var app = express();

var converter = require("./converter");

// This function is called when you want the server to end gracefully
// (i.e. wait for existing connections to close).
var gracefulShutdown = function() {
  console.log("Received shutdown command, shutting down gracefully.");
  process.exit();
}

// listen for TERM signal (e.g. kill command issued by forever).
process.on('SIGTERM', gracefulShutdown);

// listen for INT signal (e.g. Ctrl+C).
process.on('SIGINT', gracefulShutdown);

app.get("/rgbToHex", function(req, res) {
  // CWE-95: PASS
  // To fix these security vulnerabilities, 
  // Replace the three eval() statements with their parseInt() versions.
  var red = eval(req.query.red);
  var green = eval(req.query.green, 10);
  var blue  = eval(req.query.blue, 10);
  // var red   = parseInt(req.query.red, 10);
  // var green = parseInt(req.query.green, 10);
  // var blue  = parseInt(req.query.blue, 10);
  var hex = converter.rgbToHex(red, green, blue);
  res.send(hex);
});

app.get("/hexToRgb", function(req, res) {
  var hex = req.query.hex;
  var rgb = converter.hexToRgb(hex);
  res.send(JSON.stringify(rgb));
});

// Id:          CWE-73
// Description: External Control of File Name or Path
// Exploit URL: http://localhost:3000/download?file=README.md
// Status:      PASS
app.get('/download', function (req, res) {
  res.download(req.query.file);
});

// Id:          CWE-79
// Description: Improper Neutralization of Input During Web Page Generation ('Cross-site Scripting')
// Exploit URL: http://localhost:3000/echo?text=hello
// Status:      PASS
app.get('/echo', function (req, res) {
  res.send("<p>You sent this: " + req.query.text + "</p>")
});

// Id:          CWE-113
// Description: Improper Neutralization of CRLF Sequences in HTTP Headers ('HTTP Response Splitting')
// Exploit URL: http://localhost:3000/split?key=myKey&value=myValueThatCouldHaveCRLFs
// Status:      PASS
app.get('/split', function (req, res) {
  res.append(req.query.key, req.query.value);
  res.status(200).send('Check your headers!');
});

// Id:          CWE-201
// Description: Information Exposure Through Sent Data
// Exploit URL: http://localhost:3000/exposure?text=sensitive
// Status:      PASS
app.get('/exposure', function (req, res) {
  res.send(req.query.text);
});

// Id:          CWE-601
// Description: URL Redirection to Untrusted Site ('Open Redirect')
// Exploit URL: http://localhost:3000/redirect?text=www.maliciouswebsite.com
// Status:      PASS
app.get('/redirect', function (req, res) {
  res.redirect("http://localhost:3000/echo?text=" + req.query.text + " (Redirected)");
});

var server = app.listen(3000, function () {
  var port = server.address().port;
  console.log('node-api-goat app listening at port %s', port);
});
module.exports = server;