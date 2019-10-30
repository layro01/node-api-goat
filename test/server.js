'use strict';

var  chai = require('chai');
const should = chai.should(); 
var  request = require('supertest');

describe("node-api-goat API test", function () {

  var server;
  before(function () {
    server = require('../app/server');
  });
  after(function () {
    server.close();
  });

  describe('Color Code Converter API', function () {
    this.timeout(25000);
    describe("CWE-73: External Control of File Name or Path", function() {
      it('downloads a sensitive file from the server', function (done) {
          request(server)
            .get('/download?file=package.json')
            .set('Accept', 'application/json')
            .expect('Content-Type', /json/)
            .expect(200);
            done();
      });
    });
  });

  describe("CWE-79: Improper Neutralization of Input During Web Page Generation ('Cross-site Scripting')", function () {
    this.timeout(25000);
    it('echoes back what you send in the text query string parameter', function (done) {
      request(server)
        .get('/echo?text=hello')
        .expect('Content-Type', /text/)
        .expect(200)
        .end((err, res) => {
          res.text.should.be.include('<p>You sent this: hello</p>');
          return done();
        });
    });
  });

  describe("CWE-113: Improper Neutralization of CRLF Sequences in HTTP Headers ('HTTP Response Splitting')", function () {
    it('appends a file name to the HTTP response', function (done) {
        request(server)
          .get('/split?key=myKey&value=myValueThatCouldHaveCRLFs')
          .expect(200);
          done();
    });
  });

  describe("CWE-201: Information Exposure Through Sent Data", function () {
    it('echoes back what you send in the text query string parameter via a redirect', function (done) {
        request(server)
          .get('/exposure?text=sensitive')
          .expect(200)
          .end((err, res) => {
            res.text.should.be.include('sensitive');
            return done();
          });
    });
  });

  describe("CWE-601: URL Redirection to Untrusted Site ('Open Redirect')", function () {
    it('echoes back what you send in the text query string parameter via a redirect', function (done) {
        request(server)
          .get('/redirect?text=hello')
          .expect(302); // HTTP response code for Redirect is 302
          done();
    });
  });

  describe("RGB to Hex conversion", function () {
    it('returns the color in hex', function (done) {
      request(server)
        .get('/rgbToHex?red=255&green=255&blue=255')
        .expect(200)
        .end((err, res) => {
          res.text.should.be.include('ffffff');
          return done();
        });
    });
  });

  describe("Hex to RGB conversion", function () {
    it('returns the color in RGB', function (done) {
      request(server)
        .get('/hexToRgb?hex=00ff00')
        .expect(200)
        .end((err, res) => {
          res.text.should.be.include('[0,255,0]');
          return done();
        });
    });
  });
});
