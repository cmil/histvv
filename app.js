/*
 * app.js
 *
 * Copyright (C) 2018-2020 Leipzig University Library <info@ub.uni-leipzig.de>
 *
 * Author: Carsten Milling <cmil@hashtable.de>
 *
 * This file is part of histvv.
 *
 * Histvv is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Histvv is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

'use strict';

const path = require('path');
const express = require('express');
const debug = require('debug')('histvv:app');
const logger = require('morgan');
const annotate = require('./annotate');
const staticHtml = require('./static');
const finish = require('./finish');
const config = require('./config');
const pndHandler = require('./pnd');

debug({...config, db: {
  ...config.db,
  password: config.db.password ? '*****' : config.db.password
}});

annotate().then(n => {
  console.log('all documents prepared (%s new)', n);
}).catch(error => {
  console.warn(error);
});

const routeHandlerFactory = require('./routehandler.js')();

const app = express();

app.set('strict routing', true);

app.use(logger('dev'));

// redirect search without query to search form
app.get('/suche/', (request, response, next) => {
  if (Object.keys(request.query).length === 0) {
    response.redirect(301, '/suche.html');
  } else {
    next();
  }
});

app.get('/dozenten/', routeHandlerFactory('dozenten.xq', 'dozenten.xsl'));
app.get('/dozenten/galerie.html', routeHandlerFactory('dozenten.xq', 'dozenten.xsl'));
app.get('/dozenten/namen.html', routeHandlerFactory('dozentennamen.xq', 'dozenten.xsl'));
app.get('/dozenten/lookup/:name', routeHandlerFactory('dozentenlookup.xq', 'dozenten.xsl'));
app.get('/dozenten/:id.html', routeHandlerFactory('dozent.xq', 'dozenten.xsl'));
app.get('/pnd.txt', routeHandlerFactory('dozenten.xq', 'beacon.xsl', {
  send: true, type: 'text', xslParams (request) {
    const base = request.protocol + '://' + request.get('host');
    return {
      'histvv-beacon-feed': base + request.originalUrl,
      'histvv-beacon-target': base + '/pnd/{ID}'
    };
  }
}));
app.get('/pnd/:pnd', pndHandler());
app.get('/suche.html', routeHandlerFactory('suchformular.xq', 'suche.xsl'));
app.get('/suche/', routeHandlerFactory('suche.xq', 'suche.xsl', {
  queryParams: [
    'start',
    'interval',
    'volltext',
    'dozent',
    'von',
    'bis',
    'fakultaet'
  ]
}));
app.get('/vv/', routeHandlerFactory('index.xq', 'vv.xsl'));
app.get('/vv/:id.html', routeHandlerFactory('semester.xq', 'vv.xsl'));

if (config.staticDir) {
  app.use(staticHtml(config.staticDir));
}

app.use(staticHtml(path.join(__dirname, 'public')));
app.use(finish(config.customXslFile));

if (config.staticDir) {
  app.use(express.static(config.staticDir));
}

app.use(express.static(path.join(__dirname, 'public')));

// catch 404 and forward to error handler
app.use((request, response, next) => {
  const err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use((err, request, response, _) => {
    response.status(err.status || 500);
    response.json({
      message: err.message,
      error: err
    });
  });
}

// production error handler
// no stacktraces leaked to user
app.use((err, request, response, _) => {
  response.status(err.status || 500);
  response.type('text');
  response.send(err.message);
});

module.exports = app;
