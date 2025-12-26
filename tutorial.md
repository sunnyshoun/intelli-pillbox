# Flutter App 開發入門教學講義

## 專案：智慧藥盒 (Intelli Pillbox)

## 1. 什麼是 Flutter？

簡單來說， **Flutter 是 Google 推出的「UI 工具包」** 。

想像一下，過去如果你要開發一個 App：

* 要給 iPhone 用，你必須學 Swift 語言，用 Apple 的工具開發。
* 要給 Android 用，你必須學 Kotlin 語言，用 Google 的工具開發。

這導致開發成本很高。 **Flutter 的出現解決了這個問題** 。

### 核心特色：

* **跨平台 (Cross-Platform)** ：寫一次程式碼 (Codebase)，可以同時打包成 iOS 和 Android 的 App，甚至還能變成網頁 (Web) 和電腦軟體 (Desktop)。
* **高效能** ：它直接畫在螢幕上，不透過中間層轉換，所以速度非常快，能達到每秒 60 幀 (60fps) 的流暢度。
* **熱重載 (Hot Reload)** ：這是開發者的最愛！當你修改了程式碼並存檔，模擬器上的畫面會**立刻**改變，不需要重新編譯等待，大大節省開發時間。

## 2. Flutter 的理念與撰寫概念

在 Flutter 的世界裡，有一句最重要的口訣：

> **"Everything is a Widget" (萬物皆是組件)**

### 2.1 什麼是 Widget (組件)？

App 畫面上的每一個元素都是 Widget。

* 一段文字 (`Text`) 是一個 Widget。
* 一個按鈕 (`Button`) 是一個 Widget。
* 把東西排成一列 (`Row`) 的排版規則也是一個 Widget。
* 甚至整個 App 本身 (`MaterialApp`) 也是一個 Widget。

我們像堆積木一樣，把小的 Widget 組合起來，變成大的 Widget，最後變成一個完整的頁面。這就形成了  **「Widget Tree (組件樹)」** 。

### 2.2 宣告式 UI (Declarative UI)

傳統開發常需要告訴電腦「如何」做 (例如：先找到按鈕，然後改變它的顏色)。
Flutter 使用 **宣告式 UI** ，你只需要告訴電腦「 **當狀態 (State) 是這樣的時候，畫面要是什麼樣子** 」。

* **StatelessWidget (無狀態組件)** ：畫面是靜態的，產生後就不會變 (例如：顯示標題文字)。
* **StatefulWidget (有狀態組件)** ：畫面會隨資料改變 (例如：計數器、打勾的選單、智慧藥盒的藥物列表)。

## 3. Dart 常用語法說明

Flutter 使用的是 **Dart** 程式語言。它長得很像 Java 或 C++。以下是開發 App 時最常用的語法：

### 3.1 變數宣告

```
// 明確指定型態
String appName = "Intelli Pillbox";
int pillCount = 3;
bool isTaken = false;

// 自動推斷型態 (常用)
var userName = "John"; // Dart 知道這是 String
final double height = 180.5; // final 表示賦值後不能再改變
```

### 3.2 函式 (Function)

```
// 一般寫法
void sayHello(String name) {
  print("你好, $name"); // $ 用來在字串中插入變數
}

// 箭頭函式 (如果只有一行程式碼)
int add(int a, int b) => a + b;
```

### 3.3 類別 (Class) - 建構 Widget 的基礎

```
class MyPage extends StatelessWidget {
  final String title;

  // 建構子 (Constructor)，用來接收參數
  const MyPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
```

### 3.4 非同步處理 (Async/Await) - **超重要！**

App 讀取資料庫或網路時不能「卡住」畫面，所以要用非同步。

* `Future`: 代表未來的某個時間會拿到的資料。
* `async`: 標記這是非同步函式。
* `await`: 等待這個動作做完再繼續往下執行。

```
Future<void> loadData() async {
  print("開始讀取...");
  await Future.delayed(Duration(seconds: 2)); // 模擬等待2秒
  print("讀取完成！");
}
```

## 4. Lib 資料夾結構與檔案說明

在 `intelli_pillbox` 專案中，所有的程式碼都在 **`lib`** 資料夾內。這是一個標準的專案結構，我們將其分為「外觀 (UI)」與「邏輯 (Logic)」。

### 📂 `lib/` (根目錄)

* **`main.dart`** :  **程式的入口點** 。
* 裡面會有一個 `void main()` 函式，這是 App 啟動的第一步。
* 它通常負責初始化設定 (如通知服務、資料庫) 並執行 `runApp()` 來啟動主畫面。

### 📂 `lib/screens/` (畫面層)

這裡存放所有使用者看得到的「頁面」。

* **`main_screen.dart`** : 主畫面框架。通常包含底部的導航列 (BottomNavigationBar)，用來切換不同的 Tab (分頁)。
* **`schedule_tab.dart`** : **(核心功能)** 顯示吃藥時刻表的頁面。
* **`family_tab.dart`** : 家人照護或監控的頁面。
* **`history_tab.dart`** : 查看過去吃藥紀錄的頁面。
* **`setting_screen.dart`** : 設定頁面。
* **`schedule/add_alarm_form.dart`** : 新增提醒的表單頁面。

### 📂 `lib/models/` (資料模型層)

這裡定義資料的「長相」或「規格書」。

* **`app_models.dart`** : 定義了什麼是「藥物 (Pill)」、什麼是「提醒 (Alarm)」。例如一個 `Alarm` 可能包含 `time` (時間)、`pillName` (藥名)、`isTaken` (是否已服用) 等欄位。這讓程式碼管理資料更安全。

### 📂 `lib/providers/` (狀態管理層)

這是連接 UI 和資料的橋樑。

* **`app_provider.dart`** : 使用 `Provider` 套件來管理全域狀態。
* 當你在 `AddAlarmForm` 新增一個鬧鐘時，你會呼叫這裡的函式。
* `Provider` 會通知 `ScheduleTab`：「資料變了！請重繪畫面！」
* 這確保了不同頁面看到的資料是同步的。

### 📂 `lib/services/` (服務層)

這裡存放不涉及畫面，但在背景運作的功能。

* **`notification_service.dart`** : 控制手機發出通知的邏輯 (跳出視窗、震動、聲音)。
* **`background_service.dart`** : 處理 App 在背景執行時的邏輯 (例如：App 沒開也要能跳通知)。

### 📂 `lib/utils/` (工具層)

* **`format_utils.dart`** : 存放共用的工具函式，例如把 `DateTime` 轉成字串 "12:00 PM"，避免在每個頁面都重寫一次。

## 5. 套件管理 (Package Management)

Flutter 強大的原因之一是擁有豐富的第三方套件 (Packages)。

### 核心檔案：`pubspec.yaml`

這個檔案就像是 App 的「採購清單」。你可以在這裡聲明你的 App 需要哪些外部功能。

在 `intelli_pillbox` 中，我們可能用到了：

* `flutter`: SDK 本身。
* `provider`: 用來管理狀態 (State Management)。
* `flutter_local_notifications`: 用來發送吃藥提醒通知。
* `intl`: 用來處理日期和時間格式。
* `shared_preferences` (推測): 用來在手機上儲存簡單的設定。

### 如何安裝套件？

1. **瀏覽** ：去 [pub.dev](https://pub.dev "null") 搜尋你需要的功能 (例如搜尋 "camera")。
2. **指令安裝** ：在終端機 (Terminal) 輸入：

```
   flutter pub add 套件名稱
```

1. **自動更新** ：系統會自動將套件名稱與版本寫入 `pubspec.yaml` 並下載程式碼。

## 6. 如何利用 USB 偵錯來測試 APP

在模擬器上跑雖然方便，但最終我們還是要在真機上測試 (尤其是相機、藍芽或通知功能)。

### 準備工作

1. **Android 手機** ：

* 進入「設定」>「關於手機」。
* 連續點擊「版本號碼 (Build Number)」7 次，直到出現「您已成為開發人員」。
* 回到設定，進入「開發人員選項」，開啟  **「USB 偵錯 (USB Debugging)」** 。

1. **iPhone 手機** ：

* 需要 Mac 電腦與 Xcode。
* 手機接上電腦，點選「信任這部電腦」。
* (Windows 電腦開發 Flutter 無法直接輸出到 iPhone 測試，需透過 Mac)。

### 執行測試步驟

1. **連接 USB** ：用傳輸線將手機接到電腦。
2. **確認裝置** ：

* 在 VS Code 右下角應該會看到你的手機型號。
* 或者在終端機輸入 `flutter devices` 確認是否有抓到手機。

1. **執行偵錯 (Debug)** ：

* 在 VS Code 中按下 **F5** (或點選 "Run and Debug")。
* 等待編譯 (第一次會比較久，因為要安裝 APK 到手機上)。

1. **查看輸出** ：

* App 會在手機上自動開啟。
* 電腦下方的 "Debug Console" 會顯示 `print()` 出來的訊息，這裡是你找 Bug 最重要的地方！

### 常見問題

* **Q: 手機沒抓到？**
  * A: 檢查傳輸線是否支援傳輸資料 (有些線只能充電)。
  * A: 確認手機螢幕是否有跳出「允許 USB 偵錯嗎？」，請點「允許」。

## 7. 練習任務

**任務 1：修改 App 的主題顏色**

* **目標** ：找到 `lib/main.dart` 檔案，尋找 `ThemeData` 的設定。
* **動作** ：試著將 `primarySwatch` 或 `colorScheme` 的顏色改成你喜歡的顏色（例如 `Colors.green` 或 `Colors.purple`）。
* **驗證** ：存檔後觀察模擬器或手機，App 的標題列和按鈕顏色是否改變了？

**任務 2：留下你的簽名**

* **目標** ：修改 `lib/screens/setting_screen.dart` (設定頁面)。
* **動作** ：在頁面中加入一個 `Text` Widget，內容寫上：「設計者：[你的名字]」。
* **驗證** ：打開 App 的設定頁面，確認是否能看到你的名字出現在畫面上。

**任務 3：追蹤程式執行 (Debug 練習)**

* **目標** ：修改 `lib/screens/schedule/add_alarm_form.dart`。
* **動作** ：找到「儲存」或「新增」按鈕的 `onPressed` 事件，在裡面加入一行程式碼：

```
  print("正在新增藥物提醒...");
```

* **驗證** ：執行 App 並嘗試新增一個鬧鐘，觀察 VS Code 下方的 **Debug Console** 是否有印出這段文字。

**任務 4：探索外部套件**

* **目標** ：打開專案根目錄下的 `pubspec.yaml` 檔案。
* **動作** ：找到 `dependencies:` 區塊。
* **問題** ：請問這個專案使用的 `provider` 套件版本是多少？

**任務 5：調整顯示文字**

* **目標** ：修改 `lib/screens/main_screen.dart`。
* **動作** ：找到底部導航列 (BottomNavigationBar) 的設定，將其中一個標籤 (Tab) 的文字（例如 'Schedule' 或 'Family'）改成中文（例如 '時刻表' 或 '家人'）。
* **驗證** ：存檔後，確認 App 下方的按鈕文字是否變成了中文。

### 結語

* **View (Screens)** 負責長相。
* **Model** 負責資料格式。
* **Provider** 負責傳遞資料。
* **Service** 負責系統功能。
