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

```
# for installation just install ruby, at least with your package manager
# then run the following commands inside the HisqisMailer directory
gem install bundler
bundle install
#
# if you don't want your username and password in your bash history put
# something like this in your .profile or .bashrc or .zshrc
export QISUSER="myUserName"
export QISPASS="myPassword"

```

All you need now to get set is a cronjob like:

``` 
0 * * * * /path/to/getGrades.rb -p $QISPASS -u $QISUSER >/dev/null 2>&1
```

Make a Nginx config like the following in your local lan and you'll get a super awesome overview page:

```
server {
        listen      80;
        server_name grades.lan;
        root /path/to/HisqisMailer/html/;
        index index.html index.htm;

        location / {
            try_files $uri $uri/ =404;
        }

    }
```
