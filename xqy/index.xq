(:~
 : index.xq
 :
 : Copyright (C) 2018 Leipzig University Library <info@ub.uni-leipzig.de>
 :
 : Author: Carsten Milling <cmil@hashtable.de>
 :
 : This file is part of histvv.
 :
 : Histvv is free software: you can redistribute it and/or modify
 : it under the terms of the GNU General Public License as published by
 : the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 : Histvv is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 : GNU General Public License for more details.
 :
 : You should have received a copy of the GNU General Public License
 : along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)

declare namespace v = "http://histvv.uni-leipzig.de/ns/2007";

<index>
{
for $d in //v:vv
let $k := $d/v:kopf
let $sem := if ($k/v:semester = "Winter") then "w" else "s"
order by $k/v:beginn/v:jahr, $k/v:ende/v:jahr
return
<vv name="{concat($k/v:beginn/v:jahr, $sem)}" >
  <titel>{concat($k/v:semester, "semester ", $k/v:beginn/v:jahr)}</titel>
  <vnum>{count($d//v:veranstaltung)}</vnum>
  {if ($k/v:status/@komplett = "ja") then <komplett/> else ''}
</vv>
}
</index>
