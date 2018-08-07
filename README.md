<!---
 Copyright (C) 2018 Klaus Schwarz
 
 This file is part of HisqisMailer.
 
 HisqisMailer is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 HisqisMailer is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with HisqisMailer.  If not, see <http://www.gnu.org/licenses/>.
-->

# Hisqismailer

this sends u mails when u get some new grades...

BUT you need linux... and cronjobs and environment variables and ruby + some gems

I run it with a cronjob like

``` 
0 * * * * /path/to/getGrades.rb -p $PASS -u $USER >/dev/null 2>&1
```