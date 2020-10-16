/*
 * pnd.js
 *
 * Copyright (C) 2018 Leipzig University Library <info@ub.uni-leipzig.de>
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
const fs = require('fs');
const query = require('./query');

const xqfile = path.join(__dirname, 'xqy', 'pnd.xq');
const xq = fs.readFileSync(xqfile, 'utf-8');

module.exports = function () {
  async function pndHandler (request, response, next) {
    try {
      const rsp = await query(xq, {pnd: request.params.pnd});
      const {data} = rsp;

      if (data === '') {
        return next();
      }

      response.redirect(data);
    } catch (error) {
      console.log(error);
    }
  }

  return pndHandler;
};
