'use strict';

var  chai = require('chai');
const should = chai.should(); 
var  request = require('supertest');

describe("node-api-goat API test", function () {
  this.timeout(25000);

  var server;
  before(function () {
    server = require('../app/server');
  });
  after(function () {
    server.close();
  });

  describe("CWE-73: External Control of File Name or Path", function() {
    it('downloads a sensitive file from the server', function (done) {
        request(server)
          .get('/cwe73/read?foo=package.json')
          .expect('Content-Type', /json/)
          .expect(200)
          .end((err, res) => {
            if(err){
              return done(err);
            } else{
              return done();
            }
          });
    });
  });

  describe("CWE-79: Improper Neutralization of Input During Web Page Generation ('Cross-site Scripting')", function () {
    it('echoes back what you send in the text query string parameter', function (done) {
      request(server)
        .get('/cwe79/echo?text=hello')
        .expect('Content-Type', /text/)
        .expect(200)
        .end((err, res) => {
          if(err){
            return done(err);
          } else{
            res.text.should.be.include('<p>You sent this: hello</p>');
            return done();
          }
        });
    });
  });

  describe("CWE-113: Improper Neutralization of CRLF Sequences in HTTP Headers ('HTTP Response Splitting')", function () {
    it('appends a file name to the HTTP response', function (done) {
        request(server)
          .get('/cwe113/split?key=myKey&value=myValueThatCouldHaveCRLFs')
          .expect(200)
          .end((err, res) => {
            if(err){
              return done(err);
            } else{
              res.text.should.be.include('Check your headers!');
              return done();
            }
          });
    });
  });

  describe("CWE-201: Information Exposure Through Sent Data", function () {
    it('echoes back what you send in the text query string parameter via a redirect', function (done) {
        request(server)
          .get('/cwe201/exposure?text=sensitive')
          .expect(200)
          .end((err, res) => {
            if(err){
              return done(err);
            } else{
              res.text.should.be.include('sensitive');
              return done();
            }
          });
    });
  });

  describe("CWE-601: URL Redirection to Untrusted Site ('Open Redirect')", function () {
    it('echoes back what you send in the text query string parameter via a redirect', function (done) {
        request(server)
          .get('/cwe601/redirect?text=hello')
          .expect(302) // HTTP response code for Redirect is 302
          .end((err, res) => {
            if(err){
              return done(err);
            } else{
              return done();
            }
          });
    });
  });

  describe("CWE-95: Eval Injection", function () {
    it('RGB to Hex conversion', function (done) {
      request(server)
        .get('/cwe95/rgbToHex?red=255&green=255&blue=255')
        .expect(200)
        .end((err, res) => {
          if(err){
            return done(err);
          } else{
            res.text.should.be.include('ffffff');
            return done();
          }
        });
    });
  });

  describe("Hex to RGB conversion", function () {
    it('returns the color in RGB', function (done) {
      request(server)
        .get('/hexToRgb?hex=00ff00')
        .expect(200)
        .end((err, res) => {
          if(err){
            return done(err);
          } else{
            res.text.should.be.include('[0,255,0]');
            return done();
          }
        });
    });
  });

  describe("CWE-502: Deserialization of Untrusted Data", function () {
    it('Deserializes untrusted data without verification of result data', function (done) {
      request(server)
        .get('/cwe502/serialize?foo={"rce":"_$$ND_FUNC$$_function (){console.log(\'exploited\')}()"}')
        .expect(200)
        .end((err, res) => {
          if(err){
            return done(err);
          } else{
            res.text.should.be.include('node-serialize');
            return done();
          }
        });
    });
  });

  describe("CWE-78: OS Command Injection", function () {
    it('Command injection exploit', function (done) {
      request(server)
        .get('/cwe78/childprocess?foo=echo+this+was+sent+from+the+client')
        .expect(200)
        .end((err, res) => {
          if(err){
            return done(err);
          } else{
            res.text.should.be.include('child_process');
            return done();
          }
        });
    });
  });

  describe("CWE-611: Improper Restriction of XML External Entity Reference", function () {
    it('XML evaluation', function (done) {
      request(server)
        .get('/cwe611/xmlref/?xml=<xml>xml</xml>')
        .expect(200)
        .end((err, res) => {
          if(err){
            return done(err);
          } else{
            res.text.should.be.include('xml');
            return done();
          }
        });
    });
  });

});
