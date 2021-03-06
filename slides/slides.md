# Build and Learn Rails Authentication
### Ryo Kajiwara (sylph01)
### 2021/10/21 @ Kaigi on Rails 2021

----

# 本発表のレポジトリは以下です
## スライドはslidesフォルダ以下にあります

![](frame.png)

<!-- こちらのURLはTweetしますが、内容多めでいつもの「超高速で沼が駆け抜ける」スタイルなので、並列して開くことをおすすめします。 -->

----

# 誰？

- sylph01 / 梶原 龍
- Twitter: @s01
- 暗号とかできます
- Elixirとかできます
- Railsまるでわからん

![bg fit right:33%](me_.jpg)

----

# Rails(鉄道)にはよく乗ります

![bg opacity:.4 horizontal](PXL_20210722_192222872.jpg)
![bg opacity:.4 ](PXL_20210729_041115019.jpg)
![bg opacity:.4 ](PXL_20210728_013536666.jpg)

----

# 若干真面目な自己紹介

- やせいのプログラマ(要するにフリーランス)
- W3C, IETFなどでセキュリティ寄りのプロトコルの標準化のお手伝いをしていました
    - HTTPS in Local Network, Messaging Layer Securityなど
- 次世代OAuthの薄い本を書きました
    - 現バージョンは今は頒布中止していますが新バージョン出したい
- Kaigi on Rails 1週間前に松山に引っ越しました

![bg fit right:33%](ogwbook.png)

----

# 現場の宣伝

- 株式会社コードタクトにて「まなびポケット」の認証認可基盤の開発をしています
- 認証認可チームにて**新規メンバーを募集中です**
    - 既存の認証基盤を置き換える新規開発を行います
    - モダンな認証認可技術で日本の公教育にイノベーションをもたらしましょう

![bg fit opacity:.3 vertical](logo_codetakt.png)
![bg fit opacity:.3](h_logo01.png)

----

----

# Railsの認証？

# 要するに**Devise**のことでしょ？

----

# なんか強い人から

# Deviseは**イケてない**って聞いたんだけど？

----

# Rails sucks? It's most likely that **you suck**

# Devise sucks? It's most likely that **you suck**

----

# 本発表の目的

認証機能の自作と解説、また主要な認証ライブラリのアプローチの比較を通して、

**認証技術への理解を深めること、また認証ライブラリの選択を手助けすること**

を目指します

----

# Disclaimer

- Do try this at home, but
- **Do not try this in production**

できる限り脆弱性を埋め込まないように気をつけて作ることをしますが、通常の場合productionでは**多数の人によって検証されているライブラリを使用すること**をおすすめします。

----

# Disclaimer (2)

なんなら **認証機能は自分で持たないほうがいい。**

- 自分でIDを管理するのは飲水を確保するのに自分で井戸を掘ること
- ID連携技術を使ってIdPを利用することは近代的な水道インフラに乗っかること

**OAuth/OpenID Connect**の話もできるにはできますが今回はその話はしません。

----

----

# 第1部:

# 認証を作ってみる

<!-- やったことある人は「どこまで気にして作れたか」を思い出しながら聞いていただけると幸いです -->

----

# 認証/認可についての概念

人は対象をどのように認知するか？

- 人/システムは **対象(Entity)** を直接認知しない。
- 人/システムは **Identity(属性の集合)** を通して対象(Entity)を認知する。
- 1つの対象(Entity)は複数の属性(Identity)を持ち、文脈に応じて使い分ける。

----

# 認証/認可についての概念

- Authentication(認証)
    - Entityがサービスの認知するIdentityに紐付いているという確証を得ること
    - 一般にいう「ログイン機能」は、識別子(ID)とパスワードの組を提示できることによって、 **利用するEntityがサービス上のEntityに対応している**という確証を得られることによって成立する
- Authorization(認可)
    - リソースにアクセスするための条件を定めること

----

# 忙しい人のための暗号・ハッシュアルゴリズム

この後の説明に用いる道具を超高速で説明します。実際の中身はググって

----

# 暗号化（ここでは共通鍵暗号のこと）

![](encryption.png)

一般に128bit以上のAESを使う（256bitは実はoverkill気味）。3-DESって言われたら「臭い」を感じ取って欲しい。

RSAは公開鍵暗号。ここでは説明しない。

----

# ハッシュ化

![](hash.png)

現代的にはSHA-2(SHA256, SHA512)が一般的。SHA-3などもあるにはある。あえて新規にSHA-1やMD5を使う理由はない。

**元の値に戻すのが困難**という性質がセキュアなパスワード認証においてとても重要。

----

# HMAC（超訳: 鍵付きハッシュ）

![](hmac.png)

ハッシュ関数を使って秘密の値(鍵)で特徴づけられる関数を得る方式。秘密の値を知らないと関数の形がわからないのでMAC値が計算できない。「HMAC-SHA256」というように「方式名」＋「利用するハッシュ関数」の組で呼ばれる。

----

# Webサービスの認証で必要な機能

- 必ず欲しい
  - ログイン・ログアウト
  - クッキーからの自動再ログイン(remember)
  - パスワードリセット
- できれば欲しい
  - ロックアウト
  - Eメール認証
  - ワンタイムパスワード

(機能はDeviseやRodauthのfeaturesから抜粋)

----

# パスワード認証に対する攻撃

パスワード認証に対する攻撃は一般に

- ブルートフォース攻撃
    - 辞書攻撃もこれの亜種
- **データベース流出を利用したハッシュクラック**
    - ローカルで大量にハッシュ計算して衝突させる
    - なお、「暗号化して保存」では復元できてしまうのでダメです

の2つの形を取る。

----

# ハッシュアルゴリズムの選択

パスワードを保存する場合のハッシュアルゴリズムは**遅いものほどよい**。この理由は**正規のハッシュは1回しか計算されないが攻撃の際は複数のハッシュを計算しなくてはいけない**ため。

（詳細は省略、キーワードで検索してください）

- MD5: 伸長攻撃が可能、そもそもハッシュ長が短いので衝突させやすい
- SHA-1: 強衝突耐性が突破されている
- SHA-2: 衝突耐性の面では現時点では十分だが、計算が十分に遅くない
    - 複数回適用して遅くするPBKDF2という方式がある
- パスワードハッシュ用に開発された**bcrypt**はわざと計算を遅くしている

<!--
https://twitter.com/TerahashCorp/status/1155128018156892160
https://qiita.com/ockeghem/items/5a5e73528eb0ee055428
-->

----

![h:500px](EAfWzjCWkAUC9o_.jpeg)

(https://twitter.com/TerahashCorp/status/1155128018156892160 より)

bcryptなら8桁でもクラックするのにGPUクラスタでも**18年かかる！**

----

# salt

ユーザーごとにランダムな文字列sを生成し、ハッシュ値の $h(p || s)$ と平文の s を保存することによって、事前にハッシュを計算しておいてテーブルをルックアップする**レインボーテーブルアタック**を回避できる。

bcryptでは出力される文字列がsaltとハッシュ値の組を結合したものになっている。

----

# `has_secure_password`

Railsでは `has_secure_password` というモデルのメソッドがbcryptを利用してパスワードハッシュ化の面倒を見てくれる。パスワード入力の確認も面倒を見てくれる。便利。

ソースは `activemodel/lib/active_model/secure_password.rb` 。

----

# 応用

攻撃者が正解のハッシュ値を得られないようにすればよいので、もっとがんばるなら以下のような方法が取れる:

- HMAC-SHA256のsecretを外部のHardware Security Moduleに保存して、HSMのAPIを通してハッシュ計算をする
    - secretはHSM上にしかないので、ハッシュ値の計算がHSMにしかできなくなる
    - このような手法をpassword pepperと呼ぶらしい
- ハッシュ値そのもののアクセスを可能な限りさせないためにデータベース関数を利用する
    - 後で紹介する rodauth がこの方式を使っている

<!-- DeviseとRodauthはpassword pepperに対応しているが、HMAC-SHA256に使う共通のインメモリのpassword pepperを使っているだけで、HSMを使うpassword pepperに比べると安全性は若干落ちる -->

----

# クッキーからの自動再ログイン、パスワードリセット、Eメール認証

基本的に原理は同じで、

- 有効期限つきの乱数列を払い出しユーザーモデルに関連づける
    - この際、データベースに保存するのはハッシュ化された値
    - 乱数列が利用される際には有効期限を確認、利用されたら乱数列を破棄
- Eメール認証とパスワードリセットではこの乱数列を登録しているメールアドレスに対して送信する

すべて同様に **「生成した乱数列を知っていて」「有効期限内で提示できる」** という性質をもってEntityが登録ユーザーに対応することを確認している。

<!-- ぶっちゃけ十分に短命であればハッシュ化された値じゃなくてもパスワードが平文で入ってるのに比べてそこまでリスクは高くない。攻撃者がデータベースのスナップショットにアクセスがある状態と比べてデータベースに常時アクセスがある状態を作るのはかなり難しいため -->

----

# クッキーからの自動再ログイン？セッションじゃダメなの？

- セッション: **ブラウザウィンドウが開いている間のみ有効な** Cookieのこと
    - セッションはCookieのサブセット
- Cookie: ここでは「 **ブラウザウィンドウよりも長いライフタイムを持つ** Cookie」のことを指す
    - 明示的に有効期限を指定したものを指す
    - なのでブラウザウィンドウを閉じた後の再ログインに使える
- Railsではセッションは自動で(`secret_key_base`を使って)暗号化される
    - Cookieは明示的にsignedかencryptedを指定する必要がある

----

# ワンタイムパスワード

- [HOTP: An HMAC-Based One-Time Password Algorithm (RFC 4226)](https://datatracker.ietf.org/doc/html/rfc4226)
- [TOTP: Time-Based One-Time Password Algorithm (RFC 6238)](https://datatracker.ietf.org/doc/html/rfc6238)

を用いるものが一般的。

**サーバーと共通の秘密を知っていて、共通の秘密から時刻などに基づいて特定の値を導出できる** という性質をもってEntityが登録ユーザーに対応することを確認している。

----

# ロックアウト(ブルートフォース攻撃対策)

- 以下の性質を持つカウンタを用意
    - 不正なログイン試行でカウントが1増えて
    - 正常なログインで0に戻る
- 一定以上のカウントを持っている場合、最終ログイン時間から一定時間が経過していない場合パスワードがあっていても自動的にログインに失敗する
    - 試行回数に対して指数でログイン不可能時間を設ける[exponential backoff algorithm](https://devcentral.f5.com/s/articles/implementing-the-exponential-backoff-algorithm-to-thwart-dictionary-attacks)という方式が一般的

----

# 実際に作ってみた

`https://github.com/sylph01/touch-and-learn-authentication/`

以下のRailsアプリにこれらの欲しい機能をできるだけプリミティブに実装したサンプルを置いています。

----

----

# 第2部:

# 認証ライブラリの話

----

# (再掲)

# Railsの認証？

# 要するに**Devise**のことでしょ？

----

# 何でライブラリが欲しいか

- ~~楽をしたい~~
- 読みやすいイディオム/DSLの形で認証機能を使いたい
- いろんな人の目が入ってるのでセキュリティバグを埋め込んでいる可能性が少ない

----

# ライブラリ化する場合に行うこと

- 初期設定手段を用意
    - `rails generate` のジェネレータを用意するのが一般的
- モデル、コントローラーなどのクラスを拡張しDSLを追加する

----

# 何でライブラリがあるのに自作をしたか

- 今回は学習目的
- productionでも一度自作している
    - ユーザーインターフェースを伴わないJSON APIで、アクセストークンを払い出す機構だけが欲しかった
    - 一般にproductionでライブラリを使わない理由があるとすれば**目的に合致しないから**

----

# ライブラリの比較

- [Devise](https://github.com/heartcombo/devise)
- [Sorcery](https://github.com/Sorcery/sorcery)
- [Authlogic](https://github.com/binarylogic/authlogic)
- [Rodauth](https://github.com/jeremyevans/rodauth)

を対象に比較をしていきます。

発表者の経験としては「Deviseはproductionで使ったことがある」「あとは今回調べた」程度です。

----

# Devise (1)

- Wardenの上に作られている
    - Wardenとは: 認証用 rack middleware
    - session middlewareの後に入って、sessionの情報を使って認証状態を確かめたり認証アクションをトリガーしたりする

----

# 超忙しい人のためのWarden

`env['warden'].authenticated?` - 認証済みであるかを確かめる

`env['warden'].authenticate(:password)` - `:password` strategyで認証を行う。実際の認証は各々定義するstrategyの中で行う

成功したら `env['warden'].user` にuser objectが入ってくる

認証エラー時は `throw(:warden)` でWardenの例外を投げる

----

# Devise (2)

Deviseのstrategyは `lib/devise/strategies` 以下にある。パスワード認証は[DatabaseAuthenticatable](https://github.com/heartcombo/devise/blob/5d5636f03ac19e8188d99c044d4b5e90124313af/lib/devise/strategies/database_authenticatable.rb#L9-L26) strategyで実装されている。

コントローラーで用いる `signed_in?`, `sign_in`, `sign_out` などは [`Devise::Controllers::SignInOut`](https://github.com/heartcombo/devise/blob/5d5636f03ac19e8188d99c044d4b5e90124313af/lib/devise/controllers/sign_in_out.rb#L7) で実装されている。Wardenの `authenticate?` や `set_user` や `logout` が使われていることがわかる。

----

# Devise (3)

Routesに `devise_for :users` を書くとそのUserが対応しているDeviseのモジュールに応じてDeviseの提供するcontrollerへのrouteが設定される。

ControllerのアクションをカスタマイズしたいときにはDeviseの提供するcontrollerをそのまま使いたくない。**多分これがDeviseを嫌う一番の理由か？**

<!-- 一方、基本機能を使うだけならDeviseのcontrollerで十分に事足りるので楽。カスタム要件少ないといいですね… -->

----

# Sorcery

- **code generationを可能な限り使わない**、シンプルに切り詰めた認証ライブラリ
    - Deviseではデフォルトから離れたことをしようと思うとコントローラーを継承したりoverrideしたりしないといけない
    - Sorceryでは**ライブラリのメソッドを自分のMVCコードの中で使う**
        - ただし自己責任の部分が増える
- 設定はInitializerにまとまっている
    - コード中で `sorcery_config` を取る動作がよく見られるのはこれ
- 暗号コードはAuthlogicをベースにしている
- パスワードの**暗号化**が可能
    - at your own risk...

----

```ruby
require_login
login(email, password, remember_me = false)
auto_login(user)
logout
logged_in?
current_user
redirect_back_or_to
@user.external?
@user.active_for_authentication?
@user.valid_password?('secret')
User.authenticates_with_sorcery!
```

(GitHubのreadmeより)

パスワード認証だけならメソッドは**11個！**

<!-- Sorcery, more like Instant, huh? -->

----

# Authlogic

- **Sessionオブジェクトを中心に据えた**認証ライブラリ
    - 他のライブラリではログインセッションが明示的にオブジェクトで表されないことに注意
- モデルに `acts_as_authentic` と書くと機能が有効化される
- 他では対応していない外部認証プロバイダ(OpenID, LDAP, PAM, x509)に対応できる
- generatorがない
    - モデルのセットアップ時にREADMEにあるmigrationから必要な機能分を選んで手書きする

<!-- acts_as_hoge, Rails 2とか3時代の香りがしますね -->

----

```ruby
UserSession.create(:login => "bjohnson", :password => "my password", :remember_me => true)

session = UserSession.new(:login => "bjohnson", :password => "my password", :remember_me => true)
session.save

session = UserSession.find

session.destroy
```

(GitHubのreadmeより抜粋)

<!--
- createはnew -> saveと同じ。1行目 = 2行目 + 3行目
- session.saveでセッションを保存し有効化する。この中でCookieへの値のセットが行われる
- findはrememberの際に使う。セッションの中身から永続化されているsessionを取ってくる
- destroyでログアウト
-->

----

# Rodauth (1)

- "Ruby's most advanced authentication framework"の名に恥じない**圧倒的高機能**
    - 暗号技術ファンとして素直に感心する
    - WebAuthn、ワンタイムパスワード、SMS、JWTのサポート
    - データベース関数によるパスワードハッシュへのアクセス
    - HMACを使った"password pepper"の徹底
- Rails/ActiveRecordを前提としていない
    - RodaとSequelで作られている
    - が**Railsでの利用方法はそんなに自明ではない**

----

# Rodauth (2): データベース関数の利用

- 普通のRailsアプリではアプリを実行するユーザーがパスワードハッシュ値にアクセスできる
- 通常のアプリユーザーとパスワードハッシュ値にアクセスできるユーザーを分離
    - **パスワードハッシュ値をアプリに見せることなく**値の設定や比較を行うデータベース関数を定義
    - アプリユーザーはデータベース関数を利用するだけ
- データベースの権限昇格が発生しない限りパスワードハッシュが漏れることがない

----

# Rodauth (3): password pepperの徹底

`hmac_secret` を設定することで、以下の値(p.29で説明した仕組み)の保存時にHMACが適用される（→共通のsecretを使う"password pepper"）。

- Eメールで送信するtoken
- rememberで使用するtoken

ワンタイムパスワードで使用するトークンはユーザーに提示されるキーにHMACが適用される。

`hmac_secret` をメモリ上にのみ存在させることで攻撃者はハッシュ(HMAC)値の計算に用いる関数を知ることができない。

----

# 外部認証プロバイダ利用

- DeviseはOmniAuthが利用できる
- Authlogicはプラグインが複数ある
    - レガシーな認証方式に対してもプラグインがある
    - RodauthでもLDAPは対応している
- SorceryはExternalプラグインというのが同梱されている
- Rodauthは見る限りまだ？

----

# おまけ: ハッシュ済みパスワードのカラム名

- Deviseは `encrypted_password`
    - 一般にハッシュ化した値をencryptedであるとは言わない
- Sorcery, Authlogicは `crypted_password`
    - そもそも暗号化済みを指す語は "crypted" ではない
- Rodauthは `password_digest`
    - ハッシュ化した値のことを "digest" と呼ぶのは正式な用法
    - `has_secure_password` で実装した場合も `password_digest`

----

# 多分こういう使い分けになる

- Rails/ActiveRecordに縛られないものが欲しい: Rodauth
- とにかく普通のパスワード認証＋αをさくっと作りたい: Devise
- 認証周りにたくさんカスタムコードがあって細かく制御したい: Sorcery, Authlogic
- 外部認証プロバイダへの移行がありそう: 今のところRodauth以外
    - レガシー外部認証方式はAuthlogicに一日の長がある
- ほぼ初期設定でとにかくセキュアにしたい: Rodauthが有利か？
    - 他がinsecureであるとは言ってないことに注意

----

# まとめ

- パスワード認証とその付随技術の実装の注意点を紹介しました
- 主な認証ライブラリの特徴とその使い分けを紹介しました

----

# Welcome to **Authentication Hell**

## (また今年も沼に人を誘ってしまった…)

----

# Questions / Comments?
## Send them to `@s01`
## or see you in the Q&A session!

----

# おまけ: Further Reading

- デジタルアイデンティティの考え方そのものについて
    - [『デジタルアイデンティティー 経営者が知らないサイバービジネスの核心』崎村夏彦](https://www.amazon.co.jp/dp/4296109901)
- 暗号技術と認証技術
    - [『図解即戦力 暗号と認証のしくみと理論がこれ1冊でしっかりわかる教科書』光成滋生](https://gihyo.jp/book/2021/978-4-297-12307-9)
    - [『暗号技術のすべて』IPUSIRON](https://www.shoeisha.co.jp/book/detail/9784798148816)

----

# おまけ: 時間が足りなくて話せなかったことのメモ

- ハッシュの衝突耐性について: [過去に記事書きました](https://d.s01.ninja/entry/20171207/1512615600)
- secure string comparison (timing-safe comparison)
    - 「前から順に一致判定して途中で打ち切る」方法では時間差を測定することで情報量の漏れが発生する
- セッションハイジャックの対策
    - HTTPSを使おう、`Secure`かつ`HttpOnly`のCookieを使おう
