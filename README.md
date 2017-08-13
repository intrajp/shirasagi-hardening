SHIRASAGI-hardning
=========
SHIRASAGI-hardning is a fork project of SHIRASAGI.

SHIRASAGI is Contents Management System.

Code Status
-----------

[![Build Status](https://travis-ci.org/shirasagi/shirasagi.svg?branch=master)](https://travis-ci.org/shirasagi/shirasagi)
[![Code Climate](https://codeclimate.com/github/shirasagi/shirasagi/badges/gpa.svg)](https://codeclimate.com/github/shirasagi/shirasagi)
[![Coverage Status](https://coveralls.io/repos/shirasagi/shirasagi/badge.png)](https://coveralls.io/r/shirasagi/shirasagi)
[![GitHub version](https://badge.fury.io/gh/shirasagi%2Fshirasagi.svg)](http://badge.fury.io/gh/shirasagi%2Fshirasagi)
[![Inline docs](http://inch-ci.org/github/shirasagi/shirasagi.png?branch=master)](http://inch-ci.org/github/shirasagi/shirasagi)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/shirasagi/shirasagi?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Stories in Ready](https://badge.waffle.io/shirasagi/shirasagi.svg?label=ready&title=Ready)](http://waffle.io/shirasagi/shirasagi)

Documentation
-------------

- [公式サイト](http://ss-proj.org/)
- [開発マニュアル](http://shirasagi.github.io/)

Platform
--------

- CentOS7.3 (SELinux enabled)
- Ruby 2.3
- Ruby on Rails 4
- MongoDB 3
- Unicorn

Installation (Auto)
-------------------

- Exec installer on CentOS7.3 as root<br />
- Set parameter "example.jp" as domain-name or IP address.<br />

```
$ curl https://raw.githubusercontent.com/intrajp/shirasagi-hardening/master/install.sh > install.sh
# bash install.sh

```

## Check the site 

#### admin page 

http://localhost:3000/.mypage  will show login page.<br />
Clicking the link as site name, you can check or edit the registered demo data.<br />
[ UserID： admin , Password： pass ]

#### public page 

http://localhost:3000/ will show demo site registered.

## develop and test environment

`.env` file in project root will set configuration as you wish
(How to set configuration)

- Change the log level from `warn` to `debug` 
- Remove the coverage analyze which is default when testing the site

```
DEVELOPMENT_LOG_LEVEL=debug
ANALYZE_COVERAGE=disabled
```

## Check these pages for other materials 

- [グループウェアの始め方](http://shirasagi.github.io/start/gws.html)
- [ウェブメールの始め方](http://shirasagi.github.io/start/webmail.html)
