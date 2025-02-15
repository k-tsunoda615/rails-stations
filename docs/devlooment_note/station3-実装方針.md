# **映画登録機能 実装手順書**

## **1. 実装手順**
### **Step 1: ルーティングの設定**
- 管理画面用のルーティングを追加する
- **GET `/admin/movies/new`** で新規登録フォームを表示
- **POST `/admin/movies`** で映画を登録

---

### **Step 2: コントローラーの実装**
- `Admin::MoviesController` に以下のアクションを追加
  - **`new` アクション**：新規登録フォームを表示
  - **`create` アクション**：フォームの入力データを受け取り、映画を登録
- 登録成功時に一覧ページへリダイレクト
- 登録エラー時にフォームを再表示し、エラーメッセージを表示

---

### **Step 3: ビューの作成**
- `app/views/admin/movies/new.html.erb` を作成し、新規登録フォームを実装
- フォームには以下の入力項目を設ける
  - **タイトル（name）**
  - **公開年（year）**
  - **概要（description）**（改行を考慮）
  - **画像URL（image_url）**
  - **上映中（is_showing）**（チェックボックス）
- 以下の項目はRailsの機能によってデータベースで自動的に管理される
  - **ID（id）**
  - **登録日時（created_at）**
  - **更新日時（updated_a）**


---

## **2. 実装のポイント**
### **✅ バリデーション**
- タイトルの重複登録を防ぐために **モデルとデータベースの両方でユニーク制約を設定**
- 入力必須項目（タイトル、公開年など）をバリデーションで制御

---

### **✅ エラーハンドリング**
#### **1. 同じタイトルの登録試行時**
- **400エラー（`unprocessable_entity`）** を返す
- フラッシュメッセージでユーザーに通知

#### **2. その他のエラー**
- Railsデフォルトのエラー画面を表示せず、**ユーザーフレンドリーなエラーメッセージを表示**
- 入力ミス時にエラーメッセージを表示し、修正できるようにする

---

### **✅ フォーム設計**
- **カラム名を日本語で表示**
- **概要（description）の改行を考慮**
- **画像URLの入力フィールドを用意**
- **上映中（is_showing）をチェックボックスで設定**

---

### **✅ リダイレクト**
| 状況 | 遷移先 | 備考 |
|------|--------|----------------------------|
| **登録成功時** | 映画一覧ページ | 成功メッセージを表示 |
| **エラー時** | フォームを再表示 | 入力値を保持し、エラーメッセージを表示 |

---

## **3. 次のステップ**
この方針に従い、以下の順序で実装を進める。
1. **ルーティングの設定**
2. **コントローラーの基本構造を作成**
3. **ビューの作成とフォームの実装**
4. **バリデーションとエラーハンドリングを追加**
5. **動作確認と微調整**

