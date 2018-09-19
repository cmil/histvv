'use strict';

var path = require('path');
var fs = require('fs');
var libxslt = require('libxslt');

var xqydir = 'xqy';
var xsldir = 'xsl';

function loadFile (filename, dir) {
  var file = /^\//.test(filename)
    ? filename
    : path.join(__dirname, dir, filename);
  return fs.readFileSync(file, 'utf-8');
}

module.exports = function (dbSession) {

  return function (xqyFile, xslFile, opts) {
    opts = opts || {};

    var xqy = loadFile(xqyFile, xqydir);
    var xsl = loadFile(xslFile, xsldir);
    // fix include path's to satisfy node-libxslt
    // see https://github.com/albanm/node-libxslt#includes
    xsl = xsl.replace(
      /xsl:import href="/g,
      'xsl:import href="' + xsldir + '/'
    );

    var stylesheet = libxslt.parse(xsl);
    var query = dbSession.query(xqy);

    function routeHandler (req, res, next) {
      // bind route params to the query
      Object.keys(req.params).forEach(function (name) {
        query.bind(name, req.params[name], '');
      });

      if (opts.queryParams) {
        opts.queryParams.forEach(function (k) {
          if (req.query[k]) {
            var val = req.query[k] instanceof Array
              ? req.query[k].join(' ') : req.query[k];
            query.bind(k, val, '', console.log);
          }
        });
      }

      // stylesheet params
      var xslparams = opts.xslParams ? opts.xslParams(req) : {};
      xslparams['histvv-url'] = req.originalUrl;

      query.execute(function (err, r) {
        if (err) console.log(err);
        if (r.result === '') {
          next();
          return;
        }
        var body = stylesheet.apply(r.result, xslparams);
        res.type(opts.type || 'html');
        if (opts.send) {
          res.send(body);
        } else {
          res.locals.body = body;
          next();
        }
      });
    }

    return routeHandler;
  };
};
