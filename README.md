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

- CentOS, Ubuntu
- Ruby 2.3
- Ruby on Rails 4
- MongoDB 3
- Unicorn

Installation (Auto)
-------------------

- Exec installer on CentOS7<br />
- Only root is permitted to exec installer<br />
- パラメーターの"example.jp"には、ブラウザでアクセスする際のドメイン名または、IPアドレスを指定してください。<br />

```
# curl https://raw.githubusercontent.com/intrajp/shirasagi-hardening/master/install.sh | bash -s example.jp
```

## Check the site 

#### admin page 

http://localhost:3000/.mypage にアクセスするとログイン画面が表示されます。<br />
サイト名のリンクをクリックすると、登録したデモデータを確認・編集することができます。<br />
[ ユーザーID： admin , パスワード： pass ]

#### public page 

http://localhost:3000/ にアクセスすると登録したデモサイトが表示されます。

## develop and test environment

`.env`というファイルをプロジェクトルートに用意すれば各種設定をお好みのものに切り替えられます。

(設定例)

- デフォルトで`warn`になっているログレベルを`debug`にしたい場合。
- テスト時にデフォルトで実行されるカバレッジ計測を省きたい場合。

```
DEVELOPMENT_LOG_LEVEL=debug
ANALYZE_COVERAGE=disabled
```

## Check these pages for other materials 

- [グループウェアの始め方](http://shirasagi.github.io/start/gws.html)
- [ウェブメールの始め方](http://shirasagi.github.io/start/webmail.html)
