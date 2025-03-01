# 🛠️ ユーザー登録機能の実装方針

## 📝 変更の概要

### 背景
- これまで座席予約はユーザー登録なしで行えたが、**将来的にクーポン配布などのためにユーザー登録を必須にしたい** という要望が発生。
- 既存の予約データをユーザー情報と紐付ける必要がある。
- **`devise` Gem を活用** し、ユーザー管理を実装する。

### 解決策
1. `devise` を使用してユーザー認証機能を実装。
2. 予約時の **名前・メールアドレスをユーザー情報から取得** するように修正。
3. 既存の予約データを新しい `users` テーブルと紐付ける **データ移行を実施**。

---

## 🔍 実装手順

### **Step 1: `devise` の導入と設定**

#### **📌 `devise` のインストール**
```bash
docker compose exec web bundle add devise
docker compose exec web rails generate devise:install
```

#### **📌 `User` モデルの作成**
```bash
docker compose exec web rails generate devise User
```

#### **📌 マイグレーションの適用**
```bash
docker compose exec web rails db:migrate
```

---

### **Step 2: ユーザー登録フォームの作成**
#### **📌 `app/views/devise/registrations/new.html.erb`**
```erb
<h2>ユーザー登録</h2>

<%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
  <div class="field">
    <%= f.label :name, "名前" %>
    <%= f.text_field :name, required: true %>
  </div>

  <div class="field">
    <%= f.label :email, "メールアドレス" %>
    <%= f.email_field :email, required: true %>
  </div>

  <div class="field">
    <%= f.label :password, "パスワード" %>
    <%= f.password_field :password, required: true %>
  </div>

  <div class="field">
    <%= f.label :password_confirmation, "パスワード（確認）" %>
    <%= f.password_field :password_confirmation, required: true %>
  </div>

  <div class="actions">
    <%= f.submit "登録する" %>
  </div>
<% end %>
```

✅ **バリデーション**
- **パスワードの確認用フィールドを追加**
- **メールアドレスの形式チェック**
- **エラーメッセージの表示（`devise` に組み込み済み）**

---

### **Step 3: 予約とユーザーの関連付け**

#### **📌 `db/migrate/XXXXXXXXXXXXXX_add_user_id_to_reservations.rb`**
```ruby
class AddUserIdToReservations < ActiveRecord::Migration[7.1]
  def change
    add_reference :reservations, :user, null: true, foreign_key: true
  end
end
```

```bash
docker compose exec web rails db:migrate
```

✅ **ポイント**
- **`reservations` に `user_id` を追加**
- **予約は `user_id` を基に取得するよう変更**
- **一時的に `null: true` で許容し、データ移行後に `false` に変更予定**

---

### **Step 4: 既存データの移行**
#### **📌 `db/migrate/XXXXXXXXXXXXXX_migrate_reservations_data.rb`**
```ruby
class MigrateReservationsData < ActiveRecord::Migration[7.1]
  def up
    User.transaction do
      Reservation.find_each do |reservation|
        user = User.find_or_create_by!(email: reservation.email) do |u|
          u.name = reservation.name
          u.password = SecureRandom.hex(10) # 仮のパスワードを設定
        end
        reservation.update!(user_id: user.id)
      end
    end

    change_column_null :reservations, :user_id, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

```bash
docker compose exec web rails db:migrate
```

✅ **データ移行の流れ**
1. **既存の予約データからユーザーを作成（emailをキーに）**
2. **作成した `User` の `id` を `reservations` の `user_id` に設定**
3. **パスワードは仮のランダム値を設定**
4. **データ移行完了後に `user_id` の `null: false` 制約を適用**
5. **ダウングレード不可の `IrreversibleMigration` を設定**

---

### **Step 5: 予約時のユーザー情報を自動入力**

#### **📌 `app/controllers/reservations_controller.rb`**
```ruby
class ReservationsController < ApplicationController
  before_action :authenticate_user!

  def new
    @reservation = Reservation.new
    @movie = Movie.find(params[:movie_id])
    @schedule = Schedule.find(params[:schedule_id])
    @sheet = Sheet.find(params[:sheet_id])
  end

  def create
    @reservation = current_user.reservations.new(reservation_params)

    if @reservation.save
      redirect_to movie_path(@reservation.schedule.movie), notice: "予約が完了しました。"
    else
      redirect_to movie_reservation_path(@reservation.schedule.movie, schedule_id: @reservation.schedule_id, date: @reservation.date), alert: "予約に失敗しました。"
    end
  end

  private

  def reservation_params
    params.require(:reservation).permit(:schedule_id, :sheet_id, :date)
  end
end
```

✅ **変更点**
- **`before_action :authenticate_user!` を追加し、ログイン必須**
- **`current_user` を利用して `user_id` を設定**
- **予約時の `name`・`email` 入力が不要に**

---

### **Step 6: テストコードの対応**

#### **📌 HTTPステータスコードの設定**

Deviseの設定ファイルで、リダイレクトのステータスコードを設定します：

```ruby:config/initializers/devise.rb
# Note: These might become the new default in future versions of Devise.
config.responder.error_status = :unprocessable_entity
# config.responder.redirect_status = :see_other  # コメントアウトして302を使用
```

✅ **ポイント**
- Rails 7ではPOSTリクエスト後のリダイレクトで303がデフォルト
- Deviseの設定で明示的に302を使用するように制御
- 既存のテストコードとの互換性を維持

#### **📌 FactoryBotの設定**

```ruby:spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "テストユーザー#{n}" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
  end
end
```

✅ **ファクトリのポイント**
- 一意の名前とメールアドレスを生成
- パスワードの確認も含めて設定
- テストデータの重複を防止

---

## ✅ テスト方法

### **手動確認**
1. **ユーザー登録ページ `/users/new` で登録できること**
2. **ログイン後に `/movies/:id` から座席予約ができること**
3. **予約データが `users` テーブルと正しく紐付いていること**
4. **ログアウト状態では予約ができないこと**
5. **既存の予約データが正しく移行されていること**
6. **バリデーションが機能していること**
   - [ ] パスワードが一致しないとエラーになる
   - [ ] メールアドレスが重複しているとエラーになる
   - [ ] フォーム未入力時にエラーが表示される

### **RSpecテスト**
```bash
docker compose exec web bundle exec rspec ./spec/station14
```

---

## 📋 レビューのポイント
- **`devise` の導入とユーザー管理が適切に実装されているか**
- **予約データの移行が正しく行われているか**
- **ログイン状態でのみ座席予約が可能になっているか**
- **既存のUIの変更を最小限に抑えつつ、機能追加できているか**
- **バリデーションの適切な実装**
- **テストコードが適切に実装されているか**
- **HTTPステータスコードの設定が正しいか**
