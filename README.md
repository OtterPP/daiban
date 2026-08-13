# 待办

菜单栏待办。点一下菜单栏上的「待办」，**立刻就是输入框**，打字、回车，记下来。

不是 Dock 里的窗口应用，也不会先弹出一层菜单再点「记一件事」。

## 做什么

- 点菜单栏标题（例如「待办 3」）→ 弹出窗口，输入框已经聚焦，直接打字。
- 回车添加一条未完成待办。
- 点一行或左边圆圈，标记完成；完成项出现在下面很短的「已完成」里，再点可恢复。
- 悬停一行可删除；右键菜单里也有删除 / 润色。
- 可选「润色」：把草稿或已有条目收成一条短的、动词开头、可勾选的中文待办。
- 待办以 JSON 存在本机 Application Support，带创建时间和完成时间。
- 很小：没有项目、标签、日历、同步或账号。

## 怎么打开 / 构建

需要 **macOS 14+** 和 **Xcode**（Apple Silicon 上的 macOS 26 可直接用）。

### 用 Xcode（推荐）

1. 打开 `Daiban.xcodeproj`。
2. 选中 target **Daiban** → **Signing & Capabilities** → 选你自己的 Team（个人 Apple ID 即可）。
3. 点 Run（⌘R）。Dock 里不会跳图标；看屏幕右上角菜单栏，应出现 **待办 0**。
4. 点它，应立刻能输入。

第一次从 Xcode 以外启动未签名包时，系统可能拦一下：到「系统设置 → 隐私与安全性」允许即可。

### 命令行

```bash
chmod +x scripts/build.sh
./scripts/build.sh
open build/Build/Products/Release/Daiban.app
```

或：

```bash
xcodebuild \
  -project Daiban.xcodeproj \
  -scheme Daiban \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build \
  build

open build/Build/Products/Release/Daiban.app
```

若命令行签名失败，在 Xcode 里选好 Team 后再编，或加上你的团队 ID：

```bash
xcodebuild -project Daiban.xcodeproj -scheme Daiban -destination 'generic/platform=macOS' DEVELOPMENT_TEAM=YOUR_TEAM_ID build
```

这是 **LSUIElement / agent** 应用：不进 Dock、不进 ⌘Tab。退出用弹出窗口左下角的「退出」，或活动监视器。

## 点击为什么直接是输入框

`MenuBarExtra` 用了 `.menuBarExtraStyle(.window)`，所以点菜单栏是弹出窗口，不是系统下拉菜单。

窗口一成为 key window，输入框会 `makeFirstResponder`，光标已经在里面。按回车记下，输入框清空并保持焦点，可以连续记几条。

## 可选润色 / API Key

输入框右侧的魔法棒，或一行上的「润色」：

1. **没填密钥**：本地清理，去掉「我想 / 能不能 / 帮我 / 一下 / 吧」等填充，不联网。
2. **填了密钥**：调用兼容 OpenAI 的 `POST {base}/chat/completions`。

默认：

- 地址：`https://api.x.ai/v1`
- 模型：`grok-3-mini`

在弹出窗口点 **设置…**（或系统设置里的 待办）：

- 把 API Key 贴进密钥框。密钥写入 **本机钥匙串**（`com.byteotter.daiban`），**不会进 git、不会进 Application Support 的待办文件**。
- 需要的话改接口地址和模型（任何 OpenAI 兼容服务都可以）。
- 清空密钥即删除钥匙串条目，之后只走本地清理。

不要把密钥写进仓库、`.env` 或源码。`.gitignore` 已忽略常见密钥文件名。

## 数据与隐私

- 待办存在：
  - `~/Library/Containers/com.byteotter.daiban/Data/Library/Application Support/Daiban/todos.json`（沙盒，正式运行）
  - 或 `~/Library/Application Support/Daiban/todos.json`（若未沙盒）
- 每条包含：标题、是否完成、`createdAt`、`doneAt`。
- 不建账号，不同步，不上云。
- 只有你点「润色」且设置了密钥时，才会把**那一条文字**发到你配置的接口。密钥留在钥匙串。
- 本仓库不含待办数据，也不含密钥。

## 技术

Swift + SwiftUI，macOS 14+。菜单栏用 `MenuBarExtra` + window style；`Info.plist` 里 `LSUIElement` 为 true。MIT 许可见 [LICENSE](LICENSE)。
