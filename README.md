# Build and Learn Rails Authentication - Railsにおける認証技術の実装サンプル

## Disclaimer

あくまで学習用サンプルであるため、可能な限りのセキュリティ面の配慮は行っていますが、**本番環境のアプリケーションにそのまま使うことは控えてください。** 万一コピペで使用したいという場合でも、適切なセキュリティレビューを経た上で使用するようにしてください。

実際の商用アプリケーションでこのコードを流用したことによって生じた損害の責任は負いかねます。

## 動作にあたって

Rails consoleからユーザーを作成してください。

```
User.create(
  email: "hoge@example.com",
  password: "hogefuga",
  display_name: "Hoge"
)
```

メール送信は ~~作者のローカル環境がOP25Bされてるっぽいので~~ LetterOpenerWebを使って擬似的にメール送信をする形にしています。LetterOpenerWebのインターフェースへのリンクはrootのURLに記載があります。

## それぞれの機能に対応するコミットハッシュ

- ログイン: `c911d16075821eaa9f17a6c263560df875375adc`
- ログアウト: `c23f67ba900ee5cabd7ad1e945135c459b898124`
- Cookieからの再ログイン(remember): `0986b228c02aa615af0a3b4cddccc0759b767f01`
  - `5f2d088663e6ebbbc0530fc35b261f323ffb1f18`: remember tokenが時間で無効化されていることが確認できたらユーザーからその値を消去する
- ロックアウト: `dd586a2019bda6d8bc9e5332af77b141a29717e9`
  - exponential backoffで実装しているので、実際にその効果を確かめる場合は6〜10回くらいログインに連続で失敗させてデータベースの中身を見るとよいです
  - `5fbad9f8c84e79fdea0fb475d39c1f89e79fb098`: ユーザーがロックアウトされているかのチェックを最優先する順序に変更した
- Eメール認証: `388be28b6f13f6958f2e086819b33b3dc0ab03d6`
  - `d0ebf52d3ec01928ef8fe22d64ac6d5c85f88ea5`: 期限のチェックが漏れていたのの追加
- パスワードリセット: `bd574b82a133247d95ab7fb730e2b0f831427058`
