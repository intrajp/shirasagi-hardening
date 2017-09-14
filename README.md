SHIRASAGI-hardning
=========
SHIRASAGI-hardning is a fork project of SHIRASAGI.

SHIRASAGI is Contents Management System.

Documentation
-------------

- [公式サイト](http://ss-proj.org/)
- [開発マニュアル](http://shirasagi.github.io/)

Platform
--------

- CentOS 7.3 or CentOS 7.4 (SELinux enabled)
- Ruby 2.3
- Ruby on Rails 4
- MongoDB 3
- Unicorn

Installation (Auto)
-------------------

- Exec installer on CentOS 7.3 or CentOS 7.4 as root<br />
- Set parameter "example.jp" as domain-name or IP address.<br />

```
-- Download the install script --

$ curl -sO https://raw.githubusercontent.com/intrajp/shirasagi-hardening/master/install.sh

-- Check the contents --

$ cat install.sh

-- Execute the script as root --

# bash install.sh

-- Check the script has finished.--

  Echo string when installation succeeded: 

     "shirasagi installer has finished"

  Echo string when installation failed: 

     "Oops! Something went wrong!"

  Anyways, check install-log file "shirasagi-install_YYmmddHHMMSS.log" in /var/log for detail.
```

## Check the site 

#### admin page 

http://localhost:3000/.mypage  will show login page.<br />
Clicking the link as site name, you can check or edit the registered demo data.<br />
[ UserID： admin , Password： pass ]

#### public page 

http://localhost:3000/ will show demo site registered.

## Develop and test environment

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
