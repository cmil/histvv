'use strict';

var path = require('path');
var fs = require('fs');
var libxslt = require('libxslt');

var xsldir = 'xsl';

var xsl = fs.readFileSync(path.join(__dirname, xsldir, 'static.xsl'), 'utf-8');
// fix include path's to satisfy node-libxslt
// see https://github.com/albanm/node-libxslt#includes
xsl = xsl.replace(
  /xsl:import href="/g,
  'xsl:import href="' + xsldir + '/'
);

var stylesheet = libxslt.parse(xsl);

module.exports = function (dir) {

  return function (req, res, next) {
    if (res.headersSent || res.locals.content) {
      return next();
    }

    var filePath, file, html;
    var m = req.originalUrl.match(/^(\/\w+)*\/(\w+\.html)?$/);
    if (m) {
      filePath = m[2] ? req.originalUrl : req.originalUrl + 'index.html';
      file = path.join(dir, filePath);
      try {
        html = fs.readFileSync(file, 'utf-8');
      } catch (e) {
        // log error if the file exists but cannot be read
        if (e.code !== 'ENOENT') console.log(e);
        return next();
      }
    } else {
      return next();
    }

    // stylesheet params
    var xslparams = {
      'histvv-url': req.originalUrl
    };

    html = stylesheet.apply(html, xslparams);
    res.set('Content-type', 'text/html');
    res.send(html);
  };

};
