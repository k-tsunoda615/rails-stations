# **CSRFトークンとは**

## **1. CSRFとは**
- CSRF = Cross-Site Request Forgery（クロスサイトリクエストフォージェリー）
- Webアプリケーションに対する攻撃手法の一つ
- ユーザーが意図しないリクエストを強制的に送信させる攻撃

### 攻撃例
1. ユーザーが正規サイトにログイン
2. 攻撃者の用意した悪意のあるサイトにアクセス
3. 悪意のあるサイトが自動的に正規サイトへリクエストを送信
4. ユーザーの認証情報（Cookie）を使って不正な操作が実行される

## **2. CSRFトークンの役割**
- リクエストが正規サイトから送信されたものか検証するための値
- 各セッションごとにユニークな値を生成
- フォームやAjaxリクエストに自動的に付与される

### 動作の流れ
```
[ブラウザ]                    [Railsサーバー]
    │ ページリクエスト           │
    │─────────────────>│ トークン生成
    │                          │
    │ レスポンス（トークン含む） │
    │<─────────────────│
    │                          │
    │ フォーム送信（トークン付き）│
    │─────────────────>│ トークン検証
    │                          │
```

## **3. Railsでの実装**

### コントローラーでの設定
```ruby
class ApplicationController < ActionController::Base
  # CSRFトークンの検証を有効化（デフォルトで有効）
  protect_from_forgery with: :exception
end
```

### ビューでの自動挿入
```erb
<!-- フォームの場合 -->
<%= form_with model: @movie do |f| %>
  <!-- CSRFトークンが自動的に hidden フィールドとして挿入される -->
<% end %>

<!-- link_toの場合（method: :deleteなど） -->
<%= link_to '削除', movie_path(@movie), method: :delete %>
<!-- JavaScriptによってCSRFトークンが自動的に付与される -->
```

### 生成されるHTML
```html
<!-- フォームの場合 -->
<form action="/movies" method="post">
  <input type="hidden" 
         name="authenticity_token" 
         value="[ランダムな文字列]" />
  <!-- フォームの内容 -->
</form>
```

## **4. セキュリティ上の利点**

1. **リクエストの正当性確認**
   - 正規サイトから送信されたリクエストのみ受け付ける
   - 不正なリクエストは拒否される

2. **セッション固有の値**
   - トークンはセッションごとに異なる
   - 推測が困難

3. **自動的な保護**
   - Railsが自動的にトークンを生成・検証
   - 開発者が意識する必要が少ない

## **5. 注意点**

1. **APIモードでの扱い**
   - API専用アプリケーションでは異なる認証方式を検討

2. **トークンの有効期限**
   - セッションと同じ寿命
   - セッション切れでトークンも無効に

3. **JavaScriptでの Ajax リクエスト**
   - `rails-ujs`を使用する場合は自動的に付与
   - カスタムAjaxの場合は手動で付与が必要