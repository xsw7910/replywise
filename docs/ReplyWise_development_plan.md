# ReplyWise — Flutter 开发实施文档

> 配套文档：《ReplyWise — 跨语言智能回复 App 产品设计文档 v2》。
> 本文件按 **Flutter + Riverpod + go_router + 本地存储 + FastAPI 后端 + Oracle Free VM + Docker/Caddy + RevenueCat** 重新规划，参考 Rental Expense Keeper 的开发方式。

读者：Flutter / 后端 / 发布测试
目标：先完成 Android MVP，可进入 Google Play Internal Testing。

> **v3.3 收尾小修（文字一致性 + 实施细节，改完即开工，不再大改）**
> - 修复文字不一致：术语改名表述（§v2要点）、§3.9 限频结论统一为 DB 计数、§18 二期表去掉"内存计数"、§17 开发顺序与 §14 对齐。
> - 测试/定义对齐：第 6 次免费用尽错误码改 `PAYWALL_REQUIRED`（§13）；§16 MVP 定义补 credit 包。
> - 数据表增强：`usage_events` 加 `source` 与 `prompt_version` 字段 + 复合索引（§7.1）。
> - 限频与计费解耦：限频计数与计费扣减是两套，幂等回放/409 不计限频（§3.9）。
> - Phase 5 拆成 5A 订阅 / 5B credit 包（§14）；幂等清理任务落到 Phase 4（§14）。
> - 实现备注：canonicalize 用 `model_dump(mode="json")` 防 Enum 序列化坑（§3.6）；credits/sync 全量对账长期降频备注（§6.3a、§18）；account linking 冲突合并归二期（§21）。
> - **语言处理规则明确（§4.5、§6.4）**：文字 guidance 不让用户选语言（后端自动识别，用户无感）；语音 guidance 默认 Auto Detect、保留手动切换兜底；解释/Explain 输出语言跟随 App 界面语言，不依赖 guidance 检测。

> **v3.2 小修订（基于三份 review，仅补实施细节，不改架构 → 改完即开工）**
> - **计费正确性**：`free_uses_used` 永远据实累计，premium 期间不清零，掉回 free 时用 `limit-used` 恢复真实余额（§3.1）；`EntitlementState.freeUsesLeft` 改 `int?`（§3.1）；credit sync 在试用/premium 期间不误扣（§3.3、§6.3a）。
> - **工程防错**：`request_hash` 只由后端计算（前端不参与），对补默认后的 dict 排序紧凑序列化再 SHA-256，并提供 dev-only `/v1/debug/canonicalize`（§3.6、§6.9）；限频全部改 DB 计数（不用内存，避免重启清零）（§3.9）；asyncpg 短事务 + 连接池 min5/max20（§3.6、§5.1）；JWT pepper 应急轮换 + token 黑名单预留（§3.8）。
> - **范围/顺序**：Phase 2A 鉴权提前（§14）；regenerate 结果页加"将扣 1 次"提示（§3.2、§4.2）。
> - **UI**：玻璃输入框聚焦时面板 opacity 0.20→0.45 保证可读性（§19.2）。
> - **新增**：§21 决策记录（集中记录关键取舍的理由）。

> **本轮修订要点（v2）**
> - **术语统一**：用户输入的核心概念从 `instruction` 统一改名为 **`guidance`**（API 字段、Dart 状态、prompt、UI 文案全改），这是产品最大卖点，命名要一致（全局、§8）。
> - **Explain 融入 Reply**：Explain 不是独立功能/页面，而是 Reply 页内的辅助按钮（Bottom Sheet 展示）；返回升级为四段 `meaning / tone / hiddenMeaning / suggestedReplies`（§4.2、§6.6）。
> - **接口一致性修正**：polish 响应补齐 `source`/`paidCredits`；explain 等所有接口的 usage 遵循 premium 语义（`freeUsesLeft=null`）；新增 premium 完整响应示例；`creditsUsed` 语义钉死（§3.1、§6.4–6.6）。
> - **正确性修补**：credit 入账增加"启动/进 paywall 自动对账"防丢单（§3.3、§6.3a）；`request_hash` 规范化规则明确（§3.6）；限频重启清零的局限与 explain 日限落库（§3.9）；`expiresIn` 与 access token 时长对齐为 7 天（§3.8、§6.0）；`is_blocked` 写进建表语句（§7.1）。
> - **Paywall 文案**：默认突出 "3-day Free Trial" 与 "Buy Credits" 两条路径，而非只写 Upgrade（§3.4）。
> - **Guidance Library**（常用指导快捷语）：作为提高使用频率的轻量功能纳入（§4.5）。
> - **新增 §20 Future-proofing**：Email 登录、云同步/历史、多 App 后端隔离的 day-1 预留（结构预留，MVP 不启用）。
> - **产品取舍记录**：免费 5 次 + regenerate 照扣，先上线看数据再调（§3.2）；outputLang MVP 固定 `en`（§6.4）。

---

## 0. 总体技术路线

### 0.1 架构总览

```text
Flutter App
 ├─ Reply / Polish UI
 ├─ Voice input
 ├─ Clipboard helper
 ├─ RevenueCat SDK
 ├─ Local settings/cache
 └─ API client
 ↓ HTTPS

Oracle Free VM
 ├─ Caddy reverse proxy
 ├─ Docker Compose
 └─ FastAPI backend
 ├─ /health
 ├─ /v1/me
 ├─ /v1/reply
 ├─ /v1/polish
 ├─ /v1/explain
 ├─ /v1/entitlement/sync
 ├─ Usage limiter
 ├─ RevenueCat verifier
 └─ LLM provider adapter
```

### 0.2 关键原则

1. **模型 API key 只放后端**，Flutter App 不直接调用 OpenAI / Claude / DeepSeek。
2. **免费 lifetime 5 次以后端为准**，本地只做缓存展示。
3. **RevenueCat entitlement 以后端校验为准**，不能只相信客户端传来的 premium 状态。
4. **默认不保存用户消息正文**，只保存 usage 和订阅状态。
5. **先 Android 普通 App 上线**，不要在 MVP 同时做悬浮球 / iOS 键盘扩展。
6. **复用 Rental Expense Keeper 的发布经验**：dart-define、internal testing、RevenueCat entitlement、Oracle VM、Caddy HTTPS、后端 health check。

### 0.3 鉴权与防滥用模型

**问题**：仅凭客户端传来的 `X-App-User-Id` / `X-Device-Id` 识别用户是不安全的——这两个值客户端可任意伪造。若不加保护，攻击者可以：换 `appUserId` 无限刷免费 5 次；或伪造 premium 头白嫖模型调用。`appUserId` 是 RevenueCat 标识，不是密钥，**不能当鉴权凭证**。

**MVP 的最低安全基线**（在"不强迫登录"前提下成立）：

1. **设备级匿名 token**：App 首次启动调用 `POST /v1/auth/anonymous`，后端签发一个绑定 deviceId 的 JWT（有效期较长 + refresh）。此后所有 `/v1/*` 业务请求必须带 `Authorization: Bearer <token>`。这挡住"改 header 直接刷次数"。
2. **premium 状态只认后端回查**：客户端的 RevenueCat 状态只用于即时 UI；**能否生成、用哪个模型，一律由后端用 RevenueCat secret key 按 appUserId 回查后的可信缓存决定**。任何请求头里的 premium 标记一律忽略。（修正 v2 中 §3.3 原则与 §6.3 实现不一致的问题。）
3. **多层防刷**：在 token 之上叠加 IP 限频 + 设备指纹异常检测，用于发现批量注册匿名 token 的滥用。
4. **explain 等"不计次"接口也要限频**（见 §6.6），否则成为白嫖模型的后门。

> 注意：这套基线能显著提高滥用门槛，但**无法 100% 防止技术手段绕过**（见 §3.5）。MVP 目标是"够用"，不是"绝对防刷"。

---

## 1. Flutter 技术栈

| 模块 | 建议 |
|---|---|
| Flutter | 3.x stable |
| 状态管理 | Riverpod |
| 路由 | go_router |
| 本地存储 | shared_preferences + drift 可选 |
| 安全存储 | flutter_secure_storage（存 JWT access/refresh token） |
| 网络 | dio 或 http |
| JSON | freezed + json_serializable 或手写 DTO |
| 订阅 | purchases_flutter |
| 语音 | speech_to_text 或平台通道 |
| 剪贴板 | Flutter Clipboard API |
| 错误监控 | 先用日志，后续 Sentry |
| 测试 | flutter_test + mocktail |
| 主题 | 单一淡蓝色玻璃拟态，玻璃用 BackdropFilter（§19）；第一版不做切换/深色 |

### 1.1 推荐目录结构

```text
lib/
 main.dart
 app.dart

 core/
 config/
 app_config.dart
 network/
 api_client.dart
 api_error.dart
 storage/
 local_settings_repository.dart
 theme/
 app_theme.dart
 app_skin.dart # 淡蓝色玻璃拟态 token（单一主题，§19）
 widgets/
 primary_button.dart
 app_text_field.dart
 usage_badge.dart

 features/
 auth/
 application/
 auth_controller.dart # 启动鉴权、token 刷新、401 全局处理
 data/
 auth_repository.dart # /v1/auth/anonymous, /v1/auth/refresh
 token_storage.dart # flutter_secure_storage 读写 token
 domain/
 auth_state.dart

 reply/
 presentation/
 reply_screen.dart
 reply_result_card.dart
 audience_selector.dart
 application/
 reply_controller.dart
 data/
 reply_repository.dart
 reply_dtos.dart
 domain/
 reply_models.dart

 polish/
 presentation/
 polish_screen.dart
 application/
 polish_controller.dart
 data/
 polish_repository.dart
 domain/

 entitlement/
 presentation/
 paywall_screen.dart
 application/
 entitlement_controller.dart
 data/
 revenuecat_entitlement_repository.dart
 backend_entitlement_repository.dart
 domain/
 entitlement_state.dart

 settings/
 presentation/
 settings_screen.dart
```

---

## 2. App 配置

### 2.1 dart-define

参考 Rental Expense Keeper 的方式，使用 dart-define 区分环境。

```bash
flutter run \
 --dart-define=REPLY_BACKEND_BASE_URL=https://api-reply.novaaistudio.ca \
 --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxxxxx \
 --dart-define=REVENUECAT_ENTITLEMENT_ID=premium \
 --dart-define=REPLY_ENV=dev
```

release build：

```bash
flutter build appbundle --release \
 --dart-define=REPLY_BACKEND_BASE_URL=https://api-reply.novaaistudio.ca \
 --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxxxxx \
 --dart-define=REVENUECAT_ENTITLEMENT_ID=premium \
 --dart-define=REPLY_ENV=prod
```

### 2.2 AppConfig

```dart
class AppConfig {
 static const backendBaseUrl = String.fromEnvironment(
 'REPLY_BACKEND_BASE_URL',
 defaultValue: 'http://10.0.2.2:8000',
 );

 static const revenueCatAndroidApiKey = String.fromEnvironment(
 'REVENUECAT_ANDROID_API_KEY',
 );

 static const entitlementId = String.fromEnvironment(
 'REVENUECAT_ENTITLEMENT_ID',
 defaultValue: 'premium',
 );

 static const env = String.fromEnvironment(
 'REPLY_ENV',
 defaultValue: 'dev',
 );
}
```

---

## 3. Entitlement 与免费次数设计

### 3.1 状态模型

```dart
class EntitlementState {
  final bool isPremium;
  final int freeUsesLimit;     // 5
  final int freeUsesUsed;
  final int? freeUsesLeft;     // premium 时为 null，必须可空
  final int paidCredits;       // 已购买的可用 credit 余额（一次性包累加）
  final bool upgradeRequired;
  final String? message;
}
```

放行与扣减规则（三层：免费 → credit → 订阅）：

```text
isPremium == true
  → 允许生成（无限/高额度），不扣免费次数、不扣 credit

isPremium == false && freeUsesLeft > 0
  → 允许，优先扣免费次数（freeUsesUsed + 1）

isPremium == false && freeUsesLeft <= 0 && paidCredits > 0
  → 允许，扣 1 个 paidCredits

isPremium == false && freeUsesLeft <= 0 && paidCredits <= 0
  → 阻止生成，显示 paywall（可选订阅 或 购买 credit 包）
```

> 扣减优先级固定为：**先用免费 5 次，免费用完再用购买的 credit**。premium 订阅用户两者都跳过。

**关键：`free_uses_used` 永远据实累计，premium 期间绝不清零（v3.2 修正，防"过期后免费额度消失"）**

这是一个隐蔽但严重的计费 bug 来源，务必照此实现：

- `usage_summary.free_uses_used` 是**客观事实**，取值始终在 `0..free_uses_limit`，**与用户当前是否 premium 无关**。它只在"非 premium 且本次扣的是免费额度"时 +1，其它任何情况（premium、扣 credit、试用期）都**不改动**它。
- premium / 试用期用户：跳过一切扣减，`free_uses_used` 保持原值不动（用户订阅前用了 2 次，订阅期间它就一直是 2）。
- 后端组装响应时**动态计算** `freeUsesLeft`：
  ```text
  freeUsesLeft = isPremium ? null : (free_uses_limit - free_uses_used)
  ```
- 这样当用户**订阅过期/取消/试用到期掉回 free** 时，`isPremium` 变 false，后端立即用 `limit - used` 返回真实剩余（如还剩 3 次），用户无缝接回订阅前没用完的免费额度，**不会"莫名其妙清零或消失"**。
- 红线：**任何分支都不允许把 `free_uses_used` 重置为 0 或在 premium 期间改写它**。premium 只影响"响应里 freeUsesLeft 是否塞 null"，不影响底层计数。

**premium 下的字段语义**：当 `isPremium == true` 时，客户端**只看 `isPremium` 判断是否放行**，`freeUsesLeft` 在 premium 时所有接口统一返回 `null`（包括 `/v1/me`、`/v1/entitlement/sync`、生成接口的 usage）。`creditsUsed` 表示本次消耗的免费次数（premium 恒为 0）。

**非 premium 的余额展示**：UI 显示"剩余可用 = freeUsesLeft + paidCredits"，或分两行（免费 X、已购 Y）。

客户端约束：
- Dart DTO 中 `freeUsesLeft` 必须可空：`final int? freeUsesLeft;`。
- usage badge 文案逻辑：
  ```dart
  String get usageText {
    if (isPremium) return "Premium";
    final free = freeUsesLeft ?? 0;
    return "${free + paidCredits} left";   // 或 "免费 $free · 已购 $paidCredits"
  }
  ```
- premium 用户 UI 永不显示剩余次数。
- 后端即使 premium 不扣任何额度，仍把实际 token 消耗写入 `usage_events`，供成本分析。

**`creditsUsed` 字段语义（钉死，避免三层模型下歧义）**：`creditsUsed` = 本次消耗的额度数量，生成成功恒为 `1`，premium 恒为 `0`。**它不区分来源**——来源由 `source` 字段表示（`free` = 扣免费额度，`credit` = 扣已购 credit，`null` = premium 未扣）。所有生成接口（reply / polish）的 usage 都必须返回 `creditsUsed` + `source` 两个字段，前端据 `source` 决定刷新哪个余额。

**premium 用户完整响应示例（前端照此实现，所有接口一致）**：
```json
{
  "isPremium": true,
  "freeUsesLimit": 5,
  "freeUsesUsed": 0,
  "freeUsesLeft": null,
  "paidCredits": 0,
  "upgradeRequired": false,
  "usage": {
    "creditsUsed": 0,
    "source": null,
    "freeUsesLeft": null,
    "paidCredits": 0
  }
}
```
> 规则统一：**任何接口、任何时候，premium 用户的 `freeUsesLeft` 一律为 `null`**（包括 /v1/me、/v1/entitlement/sync、reply、polish、explain 的 usage 块）。前端只用 `isPremium` 判断放行，绝不读 premium 用户的 `freeUsesLeft`。

### 3.2 免费次数与 credit 包

免费额度固定：

```text
FREE_LIFETIME_LIMIT = 5
```

> **产品取舍：regenerate 照扣，先上线看数据**。reply 一次生成扣 1 次（产出 3 个版本）；用户对结果不满意点"重新生成"（regenerate）**同样扣 1 次**。已知风险：免费仅 5 次，用户可能因反复试错快速耗尽、在转化前先挫败。本版**先保持 5 次 + regenerate 照扣**上线，通过 §9 指标（尤其"免费耗尽前的生成次数分布""耗尽用户的转化率"）观察真实试错率，再决定是否：(a) 提高 `FREE_LIFETIME_LIMIT`、(b) 对同一输入的前 N 次 regenerate 免扣、或 (c) 首装赠送额外次数。**这是一个待验证的运营参数，不是定论**——`FREE_LIFETIME_LIMIT` 必须可配置（见 §10），便于上线后不发版就调整。

> **UI 提示（减少意外扣费投诉）**：结果页的"重新生成"按钮旁/点击时，对**非 premium 用户**明确提示"本次重新生成将消耗 1 次"（如二次确认或按钮副文案），让用户知情后再扣。premium 用户不提示。

一次性 credit 包（消耗型内购，三档；价格按 Google/Apple 抽成 15–30% + 模型成本定，单价随包变大递减以鼓励买大包）：

| 包 | 次数 | Product ID（建议） |
|---|---|---|
| 小包 | 10 | `credits_10` |
| 中包 | 50 | `credits_50` |
| 大包 | 100 | `credits_100` |

> credit 是"消耗型"内购（consumable），可重复购买、累加到 `paidCredits` 余额；与订阅并存，互不冲突。

计数接口由后端返回（非 premium）：

```json
{
  "isPremium": false,
  "freeUsesLimit": 5,
  "freeUsesUsed": 2,
  "freeUsesLeft": 3,
  "paidCredits": 50,
  "upgradeRequired": false
}
```

### 3.3 RevenueCat entitlement 与免费试用

RevenueCat 配置：

- Entitlement：`premium`
- Offering：`default`
- Package：monthly subscription
- Product ID 示例：`reply_premium_monthly`
- **免费试用：在 Google Play 该订阅的 base plan 上配置 3 天 free trial offer**（不是在代码里写），RevenueCat 自动识别。

免费试用的关键事实（务必理解，避免做错）：

- **试用期内 entitlement 就是 active 的**，所以试用用户的 `isPremium` 天然为 true、可无限用——后端"按 entitlement 判断 premium"的逻辑无需为试用做任何特殊处理。
- 3 天后未取消 → Google 自动扣月费、entitlement 继续 active；用户取消 → 到期后 entitlement 变 inactive，后端 sync 后回到 free。
- **每个 Google 账号每个订阅只能试用一次**（平台保证），换账号薅属于"提高门槛不能根绝"，与免费 5 次同理，不必额外防。
- 因为有"取消/到期"这个异步事件，**RevenueCat webhook 的重要性上升**（见 §18）：若仅靠用户主动打开 App 触发 sync，已取消/过期的用户可能短时间继续被当 premium。MVP 可接受这个延迟（下次 sync 即纠正），但 webhook 应尽早补上。

**试用 + credit 包并存的扣费语义（务必明确，避免误扣）**：
- 试用期用户 `isPremium=true`，按 §3.1 **跳过所有扣减**——既不扣免费 5 次，**也不扣已购 credit**。即用户在试用期内即使之前买过 credit，也是"免费"消耗，`paid_credits` 不动。
- **试用到期 / 取消 / 转正失败导致掉回非 premium 时，用户之前购买的 `paid_credits` 必须原样保留**（试用期从未触碰过它）。掉回后扣费顺序恢复为"免费剩余 → credit"。
- 开发红线：**消耗**额度时，第一道判断永远是 `if isPremium: return (不扣任何额度)`，credit 扣减（`paid_credits - 1`）只在非 premium 分支发生。**绝不允许在 premium/试用分支里对 `paid_credits` 做减法**。（注意：credit 入账加法 `paid_credits + N` 是另一回事，见下，premium 期间也照常入账。）

**credit sync 与试用/premium 的交互（v3.2 明确，防误扣/防丢失）**：`/v1/credits/sync` 的职责是"把已购买的 credit **入账**到 `paid_credits`"，它**只增不减**，与是否 premium 无关——即使用户在试用/premium 期间买了 credit 包，sync 也照常把它**入账存起来**（`paid_credits += N`），只是这些 credit 在 premium 期间不会被消耗。这样试用到期掉回 free 后，用户试用期买的 credit 完好可用。**绝不能因为"当前是 premium"就跳过 credit 入账**，否则用户花钱买的 credit 凭空消失。一句话区分：**premium 不影响"入账"（照存），只影响"消耗"（不扣）**。

Flutter 启动时：

1. 初始化 RevenueCat。
2. 获取或创建 appUserId。
3. 调用 `Purchases.getCustomerInfo`。
4. 判断 `customerInfo.entitlements.active['premium']`（试用期也算 active）。
5. 调用后端 `/v1/entitlement/sync`，让后端校验并缓存状态。
6. UI 使用后端 `/v1/me` 返回的最终状态。

重要：

- 客户端可以用 RevenueCat 状态做即时 UI 更新。
- 是否允许后端生成，必须由后端再次校验或使用已同步的可信缓存。

### 3.4 Paywall 行为

触发 paywall 的位置：

- 点击 Generate Reply / Polish 前，且免费与 credit 都已用尽
- Settings 中 Upgrade / Buy credits 按钮

Paywall 提供**两条付费路径**（用户二选一）：

- **订阅**：monthly premium，**含 3 天免费试用**，适合高频用户。
- **一次性 credit 包**：10 / 50 / 100 三档，适合不想订阅、偶尔用的用户。

Paywall 必须支持：

- 加载 offerings（订阅 package + 三个 credit consumable package）
- 购买订阅 monthly package（首次自动进入 3 天试用）
- 购买 credit 包（consumable，可重复买）
- Restore purchases（恢复订阅；credit 是消耗型，不可"恢复"，但已入账的余额在后端，换设备登录同 appUserId 即可读回）
- 订阅购买成功 → 调 `/v1/entitlement/sync` 刷新；credit 购买成功 → 调 `/v1/credits/sync` 入账并刷新 `/v1/me`
- RevenueCat 配置错误时显示错误文案

**试用文案合规（必做，否则审核被拒/退款差评）**：订阅按钮区必须明确写出试用条款，例如：
> "3 天免费试用，之后 ¥X/月，可随时取消"（"Free for 3 days, then $X/month. Cancel anytime."）

**Paywall UI 默认强调（提升转化）**：主按钮文案默认突出试用而非"Upgrade"——首屏主 CTA 为 **"Start 3-day Free Trial"**，副文案 "then $X/month · Cancel anytime"；并列展示 **"Buy Credits"** 入口（10 / 50 / 100）。避免只写 "Upgrade to Premium" 这类弱转化文案。两条路径都要让用户一眼看懂"试用免费"和"按次买断"的区别。

**credit 防丢单——自动对账（重要）**：`/v1/credits/sync` 是幂等的，因此除"购买成功后立即调用"外，客户端还须在 **App 每次启动** 和 **每次打开 paywall** 时各调一次做对账。理由：用户付款成功但 App 在调 sync 前崩溃/被杀/断网时，这笔交易在 RevenueCat 存在、但后端未入账；自动对账会把"曾购买但未入账"的交易补回，避免"买了 credit 没到账"的投诉。二期 webhook 上线后由 webhook 兜底（见 §18），但客户端自动对账作为 MVP 的必备防线先做。

### 3.5 免费次数防刷的现实预期

v2 写了"免费次数必须在后端记录，避免卸载重装绕过"，但需要澄清一个工程现实：

- **Android 卸载重装后 deviceId 通常会变**（除非用不随重装变化的标识，而那些标识有隐私合规风险，不建议）。因此单靠 deviceId 无法真正阻止"重装重置 5 次"。
- 结论：**lifetime 5 次的防刷目标是"提高门槛"，不是"绝对锁死"**。免费额度本就是获客成本，少数人绕过可接受，不值得为此引入侵入性标识。

务实的锚点策略（按可靠性排序，组合使用）：

1. **RevenueCat `appUserId` 为主锚**：它在 restore 后能跟回同一用户，比 deviceId 稳。匿名 token 签发时把 appUserId 一并绑定。
2. **deviceId 为辅锚**：用于关联同一安装周期内的请求。
3. **IP + 设备指纹做异常检测**：发现短时间同 IP 大量新匿名 token，触发限流/告警，而不是逐个硬封。

> 实现上：用量计在"后端 user（由 appUserId 关联）"维度，而非纯 deviceId 维度。文档其余处提到的"以后端为准"均指此。

**appUserId 的客户端生成策略**：不要依赖 RevenueCat 自动生成的 anonymous id，因为后端需要稳定识别同一用户。首次启动：

1. 生成 UUID 作为 `appUserId`，写入 `flutter_secure_storage`。
2. `Purchases.configure` 时**显式传入这个 appUserId**。
3. 调 `/v1/auth/anonymous` 时带上同一 appUserId 完成绑定。
4. 之后即使卸载重装，只要能从 RevenueCat restore 回同一 appUserId，就能凭它重新 `/v1/auth/anonymous` 拿回同一后端 user。

### 3.6 扣次数的原子性与幂等

v2 的"先检查 entitlement → 生成 → 成功后扣 1 次"存在两个隐患：并发竞态（同一用户快速点两次可能都通过检查）、以及"模型成功但扣减失败"导致白送或重复扣。修订为：

**预扣 + 回滚 + 幂等** 模式：

1. **幂等键**：客户端每次生成请求带 `X-Idempotency-Key`（UUID v4，需用加密安全随机数）。**`request_hash` 完全由后端计算，前端不参与**（v3.2 明确）——避免 Flutter 的 `json_serializable` 与 FastAPI 的 Pydantic 在浮点（`65` vs `65.0`）、布尔（`true` vs `1`）、空格 trim 上序列化不一致，导致两端 hash 不同、退避重试全部误触发 `IDEMPOTENCY_CONFLICT`。

   后端计算 `request_hash` 的固定算法（提供一个 `canonicalize(payload) -> str` 纯函数，reply/polish 共用）：
   - **不要哈希客户端传来的原始 JSON 字符串**；而是先让 Pydantic 强校验、填充默认值，得到规范化的 Python `dict`；
   - **先 `payload.model_dump(mode="json")` 再处理**（v3.3 提醒）：直接 dump 含 `StrEnum`（如 `audience.mode`）或 datetime 的模型，`json.dumps` 可能序列化成 `"<AudienceMode.auto: 'auto'>"` 之类的非预期串，导致 hash 不稳定。`mode="json"` 会把 Enum/datetime 转成纯 JSON 兼容值（`"auto"`），务必先转再清洗。
   - 对该 dict：**先剔除所有值为 `null` 的字段，再补齐固定默认值**（`audience.mode→"auto"`、`formality→50`、`outputLang→"en"`），两步顺序固定（先剔 null 再补默认）；
   - 递归按 key 排序，序列化为**无多余空白的紧凑 JSON**（`separators=(',', ':')`、`sort_keys=True`、`ensure_ascii=False`），字符串值 trim；
   - 对该紧凑字符串取 `SHA-256` 即 `request_hash`。
   - 写单测覆盖"传 `null` vs 不传该字段 → 相同 hash"、"`65` vs `65.0` → 相同 hash"、"Enum 值序列化为纯字符串"。
   ```python
   def canonicalize(payload: ReplyRequest) -> str:
       raw = payload.model_dump(mode="json")   # 先转纯 JSON 兼容 dict，解决 Enum/datetime
       clean = strip_nulls_then_fill_defaults(raw)  # 先剔 null，再补默认（顺序固定）
       return json.dumps(clean, separators=(',', ':'), sort_keys=True, ensure_ascii=False)
   ```

   后端按 key 查记录，结合 `request_hash` 与 `status` 判断：
   - **同 key + 同 request_hash + status=succeeded**：直接回放上次结果，不重复扣费、不重复调模型。
   - **同 key + 同 request_hash + status=processing**：说明上一次仍在处理（如网络中断重试），返回 `409` / `IDEMPOTENCY_CONFLICT` 让客户端保持 loading 稍后重试，**不重复调度模型**。
   - **同 key + 不同 request_hash**：键被错误复用于不同请求，返回 `IDEMPOTENCY_CONFLICT`，拒绝而非回放旧结果。
 - **status=failed**：视为可重试——删除该 key 记录或允许覆盖，按新请求处理（避免旧失败结果卡住用户）。
2. **原子预扣（先免费、后 credit）**：premium 用户跳过预扣。非 premium 用单条原子 SQL 尝试，避免 read-modify-write 竞态。先尝试扣免费额度：
 ```sql
 -- 第一步：优先扣免费额度
 UPDATE usage_summary
    SET free_uses_used = free_uses_used + 1, updated_at = :now
  WHERE user_id = :uid AND free_uses_used < free_uses_limit;
 -- rowcount = 1 → 本次记 source='free'
 ```
 若 rowcount = 0（免费已用完），再尝试扣 1 个已购 credit：
 ```sql
 -- 第二步：免费用尽，扣购买的 credit
 UPDATE usage_summary
    SET paid_credits = paid_credits - 1, updated_at = :now
  WHERE user_id = :uid AND paid_credits > 0;
 -- rowcount = 1 → 本次记 source='credit'
 ```
 两步都 rowcount = 0（免费和 credit 都为 0）→ 返回 `PAYWALL_REQUIRED`，不调模型。预扣前先把幂等记录置为 `status=processing`，并记录本次扣的是 `free` 还是 `credit`（回滚时要还回正确的池）。
3. **调用模型**：预扣成功后再调模型。
4. **失败回滚**：模型调用失败（超时/解析失败/5xx）时，按预扣来源把那 1 次还回去，并将幂等记录置为 `status=failed`：
 ```sql
 -- source='free' 时：
 UPDATE usage_summary SET free_uses_used = free_uses_used - 1
  WHERE user_id = :uid AND free_uses_used > 0;
 -- source='credit' 时：
 UPDATE usage_summary SET paid_credits = paid_credits + 1
  WHERE user_id = :uid;
 ```
 同时记录一条 `success=0` 的 usage_event。
5. **成功落库**：成功后将幂等记录置 `status=succeeded` 并写入 `response_json` 与 `expires_at`（TTL 如 24h），过期由清理任务回收。

> 这样无论并发、重试还是中途失败，免费次数和已购 credit 都不会被多扣或漏扣，且永远先扣免费、后扣 credit。

**异步与事务边界**：后端用 FastAPI + 异步驱动（`postgresql+asyncpg`，不要同步 `psycopg`），且 **LLM 调用绝不在打开的 DB 事务内进行**——LLM 生成要 2–5 秒，若期间持有事务/连接，并发时会迅速耗尽 PostgreSQL 连接池。正确生命周期：

1. **事务一（短）**：原子预扣 `usage_summary` + 插入 `idempotency_keys(status=processing)` → 立即 commit、释放连接。用 `async with session.begin():` 包裹，代码块结束即释放连接回池。
2. **事务外**：异步调用 LLM（用 `httpx` 显式 `timeout=15s`；超时/失败立刻进入回滚）。**调 LLM 期间不得持有任何活跃 DB session/连接**——否则多个并发用户遇到 LLM 慢响应时，连接池会被瞬间占满（即使 CPU 空闲）。
3. **事务二（短）**：成功则更新 `idempotency_keys=succeeded` 并写 `usage_events`；失败则按来源回滚（free 还 free、credit 还 credit）+ `status=failed` + 记 `success=0` → commit。

> 连接池建议：asyncpg `min_size=5, max_size=20`（按 Oracle Free VM 资源与并发调）。
> 任何同步阻塞（同步 DB 驱动、同步 HTTP）都会卡死 uvicorn 事件循环，务必全链路 async。

### 3.7 客户端启动鉴权与 token 刷新流程

避免 token 过期后 App 卡住，客户端启动按下列顺序处理：

```text
启动
 ├─ 从 flutter_secure_storage 读取 accessToken / refreshToken
 ├─ 若无 token → 调 /v1/auth/anonymous（带本地 appUserId）→ 存 token
 ├─ 若有 accessToken → 调 /v1/me
 │ ├─ 200 → 正常进入
 │ └─ 401 / TOKEN_EXPIRED → 调 /v1/auth/refresh（带 refreshToken）
 │ ├─ 成功 → 存新 token → 重试 /v1/me
 │ └─ 失败 → 调 /v1/auth/anonymous（凭 appUserId 重新绑定）→ 存 token → /v1/me
```

实现要点：
- 用一个 `AuthService`（Riverpod provider）独占 token 生命周期；所有请求经全局 dio interceptor 委托给它。
- interceptor 捕获 401：自动 refresh 一次并重放原请求；refresh 失败再走 anonymous。
- **单飞 refresh**：同一时刻只允许一个 refresh 在飞，其余 401 请求入队等待，refresh 成功后用新 token 统一重放，避免 refresh 风暴。
- **409 退避重试**：interceptor 收到 `IDEMPOTENCY_CONFLICT`（处理中）时，**不冒泡给 UI**，而是带同一 `X-Idempotency-Key` 指数退避重试（1s→2s→…最多 3 次）；原请求在此窗口内完成后，重试会命中 succeeded 分支无缝拿到结果。
- anonymous 也失败（如离线）时：指数退避 + 最多 3 次后再报"网络错误"，不要白屏，不要无限循环。

### 3.8 JWT 细节

- payload 至少包含：`user_id`、`app_user_id`、`device_hash`、`iat`、`exp`、`jti`（JWT ID）。
- **device_hash 用 server pepper**：`device_hash = SHA-256(deviceId + SERVER_PEPPER)`，pepper 是服务端环境变量密钥。仅哈希可预测的硬件标识易被彩虹表反查，加 pepper 防止 DB 泄漏时被还原。
- **jti / token_version 支持服务端主动失效**：发现滥用时可把该 user 的 token 版本号 +1，使旧 token 全部失效。
- **access token 默认 7 天**+ refresh token 较长期；短 access + 自动 refresh（§3.7）对用户无感，但显著缩小泄漏窗口。生产建议 refresh rotation（归 §18），MVP 先不做但保留约定。
- `JWT_SECRET`、`SERVER_PEPPER` 足够长且随机，dev/prod 不同（见 §10）。
- **pepper / secret 泄漏应急流程（v3.2 补充）**：若 `JWT_SECRET` 或 `SERVER_PEPPER` 疑似泄漏——轮换环境变量里的密钥 → 所有现存 access/refresh token 立即失效 → 客户端下次请求收到 401 后自动走 `/v1/auth/anonymous` 凭 appUserId 重新签发（§3.7 已有此兜底路径），对用户基本无感（计费数据绑 user_id，不丢）。轮换 `SERVER_PEPPER` 会使旧 `device_hash` 失配，可接受（device_hash 仅作辅助指纹，非身份主键）。
- **token 黑名单（预留）**：jti 已入 payload。MVP 先用 `token_version`（user 行上一个整数，签发时写入 token、校验时比对，+1 即令该 user 所有旧 token 失效）实现"主动失效"；二期再上独立 `token_blacklist` 表 / Redis 做更细粒度的短期黑名单与 refresh rotation（归 §18）。

### 3.9 限频

在免费次数/订阅之外，加一层与计费无关的防滥用限频，防单用户高频刷 premium 成本或 DoS：

- 生成接口（reply / polish）：滑动窗口，如每用户每分钟最多 8 次。
- explain：每用户每日 10 次。
- 超限返回 `RATE_LIMITED`，并区分"免费额度用尽（PAYWALL_REQUIRED）"与"频率过高（RATE_LIMITED）"两种语义，便于 UI 文案。
- **限频计数统一用 DB（不用内存），见下方 v3.2 说明。**

**已知局限与处理（v3.2：MVP 限频统一用 DB 计数，不用内存）**：内存计数在后端重启（部署/崩溃）后会清零，给刷的窗口。MVP 既然已有 `usage_events` 表，限频统一改为 **DB 计数**，重启不丢：
- 生成接口（reply/polish）每分钟限频：`SELECT count(*) FROM usage_events WHERE user_id=? AND endpoint IN ('reply','polish') AND created_at >= now()-60s`。
- explain 每日限频：`SELECT count(*) ... AND endpoint='explain' AND created_at >= 当日0点`。
- DB 计数比内存稍慢，但对 MVP 并发量完全够用，且正确性有保证。
- 多实例 / 高并发时再迁移到 Redis 滑动窗口（归 §18）。
- 注意：限频计数应统计**所有尝试**（含失败），避免靠制造失败绕过；或按"成功 + 进入模型调用的请求"计，按实现简单度取其一并写明。

**限频计数 ≠ 计费扣减（v3.3 明确，两套独立逻辑）**：
- **计费扣减**（§3.6）：决定扣 free 还是 credit、失败回滚——关注"这次该不该花用户的额度"。
- **限频计数**（本节）：决定要不要 `RATE_LIMITED`——关注"这个用户短时间是否调太频繁"。
- 两者**不可共用同一个 count**，各算各的。
- **幂等回放与 409 冲突不计入限频**：客户端 409 退避重试（§3.7）带同一 `X-Idempotency-Key`，命中 succeeded 直接回放、或 processing 返回 409 时，这些**不是新的模型调用**，限频不应计数，否则正常用户一次操作因重试被误判超频。即：**限频只统计"真正进入模型调用"的请求**。
- 实现优化：限频查询不需要精确 count，`SELECT 1 ... LIMIT N` 判断是否达阈值即可提前退出（doc9 建议），配合 §7.1 的 `(user_id, endpoint, created_at)` 复合索引。

---

## 4. Flutter 页面与流程

### 4.1 路由

```text
/
 → ReplyScreen

/polish
 → PolishScreen

/paywall
 → PaywallScreen

/settings
 → SettingsScreen
```

也可以用 bottom navigation：

- Reply
- Polish
- Settings

### 4.2 ReplyScreen 状态

字段：

```dart
incomingText
guidanceText
guidanceLang
audienceMode // auto | preset | custom
audiencePreset // boss | client | colleague | friend
audienceCustom
formality // 0-100
isGenerating
result
error
// Explain（融入 Reply，非独立功能）
isExplaining
explainResult     // {meaning, tone, hiddenMeaning, suggestedReplies}
```

> **删除 `lengthPreference`**。Reply 已输出 Professional / Friendly / Short 三个版本，长短由这三个版本天然覆盖，再加长短配置只会让 prompt 和 UI 更复杂。第一版要的是"快"和"简单"；"更短/更详细"留到二期。

**Explain 融入 Reply（产品决策）**：Explain 不是独立页面或独立 Tab，而是 Reply 页"对方消息"输入框旁的一个辅助按钮。完整心智流是：

```text
Reply 页
  对方消息  ──[Explain 按钮]──> Bottom Sheet 展示 meaning/tone/hiddenMeaning/suggestedReplies
     ↓
  Your Guidance（母语说意图）
     ↓
  Generate Reply
```

- 点 "Explain" → 调 `/v1/explain` → 用 **Bottom Sheet** 展示四段结果（含意 / 语气 / 言外之意 / 建议回法），不跳页、不打断填写。
- Bottom Sheet 内的 `suggestedReplies` 可点击"采用"，把某条建议填入 guidance 作为起点（仍由用户确认后 Generate）。
- Explain 结果支持"Copy Explanation"（便于分享/记录）。
- 不做独立的 ExplainScreen。

**Guidance Library（常用指导快捷语，提高使用频率）**：在 guidance 输入框上方放一排可点的 chips，点一下即填入/追加到 guidance，免去每次手打。MVP 内置一组多语言预设（按 guidanceLang 显示对应语言）：

```text
Be polite           礼貌一点
Keep it short       简短一些
Don't be too formal 别太正式
Decline politely    委婉拒绝
Be confident        语气肯定
Add appreciation    表达感谢
```

- MVP：内置固定列表，纯本地、不联网、不计费。
- 二期：用户自定义常用语 + 云端同步（归 §20）。

生成流程：

```text
User taps Generate
 ↓
EntitlementController.ensureAiAccess
 ↓
if blocked → Paywall
 ↓
ReplyRepository.generateReply
 ↓
Backend /v1/reply
 ↓
Show result cards（每个版本含 Copy；底部含 Regenerate）
 ↓
Refresh /v1/me
```

> **Regenerate**：结果区底部提供"重新生成"按钮，沿用当前 incoming/guidance/audience，不需重填。注意按 §3.2，regenerate 照常扣 1 次额度。

### 4.3 PolishScreen 状态

字段：

```dart
draftText
direction // natural | professional | friendly | concise | custom
customGuidance
guidanceLang
isGenerating
result
error
```

生成流程与 Reply 类似。

### 4.4 Copy 行为

生成结果中每个版本都有 Copy。

复制后：

- Snackbar：`Copied`
- 可选 haptic feedback
- 不自动跳回其他 App
- 不自动发送

### 4.5 Audience 预设与语言处理

**Audience 预设**：除 auto（默认）与 custom 外，预设按钮建议比最初的 4 个略丰富，覆盖高频场景：

```text
Boss / Client / Colleague / Teacher / Friend / Dating / Custom
```

- `auto` 仍是默认：不选时由模型从对方消息语气推断（见 §6.4）。
- 预设只是把一个语义标签喂给 prompt，加项几乎零成本；但不要过多，保持一屏可选完。
- `custom` 允许母语自由描述关系（如"房东""面试官"）。

**语言处理总规则（v3.3 钉死，三件事分开处理）**

这是常见困惑点，明确区分"文字 guidance 的语言""语音 guidance 的语言""解释/Explain 的输出语言"三件事：

**1. 文字 guidance —— 不让用户选语言，后端自动识别，用户无感。**
- 大模型本身多语言，prompt 里只说"用户 guidance 可能是任意语言，理解其意图、输出英文"即可，模型自适应，**无需知道具体语种**。
- `guidanceLang` 字段**不作为用户必选项**。后端可用轻量语言检测库（如 `langdetect` / `fasttext`）自动推断后填入，**仅用于日志统计和决定解释语言的兜底**，不暴露成"打字前先选语言"的步骤——那是多余摩擦。
- 客户端打字时不弹任何"选择语言"。

**2. 语音 guidance —— 默认 Auto Detect / 跟随界面语言，保留可手动切换兜底。**

```text
Auto Detect（默认）/ 中文 / English / 日本語 / Español …
```

- 语音识别（STT）需要先知道按哪种语言解码才转得准，所以语音比文字多一层"语种"考量。
- **默认 Auto Detect**：让用户开口即说、零操作；识别后回填 guidance 输入框，可改后再生成。
- **现实坑**：Auto Detect 在"说话很短""中英混说"时易判错语种，一旦判错整句转错；且 Flutter `speech_to_text` 依赖系统引擎，自动检测支持度因机型而异，部分机型需显式传 locale 才稳。
- **兜底**：保留一个不显眼的语言切换入口；若真机实测某机型 Auto Detect 不准，**默认退化为"跟随 App 界面语言"的 locale** 比硬上自动检测更稳（见 §14 Phase 2B 验收）。
- 不可用时优雅回退到打字并提示，不能点了没反应。

**3. 解释 / Explain 的输出语言 —— 用 App 界面语言（母语），不依赖 guidance 检测结果。**
- "为什么这样写"(reply 的 why) 和 Explain 四段(meaning/tone/hiddenMeaning) 必须用**用户能读懂的母语**。
- 这个母语取 **App 界面语言**（即系统语言/用户在设置里选的 App 语言），作为 `guidanceLang`/`explainLang` 传给后端——**而不是用 guidance 文本的检测结果**。
- 原因：即使 guidance 语种检测偏差（比如把中文里夹的英文词判成英语），解释仍稳定输出用户母语，不会出现"解释突然变成英文看不懂"。

> 一句话总结：**文字不让用户选语言（后端自动）；语音默认 Auto Detect 可手动切；解释语言跟随 App 界面语言。** 三者各管各的，互不依赖。

---

## 5. 后端技术栈

### 5.1 选择

建议沿用 Rental Expense Keeper 的 FastAPI 路线。

| 模块 | 选型 |
|---|---|
| API | FastAPI |
| Server | uvicorn |
| 数据 | SQLite 起步，后续 PostgreSQL |
| 异步驱动 | `postgresql+asyncpg`（禁用同步 psycopg，避免阻塞事件循环） |
| HTTP 客户端 | `httpx`（异步，LLM 调用显式 `timeout=15s`） |
| 部署 | Docker |
| 反向代理 | Caddy |
| 运行 | Oracle Free VM |
| 模型 | OpenAI / Claude / DeepSeek adapter |
| 订阅校验 | RevenueCat REST API / Webhook |
| 日志 | Python logging |

MVP 可以先用 SQLite，因为数据量很小，部署简单。后续用户增长再迁移 PostgreSQL。

**MVP production 直接用 PostgreSQL，SQLite 仅本地 dev。** 三轮 review 一致建议，理由：

- 免费次数扣减、幂等、订阅状态都属"计费相关数据"，并发正确性不容妥协。
- Phase 4/5 必然要写并发扣减自动化测试，SQLite 即便开 WAL，多 worker 并发写仍易 `database is locked`。
- 你已有 Oracle Free VM，Docker Compose 加一个 Postgres 容器仅几分钟，省去后续锁排查与数据迁移成本。
- 迁移成本在早期最低——晚迁不如不迁。

约定：
- `MVP production`：PostgreSQL（Docker 容器，见 §9.3 增补）。
- `Local dev / prototype`：可用 SQLite 快速起步。

若在 dev 仍用 SQLite，初始化必须执行：

```sql
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout=10000;
PRAGMA synchronous=NORMAL;
```

> 扣减/回滚必须用 §3.6 的单条原子 `UPDATE ... WHERE free_uses_used < free_uses_limit`，禁止 SELECT 后再 UPDATE。PostgreSQL 下同样适用（`UPDATE ... RETURNING` 可一步拿到结果）。

### 5.2 后端目录结构

```text
backend/
 app/
 main.py
 config.py
 database.py

 api/
 health.py
 me.py
 reply.py
 polish.py
 explain.py
 entitlement.py

 services/
 ai_service.py
 model_router.py
 usage_service.py
 revenuecat_service.py
 device_identity_service.py

 schemas/
 reply.py
 polish.py
 entitlement.py
 usage.py

 models/
 user.py
 usage_event.py
 subscription_cache.py

 tests/
 test_reply.py
 test_polish.py
 test_usage.py
 test_entitlement.py

 Dockerfile
 docker-compose.yml
 requirements.txt
```

---

## 6. 后端 API 契约

> **鉴权约定**：除 `/health` 与 `/v1/auth/anonymous` 外，所有 `/v1/*` 接口必须带 `Authorization: Bearer <token>`。生成类接口（reply/polish）还需带 `X-Idempotency-Key`。后端从 token 解析出可信的 userId，**不信任请求体/请求头里的身份或 premium 字段**。

### 6.0 POST /v1/auth/anonymous

App 首次启动调用，换取设备级匿名 token。

请求：

```json
{
 "deviceId": "device-uuid",
 "appUserId": "revenuecat-app-user-id",
 "platform": "android"
}
```

后端行为：

1. 按 appUserId 查找或创建匿名 user（appUserId 为主锚，deviceId 为辅，见 §3.5）。**本接口是唯一创建 user 的入口**（见 §6.2）。
2. 签发绑定 userId 的 JWT（access + refresh），payload 含 `user_id`、`app_user_id`、`device_hash`、`iat`、`exp`、`jti`（见 §3.8）。
3. 返回 token 与初始 entitlement。

响应：

```json
{
 "accessToken": "jwt...",
 "refreshToken": "jwt...",
 "expiresIn": 604800,
 "me": {
 "isPremium": false,
 "freeUsesLimit": 5,
 "freeUsesUsed": 0,
 "freeUsesLeft": 5,
 "paidCredits": 0,
 "upgradeRequired": false
 }
}
```

> `expiresIn` 是 **access token** 的有效秒数，与 §3.8 的"access token 默认 7 天"一致（604800 秒）。refresh token 另设更长有效期，不在此字段体现。

> 配套 `POST /v1/auth/refresh`（用 refreshToken 换新 accessToken；生产建议 refresh rotation）。Token 丢失或过期时，客户端可凭 appUserId 重新调用本接口（restore 后仍关联同一 user）。完整启动/刷新流程见 §3.7。

### 6.1 GET /health

响应：

```json
{
 "status": "ok",
 "service": "reply-backend"
}
```

### 6.2 POST /v1/entitlement/sync

> 本接口**必须带 `Authorization: Bearer`**，且**不负责创建 user**——创建 user 唯一归属 `/v1/auth/anonymous`。本接口只更新"当前 token 对应 user"的 RevenueCat 状态。这样职责清晰，也避免被用来批量创建匿名用户。

请求头：
```text
Authorization: Bearer <accessToken>
```
请求体：
```json
{
 "platform": "android"
}
```
> appUserId 不从请求体取——以 token 中绑定的为准，防止伪造他人 appUserId 拉取/篡改状态。

后端行为：

1. 从 token 解析 userId 与其绑定的 appUserId。
2. 用 RevenueCat secret key 按该 appUserId 查询 entitlement。
3. 更新该 user 的 subscription cache（active / expired）。
4. 返回该 user 合并后的 entitlement + usage。（user 必须已存在；不存在视为异常，返回 401，引导客户端走 anonymous。）

响应（premium 示例，注意 `freeUsesLeft` 为 null）：

```json
{
 "isPremium": true,
 "freeUsesLimit": 5,
 "freeUsesUsed": 0,
 "freeUsesLeft": null,
 "paidCredits": 0,
 "upgradeRequired": false
}
```

### 6.3 GET /v1/me

请求头：

```text
Authorization: Bearer <accessToken>
```

> 用户身份从 token 解析，**不再用 `X-App-User-Id` / `X-Device-Id` 作为身份依据**（那些可伪造）。premium 状态返回的是后端按 appUserId 回查 RevenueCat 后的可信缓存值（见 §0.3、§6.2）。

响应：

```json
{
 "isPremium": false,
 "freeUsesLimit": 5,
 "freeUsesUsed": 3,
 "freeUsesLeft": 2,
 "paidCredits": 50,
 "upgradeRequired": false
}
```

> premium 用户时 `freeUsesLeft` 返回 `null`，客户端只依据 `isPremium` 放行（见 §3.1）。非 premium 用户的可用总数 = `freeUsesLeft + paidCredits`。

### 6.3a POST /v1/credits/sync — credit 购买入账

用户买了 credit 包后调用，由后端凭 RevenueCat 交易校验并入账。**必须带 token；不信任客户端报的购买结果。**

请求头：
```text
Authorization: Bearer <accessToken>
```
请求体：
```json
{ "platform": "android" }
```

后端行为（防重放是关键）：

1. 从 token 解析 userId 与绑定的 appUserId。
2. 用 RevenueCat secret key 查该 appUserId 的**非订阅交易（consumable purchases）**列表。
3. 对每一笔交易，以 `transaction_id` 为主键尝试写入 `credit_purchases`：
   - 若该 `transaction_id` 已存在 → **跳过**（已入账，幂等，绝不重复加 credit）。
   - 若是新交易 → 在一个事务里：插入 `credit_purchases` + `usage_summary.paid_credits += credits_granted`（按 product_id 映射 10/50/100）。
4. 返回最新的 entitlement + usage（含 `paidCredits`）。

响应：
```json
{
 "isPremium": false,
 "freeUsesLeft": 0,
 "paidCredits": 60,
 "grantedThisSync": 50,
 "upgradeRequired": false
}
```

> 安全要点：consumable 内购容易被重放/伪造，**入账只认 RevenueCat 校验过的交易**，且每个 `transaction_id` 只入账一次（数据库主键天然保证）。客户端任何"我买了 X 次"的声明都不作为入账依据。

> **调用时机（防丢单，见 §3.4）**：本接口幂等，客户端应在 **(1) 购买成功后立即**、**(2) App 每次启动**、**(3) 每次打开 paywall** 都调用一次，把"已付款但上次未入账"的交易补回。`grantedThisSync` 为 0 表示无新交易入账（正常）。

> **长期性能备注（归 §18 二期优化）**：本接口"拉该用户全部 consumable 历史交易、逐条比对入账"。对买过很多次的老用户 + 每次启动都调，长期有 RevenueCat API 配额与延迟压力。MVP 量小无碍；二期上 webhook 增量入账后，客户端这个高频全量对账应**降频**——例如改为"仅购买成功后 + 本地标记有未确认交易时"才调，而非每次启动都全量拉。

### 6.4 POST /v1/reply

> **`outputLang` 的 MVP 行为（明确）**：MVP **固定输出英文（`outputLang` 恒为 `"en"`）**，符合产品定位"回出地道英文"。请求体保留该字段是为未来扩展（如输出其他语言），但 MVP 阶段后端忽略客户端传值、一律按 `en` 处理，客户端也固定传 `"en"`。**不在 MVP 做对方消息语言检测或让用户选输出语言**——避免无谓复杂度。

> **`guidanceLang` 字段语义（v3.3 明确，见 §4.5）**：它**不是让用户在打字前手选的语言**。客户端传的值 = **App 界面语言**（系统/设置里的 App 语言），用途是告诉后端"用什么语言写 why 解释"。文字 guidance 本身的语种由模型自适应理解，无需此字段；后端也可对 guidance 文本做轻量语言检测仅作统计。语音 guidance 的识别语种是另一回事（Auto Detect / 可切，§4.5），与本字段无关。

请求：

```json
{
 "incoming": "Can we move the meeting to next week?",
 "guidance": "答应他，但希望最晚周三定下来",
 "guidanceLang": "zh",
 "outputLang": "en",
 "audience": {
 "mode": "auto",
 "preset": null,
 "custom": null,
 "formality": 65
 }
}
```

响应：

```json
{
 "versions": [
 {
 "label": "Professional",
 "text": "Of course — next week works for me. Would it be possible to confirm the new time by Wednesday?"
 },
 {
 "label": "Friendly",
 "text": "Sure, next week works for me. Could we confirm the time by Wednesday?"
 },
 {
 "label": "Short",
 "text": "Sure, next week works. Please confirm the time by Wednesday."
 }
 ],
 "why": "这里用 'Would it be possible' 比直接说 'Can you' 更礼貌，适合工作场景。",
 "usage": {
 "creditsUsed": 1,
 "source": "free",
 "freeUsesLeft": 4,
 "paidCredits": 50
 }
}
```

> `source` 表示本次扣的是 `free`（免费额度）还是 `credit`（已购 credit）；premium 时为 `null`、`creditsUsed` 为 0。

扣次数规则（详见 §3.6）：

- 请求需带 `Authorization: Bearer` 与 `X-Idempotency-Key`。
- 先查幂等键：命中则直接返回上次结果，不重复调模型/扣费。
- 非 premium：原子预扣，**先扣免费额度、免费用尽再扣 1 个 paidCredits**；两者都为 0 → 返回 `PAYWALL_REQUIRED`，不调模型。
- premium 用户：跳过预扣，仅记 usage_event，`freeUsesLeft` 返回 `null`、`creditsUsed` 为 0。
- 模型调用成功 → 落幂等结果；模型失败 → **按来源回滚那 1 次**（free 还 free、credit 还 credit），记 `success=0` 的 usage_event。
- polish 同理。

### 6.5 POST /v1/polish

请求：

```json
{
 "draft": "I want to ask you about the report status.",
 "direction": "professional",
 "custom": null,
 "guidanceLang": "zh"
}
```

响应：

```json
{
 "polished": "I wanted to check in on the status of the report.",
 "changes": "把 'I want to ask' 改成 'I wanted to check in'，语气更自然也更专业。",
 "usage": {
 "creditsUsed": 1,
 "source": "free",
 "freeUsesLeft": 3,
 "paidCredits": 50
 }
}
```

> polish 与 reply 共用同一套三层扣费与 usage 结构：`usage` 必含 `creditsUsed`、`source`、`freeUsesLeft`、`paidCredits` 四字段，premium 时 `creditsUsed=0`、`source=null`、`freeUsesLeft=null`。前端解析 reply / polish 响应使用同一个 DTO。

### 6.6 POST /v1/explain

> explain 用低成本模型且 `creditsUsed: 0`（不计免费额度），但**正因免费，它是被刷模型的靶子**。必须加独立限频：每 user **每日 10 次**（落库计数，见 §3.9），超出返回 `RATE_LIMITED`。explain 需带 `Authorization: Bearer`。**第一版 explain 不强制 `X-Idempotency-Key`**（它不扣费、无预扣回滚，无需幂等复杂度）；除非将来给 explain 计费，再对齐生成接口。

> **Explain 是 Reply 页的辅助工具**（见 §4.2），不是独立功能。返回升级为四段结构，价值远高于单句解释：含义 / 语气 / 言外之意 / 建议回法。

请求：

```json
{
 "text": "Things are pretty hectic on our end.",
 "explainLang": "zh"
}
```

响应：

```json
{
 "meaning": "意思是“我们这边现在比较忙乱、事情很多”。",
 "tone": "偏口语、随意，略带歉意，通常用于解释为什么延迟或改期。",
 "hiddenMeaning": "言外之意往往是“可能要往后拖一下，请你体谅”，是一种委婉的缓冲。",
 "suggestedReplies": [
   "No worries, take your time — just let me know once things settle.",
   "Totally understand. Could we aim to reconnect early next week?"
 ],
 "usage": {
 "creditsUsed": 0,
 "source": null,
 "freeUsesLeft": 3,
 "paidCredits": 0
 }
}
```

字段说明：
- `meaning`：字面/实际含义，用 `explainLang` 写。
- `tone`：语气与场合判断，用 `explainLang` 写。
- `hiddenMeaning`：言外之意 / 潜台词（非母语者最易漏掉的部分），用 `explainLang` 写；若确无言外之意可为空字符串。
- `suggestedReplies`：1–3 条**英文**建议回法（这是要发出去的内容，固定英文）；客户端可点"采用"填入 guidance（见 §4.2）。
- `usage`：遵循 §3.1 premium 语义——**premium 用户 `freeUsesLeft` 返回 `null`**；explain 不扣费，故 `creditsUsed` 恒为 0、`source` 恒为 null。

> Prompt 见 §8.3a（explain 四段 system prompt）。

### 6.7 输入校验与内容安全

所有生成接口在后端用 Pydantic 强校验，**客户端也前置同样限制**（在 `AppTextField` / controller 设 maxLength），避免用户输入超长才被后端 400 拦截：

| 字段 | 限制 |
|---|---|
| incoming | trim 后非空，≤ 4000 字符 |
| guidance | trim 后非空，≤ 1000 字符 |
| draft | trim 后非空，≤ 4000 字符 |
| custom（润色自定义） | ≤ 500 字符 |

其他规则：
- trim 后为空 → `VALIDATION_ERROR`，不调模型。
- 超长 → `INPUT_TOO_LONG`。
- 异常输入（超长重复字符、明显垃圾）可在后端做轻量规整或拒绝。
- **moderation / safety gate**：MVP 至少在后端加一道轻量过滤，拒绝明显违规/滥用请求（详细的内容审核归二期，见 §18）。

### 6.8 统一错误码表

| code | HTTP | 含义 | 客户端处理 |
|---|---|---|---|
| VALIDATION_ERROR | 400 | 参数缺失/空白 | 提示具体字段 |
| INPUT_TOO_LONG | 400 | 输入超长 | 提示精简 |
| UNAUTHENTICATED | 401 | 无 token / 无效 | 走 anonymous |
| TOKEN_EXPIRED | 401 | access 过期 | refresh 后重试（§3.7） |
| PAYWALL_REQUIRED | 402 | 免费额度用尽 | 显示 paywall |
| RATE_LIMITED | 429 | 频率过高 / explain 超日限 | 提示稍后再试 |
| IDEMPOTENCY_CONFLICT | 409 | 幂等键冲突或处理中 | 保持 loading 或提示重试 |
| MODEL_PARSE_ERROR | 502 | 模型输出无法解析 | 提示重试 |
| MODEL_UNAVAILABLE | 503 | 模型不可用且降级失败 | 稍后重试 |
| SUBSCRIPTION_SYNC_FAILED | 502 | RevenueCat 同步失败 | 提示重试，不阻断 free |
| REVENUECAT_UNAVAILABLE | 503 | RevenueCat 不可达 | 用上次缓存状态，提示稍后 |
| INTERNAL | 500 | 服务端异常 | 通用错误+重试 |

> 区分 `PAYWALL_REQUIRED`（额度用尽，引导升级）与 `RATE_LIMITED`（频率过高，稍后再试）两种语义，UI 文案不同。

### 6.9 POST /v1/debug/canonicalize（仅 dev 环境）

为排查"幂等 hash 不一致"问题提供的调试接口，**仅在 `APP_ENV=dev` 启用，prod 必须关闭/不挂载**。

请求：与 `/v1/reply` 或 `/v1/polish` 相同的请求体。
响应：
```json
{
  "canonical": "{\"audience\":{\"formality\":50,\"mode\":\"auto\"},\"guidance\":\"...\",\"incoming\":\"...\",\"outputLang\":\"en\"}",
  "request_hash": "9f2c…（SHA-256）"
}
```
用途：前端/联调时把可疑请求贴进来，看后端规范化后的紧凑串与 hash，快速定位是哪个字段（浮点、null、空格）导致 hash 偏差。因 `request_hash` 由后端独算（§3.6），此接口只是排查工具，不改变"前端不参与计算"的约定。

---

## 7. 数据模型

### 7.1 数据表（dev: SQLite / prod: PostgreSQL）

> 下面用 SQLite 语法示意；production 用 PostgreSQL（见 §5.1），类型相应调整（`TEXT`→`TEXT`/`UUID`、`INTEGER`→`INT`/`BOOLEAN`、时间用 `TIMESTAMPTZ`，自增用 `BIGSERIAL`）。原子扣减在 PG 下可用 `UPDATE ... WHERE ... RETURNING`。

```sql
CREATE TABLE users (
 id TEXT PRIMARY KEY,
 app_user_id TEXT UNIQUE NOT NULL,
 device_id TEXT,
 platform TEXT,
 is_blocked INTEGER NOT NULL DEFAULT 0,  -- 异常检测后封禁，配合 §3.8 jti 失效
 email TEXT,                              -- 预留：未来 email 登录（§20），MVP 恒为 null
 auth_provider TEXT,                      -- 预留：email | google | apple（§20）
 provider_user_id TEXT,                   -- 预留：第三方账号 id（§20）
 account_status TEXT NOT NULL DEFAULT 'anonymous',  -- anonymous | linked（§20）
 created_at TEXT NOT NULL,
 updated_at TEXT NOT NULL
);

CREATE TABLE subscription_cache (
 id TEXT PRIMARY KEY,
 user_id TEXT NOT NULL,
 is_premium INTEGER NOT NULL DEFAULT 0,
 entitlement_id TEXT NOT NULL DEFAULT 'premium',
 product_id TEXT,
 expires_at TEXT,
 last_verified_at TEXT,
 raw_status TEXT,
 FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE usage_summary (
 user_id TEXT PRIMARY KEY,
 free_uses_limit INTEGER NOT NULL DEFAULT 5,
 free_uses_used INTEGER NOT NULL DEFAULT 0,
 paid_credits INTEGER NOT NULL DEFAULT 0,   -- 已购买的可用 credit 余额
 updated_at TEXT NOT NULL,
 FOREIGN KEY(user_id) REFERENCES users(id)
);

-- credit 购买入账记录（按 transaction_id 幂等，防 consumable 重放刷量）
CREATE TABLE credit_purchases (
 transaction_id TEXT PRIMARY KEY,  -- RevenueCat/商店交易唯一 ID，天然幂等键
 user_id TEXT NOT NULL,
 product_id TEXT NOT NULL,         -- credits_10 | credits_50 | credits_100
 credits_granted INTEGER NOT NULL, -- 本次入账次数
 store TEXT,                       -- googleplay | appstore
 verified_at TEXT NOT NULL,
 raw_status TEXT,
 FOREIGN KEY(user_id) REFERENCES users(id)
);
CREATE INDEX idx_credit_purchases_user ON credit_purchases (user_id, verified_at);

CREATE TABLE usage_events (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 user_id TEXT NOT NULL,
 endpoint TEXT NOT NULL,
 model TEXT NOT NULL,
 credits_used INTEGER NOT NULL,
 source TEXT,                       -- free | credit | premium | explain（本次额度来源，便于成本分析，v3.3）
 prompt_version TEXT,               -- reply_v1 | polish_v1 | explain_v1（便于 A/B 与质量排查，v3.3）
 input_tokens INTEGER,
 output_tokens INTEGER,
 cache_hit INTEGER NOT NULL DEFAULT 0,
 success INTEGER NOT NULL,
 error_code TEXT,
 created_at TEXT NOT NULL,
 FOREIGN KEY(user_id) REFERENCES users(id)
);
-- 限频 DB 计数与用量统计用（§3.9）；PG 下为 B-tree 复合索引
CREATE INDEX idx_usage_events_user_ep_time ON usage_events (user_id, endpoint, created_at);

--幂等记录（也可用 Redis，设 TTL 24h）
CREATE TABLE idempotency_keys (
 key TEXT PRIMARY KEY,
 user_id TEXT NOT NULL,
 endpoint TEXT NOT NULL,
 request_hash TEXT NOT NULL, -- 请求体哈希，防同 key 用于不同请求
 status TEXT NOT NULL, -- processing | succeeded | failed
 response_json TEXT, -- 成功时缓存响应，命中直接回放
 error_code TEXT,
 created_at TEXT NOT NULL,
 expires_at TEXT NOT NULL
);
CREATE INDEX idx_idem_user_endpoint ON idempotency_keys (user_id, endpoint, created_at);
```

> 幂等命中逻辑见 §3.6：同 key+同 hash+succeeded 回放；processing 返回 `IDEMPOTENCY_CONFLICT`/保持 loading；同 key+不同 hash 返回 `IDEMPOTENCY_CONFLICT`；failed 允许覆盖重试。
> 需要一个定时清理任务按 `expires_at` 回收过期幂等记录。
> `is_blocked` 已写入 `users` 建表语句，供异常检测后封禁（配合 §3.8 的 jti 失效）。`email / auth_provider / provider_user_id / account_status` 为 §20 未来 email 登录预留，MVP 不使用。

> `usage_events` 增加 `cache_hit` 字段，用于观测 prompt 缓存命中率（见 §8.5）。
> 若用 SQLite，初始化时执行 `PRAGMA journal_mode=WAL;` 与 `PRAGMA busy_timeout=5000;`（见 §5.1）。
> 扣减/回滚必须用 §3.6 的单条原子 `UPDATE ... WHERE free_uses_used < free_uses_limit`，禁止 SELECT 后再 UPDATE。

### 7.2 不保存正文

不要保存：

- incoming
- guidance
- draft
- polished text
- generated reply

只保存：

- endpoint
- model
- token
- success / error
- credits used
- timestamp

如果以后要加入历史记录，默认存在本地；云历史必须单独开关和隐私说明。

---

## 8. AI Prompt 规格

### 8.1 Reply system prompt

```text
You help non-native English speakers reply to messages in natural English.
The user will provide:
1. the message they received,
2. their reply intention in their native language,
3. optional audience and tone preferences.

Generate native-level English replies that are clear, natural, and appropriate.
Do not sound like a literal translation.
Do not add facts that the user did not provide.

Return only valid JSON in this shape:
{
 "versions": [
 {"label": "Professional", "text": "..."},
 {"label": "Friendly", "text": "..."},
 {"label": "Short", "text": "..."}
 ],
 "why": "..."
}

The explanation in "why" must be written in the user's guidance language.
```

### 8.2 Polish system prompt

```text
You polish English written by non-native speakers.
Keep the original meaning.
Improve naturalness, tone, grammar, and clarity according to the requested direction.
Do not add new facts.

Return only valid JSON in this shape:
{
 "polished": "...",
 "changes": "..."
}

The explanation in "changes" must be written in the user's guidance language.
```

### 8.2a Explain system prompt（四段）

```text
You help non-native English speakers fully understand an English message they received.
Given the message, explain it for a non-native reader.

Return only valid JSON in this shape:
{
 "meaning": "...",
 "tone": "...",
 "hiddenMeaning": "...",
 "suggestedReplies": ["...", "..."]
}

Rules:
- "meaning", "tone", "hiddenMeaning" MUST be written in the user's explainLang.
- "hiddenMeaning" captures implied intent / subtext a non-native speaker may miss; use "" if there is none.
- "suggestedReplies": 1-3 short, natural English replies the user could send. These MUST be in English.
- Do not invent facts not present in the message.
```

> 模型按 §8.4 走低成本档（explain 不需要顶级英文生成质量；但 suggestedReplies 仍应自然）。

后端要做：

1. 尝试直接 parse。
2. 如果模型返回 ```json fence，strip 后 parse。
3. parse 失败，重试一次，附加 `Return valid JSON only`。
4. 仍失败，返回 `MODEL_PARSE_ERROR`。

### 8.4 模型选型与质量门槛

产品核心卖点是"地道英文输出"，这正是模型质量差异最大的环节。因此模型选型有一条硬约束：

- **不能只图便宜**。§10 的 `.env` 默认填了 `gpt-4o-mini` / `gpt-4.1-mini` 仅为快速跑通闭环；**这类小模型在语气拿捏与地道度上偏弱**，不能默认就当正式上线配置。
- **premium 档必须用质量达标的模型**。上线前用评测集实测对比候选模型（如 `gpt-4.1` 与 Claude Sonnet）在"按母语指导生成得体英文"上的表现，再定档。
- **质量是换便宜模型的前置门槛**：任何"为省成本换更小模型"的决定，必须先过 §13 的英文质量评测，地道度不达标不得上线。
- ModelRouter 抽象保留（按 free/premium/explain 路由），模型名走 `.env`，便于切换与 A/B，但默认值不等于上线值。

### 8.5 Prompt 缓存

固定的 system prompt 每次都一样，应利用 prompt 缓存降低输入成本（OpenAI 自动命中固定前缀，Claude 需显式标记缓存）。落地要点：

- 把固定指令放在 prompt **最前**，可变内容（incoming / guidance / draft）放在后面，最大化前缀命中。
- 在 `usage_events.cache_hit` 记录是否命中，监控命中率。
- lifetime 5 次免费下成本压力不大，但 premium 重度用户的成本主要靠此项控制。

---

## 9. Oracle Free VM 部署

### 9.1 域名规划

建议新增子域名：

```text
api-reply.novaaistudio.ca
```

DNS：

```text
A api-reply.novaaistudio.ca → Oracle VM public IP
```

### 9.2 Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 9.3 docker-compose.yml

如果 VM 上已经有多个 App，可继续用不同端口区分。

```yaml
services:
 reply-backend:
 build: .
 container_name: reply-backend
 restart: unless-stopped
 env_file:
 - .env
 ports:
 - "127.0.0.1:8003:8000"
 depends_on:
 - reply-db
 volumes:
 - ./data:/app/data

 reply-db:
 image: postgres:16-alpine
 container_name: reply-db
 restart: unless-stopped
 environment:
 POSTGRES_USER: reply
 POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
 POSTGRES_DB: reply
 volumes:
 - ./pgdata:/var/lib/postgresql/data
 # 仅本机访问，不对公网暴露端口
```

> production 用上面的 `reply-db`（PostgreSQL），`.env` 里 `DATABASE_URL=postgresql+asyncpg://reply:${POSTGRES_PASSWORD}@reply-db:5432/reply`（异步驱动）。本地 dev 可省略 db 容器、用 SQLite（`sqlite+aiosqlite`）。Postgres 端口不要映射到公网。

建议端口：

```text
hairtrack-backend 127.0.0.1:8000
rental-backend 127.0.0.1:8001
welcome-backend 127.0.0.1:8002
reply-backend 127.0.0.1:8003
```

### 9.4 Caddyfile

```caddyfile
api-reply.novaaistudio.ca {
 encode gzip

 reverse_proxy 127.0.0.1:8003

 header {
 Strict-Transport-Security "max-age=31536000;"
 }
}
```

> Caddy 会自动为该域名签发并续期 Let's Encrypt 证书，无需手动配置。前提：服务器 80 和 443 端口对公网开放（Oracle VM 安全组 + 本机防火墙都要放行），且域名 A 记录已正确解析到 VM 公网 IP。首次启动 Caddy 时会自动完成 ACME 验证。

检查：

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo systemctl reload caddy
curl https://api-reply.novaaistudio.ca/health
```

---

## 10. 后端环境变量

`.env` 示例：

```bash
APP_ENV=prod
# production 用 PostgreSQL + 异步驱动 asyncpg；本地 dev 可用 sqlite+aiosqlite
DATABASE_URL=postgresql+asyncpg://reply:${POSTGRES_PASSWORD}@reply-db:5432/reply
POSTGRES_PASSWORD=change-me-strong

FREE_LIFETIME_LIMIT=5

#JWT 与限频
JWT_SECRET=change-me-long-random
SERVER_PEPPER=change-me-another-long-random # device_hash 加盐
JWT_ACCESS_TTL_SECONDS=604800 # 7 天（原 30 天偏松）
JWT_REFRESH_TTL_SECONDS=15552000
EXPLAIN_DAILY_LIMIT=10
GEN_RATE_PER_MINUTE=8
IDEMPOTENCY_TTL_SECONDS=86400

REVENUECAT_SECRET_API_KEY=sk_xxxxxx
REVENUECAT_ENTITLEMENT_ID=premium

# credit 包：product_id -> 入账次数（与 RevenueCat/商店一致）
CREDITS_PRODUCT_10=credits_10
CREDITS_PRODUCT_50=credits_50
CREDITS_PRODUCT_100=credits_100
CREDITS_GRANT_10=10
CREDITS_GRANT_50=50
CREDITS_GRANT_100=100

MODEL_PROVIDER=openai
OPENAI_API_KEY=sk_xxxxxx
MODEL_REPLY_FREE=gpt-4o-mini
MODEL_REPLY_PREMIUM=gpt-4.1-mini
MODEL_POLISH_FREE=gpt-4o-mini
MODEL_POLISH_PREMIUM=gpt-4.1-mini
MODEL_EXPLAIN=gpt-4o-mini

MAX_INPUT_CHARS=4000
MAX_INSTRUCTION_CHARS=1000
MAX_OUTPUT_TOKENS_REPLY=900
MAX_OUTPUT_TOKENS_POLISH=700
MAX_OUTPUT_TOKENS_EXPLAIN=250
```

注意：

- 不要把 `.env` commit 到 Git。
- 不要把 model key 放 Flutter。
- Google Play / RevenueCat keys 按 dev/prod 分开。
- `JWT_SECRET` 必须是足够长的随机串，dev/prod 不同；泄漏等于所有匿名 token 可被伪造。
- 上面的 `MODEL_*` 默认值（gpt-4o-mini 等）仅为跑通闭环；**正式上线的 premium 模型须经 §8.4 质量评测后再定**，不要直接用默认小模型上线。

---

## 11. RevenueCat 配置步骤

### 11.1 Google Play Console

1. 创建 App。
2. 上传一个 internal testing AAB。
3. 创建 subscription product：
 - Product ID：`reply_premium_monthly`，Base plan：monthly
 - 在该 base plan 上添加 **free trial offer：3 天**（首次订阅者可享，平台限每账号每订阅一次）
4. 创建三个**一次性内购（in-app product / consumable）**：
 - `credits_10`、`credits_50`、`credits_100`
5. 激活所有产品。
6. 添加测试账号，确认 license tester 可购买测试订阅与测试内购。

### 11.2 RevenueCat Dashboard

1. 创建 Project。
2. 添加 Android App。
3. 配置 Google Play service credentials。
4. 导入 Google Play subscription **和三个 consumable 内购**。
5. 创建 Entitlement：`premium`，把 subscription product attach 到它。
6. credit 包**不挂 entitlement**（它们是消耗型、不是长期权益）——后端通过查询非订阅交易来入账。
7. 创建 Offering `default`，添加：monthly 订阅 package + 三个 credit consumable package。
8. Flutter 用 Android public SDK key；后端用 RevenueCat secret key 查询订阅状态与 consumable 交易。

### 11.3 常见错误

| 问题 | 原因 | 处理 |
|---|---|---|
| 购买成功但 premium 不更新 | product 未 attach 到 entitlement | 检查 RevenueCat entitlement |
| Offerings 为空 | Google Play 产品未激活或未同步 | 等待同步，检查 package id |
| 测试购买失败 | 测试账号未加入 license testers | 添加测试账号 |
| App 中 premium 已显示但后端仍 blocked | 后端未 sync RevenueCat | 购买成功后调用 `/v1/entitlement/sync` |
| Restore 没效果 | appUserId 不一致 | 固定 RevenueCat appUserId 并本地保存 |

---

## 12. Google Play 发布注意事项

### 12.1 Store Listing

不要夸大功能。

可以写：

- AI reply assistant
- Polish English messages
- Voice input for your intention
- Copy ready-to-send replies
- 5 free AI uses
- Premium subscription with 3-day free trial
- Credit packs available (no subscription needed)

不要写：

- 自动读取所有 App 消息
- 自动发送消息
- 后台监听剪贴板
- 悬浮球，如果第一版没做

### 12.2 Data Safety

需要披露：

- App 会发送用户输入文本到后端用于 AI 生成。
- App 不出售数据。
- 默认不保存消息正文。
- 可能收集 device ID / app user ID / purchase status / usage count。
- 麦克风权限仅用于语音输入。
- 剪贴板仅在用户操作或开启自动粘贴时读取。

### 12.3 Privacy Policy

必须包含：

- 收集哪些数据
- 为什么收集
- AI 生成请求如何处理
- 是否保存正文
- 订阅和支付由 Google Play / RevenueCat 处理
- 用户如何联系删除数据

---

## 13. 测试计划

### 13.1 Flutter 单元测试

至少覆盖：

- freeUsesLeft > 0 可生成
- freeUsesLeft == 0 且非 premium 显示 paywall
- premium 用户可生成
- RevenueCat restore 后刷新状态
- Reply 请求参数正确
- Polish 请求参数正确
- 错误码映射 UI 文案

### 13.2 后端测试

至少覆盖：

- `/health`
- `/v1/auth/anonymous` 创建匿名用户并签发 token
- 缺少/伪造 token 的请求被拒（401 UNAUTHORIZED）
- 伪造 premium 头无效——premium 只认后端 RevenueCat 回查
- `/v1/me` 用 token 解析身份（不依赖 X-App-User-Id）
- free lifetime 5 次计数
- **免费用尽且无 credit 时，第 6 次返回 `PAYWALL_REQUIRED`（不是 RATE_LIMITED）**；`RATE_LIMITED` 仅用于每分钟超 8 次或 explain 超日限
- free 用尽但有 credit 时，第 6 次改扣 credit、`source='credit'`，不报 paywall
- 并发扣减：同用户并发两次生成，总扣减不超额（原子 SQL 验证）
- 幂等：同一 `X-Idempotency-Key` + 同 request_hash 重复请求只扣一次、只调一次模型
- 幂等冲突：同 key + 不同 request_hash → IDEMPOTENCY_CONFLICT
- 幂等处理中：status=processing 时重试 → 不重复调度模型
- token 过期 → refresh 成功后重试通过；refresh 失败 → 走 anonymous 恢复
- 输入超长 → INPUT_TOO_LONG；空白 trim → VALIDATION_ERROR
- premium 用户不受 free limit 限制，freeUsesLeft 返回 null
- 模型失败回滚预扣的次数（不白扣）
- explain 超出每日 10 次返回 `RATE_LIMITED`
- 生成接口每分钟超 8 次触发 RATE_LIMITED
- JSON parse 失败返回 `MODEL_PARSE_ERROR`
- RevenueCat sync active / inactive entitlement
- /v1/entitlement/sync 不创建 user（无 token 直接 401）

> 并发压测可用 Locust / pytest-xdist / `asyncio.gather` 轰炸 `/v1/reply`，确保 `usage_summary` 绝不越界。

### 13.3 手动测试清单

Android internal test：

1. 新安装 App，显示 `5 free AI uses left`。
2. 生成 1 次 reply，变成 4。
3. 生成 1 次 polish，变成 3。
4. 连续用完 5 次。
5. 第 6 次点击生成，出现 paywall（含订阅与 credit 两条路径）。
6. 买 credit 小包（10）→ 免费用尽后能继续生成，paidCredits 递减。
7. 重复触发 credit sync，验证不重复入账（幂等）。
8. 购买 monthly subscription → 进入 3 天免费试用，premium active、不再 blocked。
9. 试用期内取消订阅 → 到期后 sync，状态回到 free/credit。
10. paywall 文案明确显示"3 天免费、之后按月收费、可取消"。
11. 卸载重装，premium restore 正常；同 appUserId 登录能读回 paidCredits 余额。
12. 取消订阅 / 过期后，后端状态能回到 free。

---

## 14. 分阶段开发计划

> **顺序与并行（v3.2）**：阶段编号不等于严格串行。关键约束是 **Phase 2A（匿名鉴权）必须在任何业务接口（reply/polish/explain/me/sync）之前完成**——它是整个系统的安全基线。Phase 1（静态 UI，纯 fake data、不依赖 token）**可与 Phase 2A 并行或略后**。推荐实际推进：0A → 0B → 2A（与 1 并行）→ 2B → 3 → 4 → 5 → 6 → 7。Phase 3 可先返回 fake usage、不接扣费，把扣费/幂等/回滚集中放到 Phase 4 彻底验证。

### Phase 0A — 本地 skeleton

目标：Flutter + 本地 FastAPI 跑通，不碰 Oracle/DNS。

任务：

- 创建 Flutter repo、FastAPI backend。
- 后端 `/health`。
- App 调用**本地** backend health（`http://10.0.2.2:8000`）。

验收：

- Android emulator 能打开 App。
- App 能拿到本地 `/health` 的 ok。

### Phase 0B — Oracle 部署

目标：把 backend 部署到 Oracle VM，HTTPS 通。

任务：

- Dockerfile / docker-compose（含 PostgreSQL 容器）。
- 配置 Oracle VM 子域名 + 安全组放行 80/443。
- Caddy 反代 + 自动 HTTPS。

验收：

- `https://api-reply.novaaistudio.ca/health` 返回 ok。

> 拆分理由：DNS / Caddy / Oracle 防火墙容易卡住，不该和写代码挤在同一步。先本地跑通逻辑，再单独啃部署。

### Phase 1 — 静态 UI

目标：先完成界面，不接 AI。

任务：

- Reply 页面。
- Polish 页面。
- Settings 页面（不含主题切换项）。
- Paywall 静态页面。
- **淡蓝色玻璃拟态主题（单一，§19）：AppSkin 固定 token + BackdropFilter**。
- 使用 fake data 展示结果。

验收：

- App 可完整点击所有主要入口。
- UI 能表达 Reply / Polish 两个核心模式。
- 淡蓝色玻璃拟态视觉成型，结果卡片清晰可读（不被玻璃糊掉）。

### Phase 2A — 匿名鉴权

目标：token 体系立起来，后续 /me、usage、sync 都依赖它。这是全项目最易出隐藏 bug 的部分。

任务：

- 后端 `/v1/auth/anonymous` + `/v1/auth/refresh` + JWT 中间件（payload 含 jti、device_hash+pepper）。
- Flutter `features/auth/`：appUserId 生成（`uuid.v4`）、token_storage（secure storage）。
- 单一 `AuthService`（Riverpod）独占 token 生命周期；状态机：unauthenticated | authenticating | authenticated | refreshing | token_expired | error。
- 全局 dio interceptor：401 单飞 refresh + 请求入队重放；refresh 失败走 anonymous（指数退避，最多 3 次）。

验收：

- App 启动自动取得 token 并持久化；重启后仍同一 user。
- access 过期自动 refresh；refresh 失败能重新 anonymous，不卡死、不无限循环。
- 无 token / 伪造 token 被拒（401）。
- 测试：token 中途过期、refresh 期间断网、并发 401 都能正确处理（§13.2）。

### Phase 2B — 本地交互

目标：完成不依赖 AI 的本地体验。

任务：

- deviceId 生成保存、app settings 保存。
- 语音输入到 guidance（含 Auto Detect 语言，§4.5）、手动粘贴按钮、copy 结果。
- **Guidance Library**：guidance 输入框上方常用语 chips，点击填入（§4.2）。
- usage badge UI（先用 fake data）。

验收：

- 用户可以粘贴、语音输入、复制。
- **语音真机验收**：至少中文 + English 在真机识别可用；某语言/某机型语音不可用时，语音按钮优雅回退到打字并给提示，**不能点了没反应**。
- Guidance Library chips 点击能正确填入/追加到 guidance。
- badge 能展示剩余次数样式。

### Phase 3 — 后端 AI 闭环

目标：Reply / Polish / Explain 真正生成结果（鉴权已在 Phase 2 就绪）。

任务：

- `/v1/reply`
- `/v1/polish`
- `/v1/explain`（四段：meaning/tone/hiddenMeaning/suggestedReplies，§6.6）+ Reply 页 Explain 按钮 + Bottom Sheet（§4.2）
- AI service / model router（explain 走低成本档，§8.4）
- Prompt + prompt 缓存（§8.5）
- JSON parse（含重试，§8.3）
- 输入校验（§6.7）+ 错误码（§6.8）

验收：

- App 调后端生成 reply / polish（请求带 Bearer）。
- Explain 在 Reply 页以 Bottom Sheet 展示四段，suggestedReplies 可"采用"填入 guidance。
- 超长/空输入被正确拦截。
- explain 每日 10 次限频（落库计数）生效。
- 模型 key 不在客户端。

### Phase 4 — 免费 5 次用量控制

目标：后端限制 free usage。

任务：

- users 表。
- usage_summary 表（含 `paid_credits` 列）。
- idempotency_keys 表（或 Redis）。
- usage_events 表（含 `source` / `prompt_version` 字段 + `(user_id,endpoint,created_at)` 索引，§7.1）。
- `/v1/me`（返回 freeUsesLeft + paidCredits）。
- 生成成功后**原子扣次数**（§3.6：先扣免费、用尽再扣 credit）。
- **幂等键**处理：重复请求不重复扣费。
- 模型失败**按来源回滚预扣**（free 还 free、credit 还 credit）。
- **幂等记录过期清理**：按 `expires_at` 回收 `idempotency_keys`（简单 cron 或启动时清理，避免表无限增长，§3.6/§7.1）。
- 免费+credit 都为 0 时 blocked。
- Flutter entitlement controller。

验收：

- 新用户 5 次免费。
- 免费用尽且无 credit 时显示 paywall。
- 模型失败不扣次数（回滚生效，且还回正确的池）。
- 并发两次生成不超额。
- 同幂等键重复请求只扣一次。
- **`free_uses_used` 据实累计验证**：用 2 次（剩 3）→ 模拟切 premium → premium 期间不改计数 → 模拟掉回 free → `/v1/me` 仍返回剩 3 次（不清零、不消失）（§3.1）。
- **request_hash 一致性**：传 `null` 字段 vs 不传该字段，命中同一幂等记录（不误报 409）。
- **并发压测（本 Phase 结束必做）**：Locust 模拟 ≥10 用户同时 generate + 重试，验证扣减不超额、连接池不被打满、无 `database is locked`/连接耗尽。

### Phase 5A — RevenueCat 订阅

目标：premium 订阅解锁 + 3 天免费试用。**先把订阅基础闭环跑通，不被 credit 问题阻塞。**

任务：

- Google Play subscription（`reply_premium_monthly`）+ base plan 配 3 天 free trial。
- RevenueCat project：entitlement `premium` + offering 含订阅 package。
- Flutter purchases_flutter：paywall 订阅路径，主 CTA "Start 3-day Free Trial"。
- 订阅 purchase / restore → `/v1/entitlement/sync`。
- 后端 RevenueCat verification + subscription_cache。

验收：

- 测试购买订阅后 premium active、不被额度限制。
- **3 天免费试用：首次订阅进入试用、试用期内 isPremium 为 true 可无限用；试用期内取消 → 到期后 sync 回 free。**
- **订阅过期免费额度恢复**：订阅前用过的免费次数，在订阅过期掉回 free 后按 `limit-used` 原样恢复，不清零（§3.1）。
- restore 正常。
- paywall 试用文案明确（3 天免费、之后按月收费、可取消）。

> **Phase 5A 前置（模型质量门槛）**：准备一组 ≥20 组真实中/英场景的评测集，确认 premium 档模型在"按 guidance 生成地道英文"上达标后再定 premium 模型（§8.4）。地道英文是产品生命线，不可只为省成本选弱模型。

### Phase 5B — Credit 包

目标：一次性 credit 包购买 + 防丢单对账。依赖 Phase 4 的 entitlement/扣减与 5A 的 RevenueCat 接入。

任务：

- 三个 consumable 内购（`credits_10/50/100`）+ RevenueCat offering 含三个 credit package。
- Flutter paywall 增加 credit 路径，并列 "Buy Credits"（§3.4）。
- credit purchase → `/v1/credits/sync`（后端凭交易校验、按 transaction_id 幂等入账）。
- **credit 自动对账**：购买成功后 + App 每次启动 + 每次打开 paywall 都调 `/v1/credits/sync`（防丢单，§3.4）。
- `credit_purchases` 表 + 后端 RevenueCat verification。

验收：

- 测试购买 credit 包后 `paidCredits` 增加；重复 sync 不重复入账（幂等）。
- **试用期不消耗 credit**：试用期内若用户已有 paidCredits，生成不扣 credit；试用到期掉回 free 后，原 paidCredits 完好（§3.3）。
- **试用期买 credit 照入账**：premium/试用期间购买 credit 包，`/v1/credits/sync` 仍正常入账 `paid_credits`（只是当下不消耗），掉回 free 后可用（§3.3）。
- **丢单恢复**：购买后立即杀进程不调 sync，重新打开 App 后自动对账补回 credit。
- 免费用尽后能用 credit 继续生成；credit 也用尽才 blocked。

### Phase 6 — Internal Testing Release

目标：提交 Google Play internal testing。

任务：

- App icon。
- Splash screen。
- Store listing。
- Privacy policy。
- Data safety。
- Release AAB。
- Internal testing testers。
- 端到端购买测试。

验收：

- Google Play internal testing 可安装。
- 测试订阅流程通过。
- free 5 次和 premium 解锁通过。

### Phase 7 — MVP 上线前打磨

任务：

- 错误文案优化。
- 延迟 loading 状态。
- 生成结果 copy rate 事件。
- 成本统计。
- prompt 质量样本测试。
- Crash / error logging。

验收：

- 主要流程稳定。
- 无明显审核风险。
- 可以进入 closed testing 或 production。

---

## 15. 与 Rental Expense Keeper 的复用点

可以直接复用或参考：

| Rental Expense Keeper | ReplyWise 对应 |
|---|---|
| Flutter + Riverpod + go_router | 同样架构 |
| RevenueCat entitlement repository | premium entitlement |
| Paywall 购买 / restore 流程 | 直接改文案和产品 ID |
| free scan counter | free AI uses counter，limit=5 |
| FastAPI backend | reply backend |
| Oracle VM + Docker + Caddy | 同样部署方式 |
| dart-define backend URL | REPLY_BACKEND_BASE_URL |
| Google Play internal testing | 同样发布流程 |
| 后端不保存图片/敏感内容 | 后端不保存消息正文 |

注意区别：

- Rental Expense Keeper 的免费额度是 scan usage；ReplyWise 是 AI generation usage。
- Rental Expense Keeper 有本地 expense DB；ReplyWise MVP 不需要复杂本地 DB。
- ReplyWise 更强调剪贴板、语音、copy flow。
- ReplyWise 更需要控制模型输出质量和延迟。

---

## 16. 最小可交付版本定义

MVP 完成标准：

- Android Flutter App 可安装。
- Reply 模式可生成 3 个英文回复。
- Polish 模式可润色英文。
- 支持语音输入指导。
- 支持复制结果。
- 免费用户 lifetime 5 次。
- 免费用完后 paywall。
- **支持购买 10 / 50 / 100 次 credit 包（consumable）。**
- **免费用完后可用已购 paid credits 继续生成。**
- RevenueCat 测试购买后 premium 解锁。
- 后端部署在 Oracle Free VM。
- 模型 API key 只在后端。
- Google Play internal testing 可用。

---

## 17. 推荐开发顺序

建议不要一开始做太多 UI 风格和高级功能。

最稳顺序（与 §14 Phase 划分一致）：

1. **Phase 0A**：Flutter skeleton + 本地 FastAPI `/health` 联通
2. **Phase 0B**：Oracle VM 部署（Docker + Caddy + **PostgreSQL 容器** + `api-reply` 子域名 HTTPS）——尽早把部署啃下来，prod 一开始就用 PostgreSQL
3. **Phase 2A**：匿名鉴权（`/v1/auth/anonymous` + `/v1/auth/refresh` + JWT 中间件 + token 存储 + dio 401 拦截）——**必须在任何业务接口之前**
4. **Phase 1**：静态 UI（Reply/Polish/Paywall/Settings + 淡蓝玻璃，fake data）——可与 2A 并行
5. **Phase 2B**：本地交互（语音 + Guidance Library + 粘贴 + copy）
6. **Phase 3**：AI 闭环（`/v1/reply`、`/v1/polish`、`/v1/explain`，先不接扣费）
7. **Phase 4**：免费 5 次 + credit + 幂等（原子预扣 + 回滚 + 并发压测）
8. **Phase 5A**：RevenueCat 订阅 + 3 天试用 + premium 解锁
9. **Phase 5B**：credit 包 + `/v1/credits/sync` + 防丢单对账
10. **Phase 6**：Google Play internal testing release
11. **Phase 7**：UI 美化和上线前打磨

先跑通闭环，再美化。不要先做悬浮球。鉴权要在调后端业务接口之前就位（§14 Phase 2A）。详细任务与验收见 §14。

---

## 18. 二期 / 上线后事项

三轮 review 提出了一批正确但不必塞进首版的建议。集中归档于此，明确"知道要做、但不阻塞 MVP"，避免首版无限膨胀：

| 事项 | 说明 | 时机 |
|---|---|---|
| RevenueCat Webhook | `/v1/webhooks/revenuecat` 处理取消/过期/续费/退款/账单问题，让订阅状态及时更新而不依赖用户主动 sync。**有 3 天试用后更重要**：试用到期/取消是异步事件，无 webhook 时需等用户下次开 App sync 才纠正 | 上线后尽快 |
| Refresh token rotation + 黑名单 | 防 refresh token 泄漏被长期使用；MVP 先用固定 refresh + jti 失效 | 二期 |
| 内容审核（moderation） | MVP 仅轻量 gate（§6.7）；完整审核接入专门服务 | 二期 |
| 可观测性 /metrics | Prometheus 指标、结构化日志 + log drain、自动重启脚本 | 上线后 |
| Caddy rate_limit | 在反代层加限频，补充应用层限频 | 上线后 |
| is_blocked 自动化封禁流程 | 字段已留（§7.1），自动检测与处置流程后做 | 二期 |
| OpenAPI / Postman | 接口规范补充文档，便于协作与回归 | 并行可做 |
| 高消耗用户策略 | 基于 usage_events token 统计做降级/提示 | 上线后看数据 |
| 历史记录、悬浮球、iOS 键盘 | 已在产品文档列为后续 | 二期及以后 |
| Alembic 数据库迁移 | 从 day-1 用更好，但 MVP 可先建表脚本；上线前补 | 上线前 |
| pg_dump 定时备份 | 计费数据应有备份，MVP 可简单 cron | 上线前 |
| Sentry / 结构化日志 + 看板 | 错误与成本可观测；MVP 先 Python logging | 上线后尽快 |
| Redis 滑动窗口限频 | MVP 用 DB 计数；多实例/高并发后迁 Redis（不使用内存计数） | 多实例时 |
| 连接池调优 / 部分唯一索引 | asyncpg pool size、`(key,request_hash) where status!='failed'` 索引 | 量上来后 |
| property-based / 负载测试 | 幂等与扣减的属性测试、Locust 压测 | 并行可做 |
| OpenAPI(API.md) / DECISIONS.md | FastAPI 自动 OpenAPI + 决策记录 | 并行可做 |
| prompt 版本号入 usage_events | 便于 A/B 与回归 | 并行可做 |
| 深色模式 / 扁平主题 / 其他配色 / 主题切换 | 第一版只做淡蓝玻璃（§19）；多套皮肤与切换后做 | 二期 |

> 原则：MVP 只做"安全和计费正确性"必需的部分（鉴权、原子幂等扣费、premium 校验、基本限频与输入校验），其余增强在有真实用户和数据后再排期。

---

## 19. 界面设计与视觉风格

### 19.1 设计方向

第一版只做**一套淡蓝色苹果玻璃拟态（Light Blue Liquid Glass）**——以淡蓝为主色调的半透明磨砂面板、柔和的淡蓝渐变背景透过模糊层、细高光描边。它与"母语→地道英文"这类轻盈、现代、偏国际化的工具气质契合，淡蓝也传达清爽、可信、专业的观感，且与 iOS 原生玻璃一致，利于后续上 iOS。

第一版**不做主题切换、不做深色模式、不做扁平主题**——只有这一套淡蓝玻璃。多主题、深色、其他配色归 §18 二期，避免首版做多套皮肤拖慢进度。

### 19.2 淡蓝玻璃拟态的关键视觉要素

- **背景层**：淡蓝单色调渐变（在浅蓝之间过渡，如 `#DCE9FF → #EAF1FF → #F2F7FF`，明度高、饱和度低，整体通透发亮），上方可有 1–2 个更淡的蓝色模糊光斑增加层次，不要引入其他色相。
- **面板层**：`backdrop-filter: blur(18–22px) saturate(160%)` + 半透明白带极轻蓝调 `rgba(255,255,255,0.20)`，`1px` 高光描边 `rgba(255,255,255,0.45)`，圆角 16–18px。
- **强调色（accent）**：统一用一个蓝色，如 `#3B82F6` / `#4F8DF7`，用于主按钮、激活态、可点元素，保持与淡蓝主题协调。
- **层级**：输入区用更低透明度的玻璃；结果卡片用接近不透明的白（如 `rgba(255,255,255,0.94)`），保证可读性——生成的英文是核心内容，不能被玻璃糊掉。
- **输入框可读性（v3.2 必做）**：guidance / 对方消息等主输入框因背景渐变多变，文本 `#1E293B` 在某些浅蓝处可能达不到 WCAG 4.5:1。措施：(a) 输入框玻璃面板垫一层极淡固体底色，或 (b) **输入框获得焦点时把面板白调 opacity 从 0.20 动态提升到 0.45**，确保户外强光下打字不费眼。真机强光下实测对比度。
- **文字对比**：淡蓝玻璃面板上用深色文字（深蓝灰，如 `#1E293B`），必须保证 WCAG 对比度；背景较亮处的文字（如顶部 header 上的白字）必要时加极轻的半透明衬底或描边，确保可读。

### 19.3 Flutter 实现要点

- 用一组固定的淡蓝玻璃 token（颜色、模糊半径、透明度、描边、圆角、accent）集中定义在 `theme/app_skin.dart`，组件统一引用，**不在组件里写死颜色**。第一版只有一套值，无需做成可切换的多实例。
  ```dart
  @immutable
  class AppSkin {
    final List<Color> bgGradient;     // 淡蓝背景渐变
    final Color panelColor;           // 面板底色（半透明白带蓝调）
    final double panelBlur;           // 模糊半径
    final Color panelBorder;          // 高光描边
    final Color resultCardColor;      // 结果卡片底色（高不透明白）
    final Color textPrimary;          // 深蓝灰正文
    final Color textSecondary;
    final Color accent;               // 蓝色强调
    const AppSkin._();
    static const light = AppSkin._(/* 淡蓝玻璃一套固定值 */);
  }
  ```
- 玻璃效果用 `BackdropFilter(filter: ImageFilter.blur(...))` 包一个半透明 `Container`。
- 组件（卡片、输入框、按钮、usage badge、paywall）统一从 `AppSkin.light` 取样式。
- 因为只有一套主题，无需 `themeProvider`、无需持久化主题选择、无需深色适配逻辑。

### 19.4 性能与可访问性

- `BackdropFilter` 在低端 Android 上有性能开销。措施：限制同屏玻璃层数量（背景 + 面板 + 结果卡片即可，不要层层叠玻璃）；列表滚动区避免大面积实时模糊。
- 尊重系统"减少透明度/动效"无障碍设置：检测到时减弱或去除模糊（直接用半透明纯色面板兜底），并减弱动画。
- 设置页**不含主题切换项**——第一版 Settings 为：App language / Voice input language / Auto paste / Subscription status / Restore purchases / Privacy / Terms / Contact（与产品文档 §5.4 对齐，去掉 App theme 项）。其中 **App language** 同时决定界面语言与解释/Explain 输出语言（§4.5）；**Voice input language** 是语音识别默认 locale（默认 Auto Detect）；**没有"guidance 打字语言"项**——文字 guidance 语种由后端自动识别（§4.5）。

> MVP 范围：仅一套淡蓝色玻璃拟态。深色模式、其他配色、扁平主题、主题切换、跟随系统自动深浅、按时段变背景渐变等，全部归 §18 二期。

---

## 20. Future-proofing：账号、云同步、多 App 后端

> 原则：MVP **不做** email 登录、云同步、历史记录，但从 day-1 在**数据结构与命名上预留**，避免日后改造伤筋动骨。关键红线——**绝不能因为预留结构而把 MVP 变复杂**。本节都是"结构预留、逻辑不启用"。

### 20.1 预留 Email / 第三方登录（anonymous → account linking）

当前是匿名 `appUserId + JWT`。未来扩展路径：

```text
Anonymous User
      ↓
Email Login / Google Sign-In
      ↓
Link anonymous user to account（不新建空账号）
      ↓
保留已有 free usage / credits / subscription
```

- `users` 表已预留 `email / auth_provider / provider_user_id / account_status` 字段（见 §7.1），MVP 恒为 null / 'anonymous'。
- **关键红线**：未来登录必须是"把当前匿名 user 升级为 email account"（在原 user 行上补 email/provider），**绝不能登录后新建一个空账号**，否则用户的 credit / 订阅 / 免费余额全丢。
- 因为 usage / credits / subscription 全部绑定 `user_id`（不绑 device），account linking 时数据天然跟随 user_id，无需迁移。
- 二期实现：新增 `/v1/auth/link`（在已登录匿名 token 的前提下绑定 email/Google），后端把 provider 信息写入当前 user 行、`account_status='linked'`。

### 20.2 预留云同步与历史记录

MVP 默认**不保存正文**（见 §7.2）。但结构上预留一张历史表，便于未来开"云端历史"：

```sql
-- 预留，MVP 不创建/不写入；二期启用
CREATE TABLE reply_history (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL,
  type          TEXT NOT NULL,      -- reply | polish | explain
  source_text   TEXT,              -- 对方消息 / 草稿（仅在用户开启云历史时才存）
  guidance_text TEXT,
  result_json   TEXT,
  is_synced     INTEGER NOT NULL DEFAULT 0,
  is_deleted    INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);
```

启用时的约束：
- MVP 默认**不启用**，不创建该表也可（或建表但不写入）。
- 二期在 Settings 增加开关 `Save history to cloud`（默认关）。
- 开启云历史必须在 Privacy Policy 明确说明存什么、存多久。
- 用户可 `Delete history`（软删 `is_deleted` + 后端硬删）。

> 现在文档只需声明：**MVP 不保存消息正文；但数据库与 API 命名保留 future cloud sync / history 结构**。

### 20.3 多 App 后端隔离（Oracle VM 已跑多个 App）

Oracle VM 上已有多个 App，ReplyWise 必须**独立部署、互不干扰**：

```text
api-hairtrack.novaaistudio.ca → 127.0.0.1:8000
api-rental.novaaistudio.ca    → 127.0.0.1:8001
api-welcome.novaaistudio.ca   → 127.0.0.1:8002
api-reply.novaaistudio.ca     → 127.0.0.1:8003   ← ReplyWise
```

每个 App 独立拥有：

- 独立 Docker service（独立容器）
- **独立 PostgreSQL database/容器**（计费数据不混库）
- 独立 `.env`
- 独立 RevenueCat key / product
- 独立 Caddy site block
- **不共享模型 usage 表**（除非未来真做统一平台）

建议目录布局：

```text
/opt/apps/
  hairtrack/
  rental/
  welcome/
  replywise/
      backend/
      docker-compose.yml
      .env
      pgdata/
```

> 隔离的好处：一个 App 的部署/故障/数据问题不波及其他；RevenueCat、模型 key、限频阈值各自独立；未来要把某个 App 迁走或卖掉也干净。

### 20.4 一句话总结（写给执行者）

```text
MVP 不做 email login、cloud sync、history，但从 day-1 预留：
1. users 表支持未来 email/provider 字段（已加）
2. anonymous user 可升级为 email account（不新建空账号）
3. usage / credits / subscription 绑定 user_id，不绑定 device
4. history 表暂不启用
5. 后端按 app 独立部署（独立 DB / .env / RevenueCat / Caddy block）
```

---

## 21. 决策记录（Decision Log）

集中记录关键产品/技术取舍的理由，便于后期 review 时理解"为什么当初这么定"，避免反复讨论已决事项。

| 决策 | 选择 | 理由 | 重审条件 |
|---|---|---|---|
| 免费额度 | lifetime 5 次（非每日） | 本产品使用频率高，每日免费会失控；lifetime 5 次足够体验、获客成本可控 | 看 §9 转化数据 |
| regenerate 扣费 | 照扣 1 次 | 实现简单、防滥用；先上线观察真实试错率再定是否优化 | 耗尽用户转化率偏低时 |
| outputLang | MVP 固定 `en` | 产品定位"回出地道英文"；做语言检测/可选只增复杂度，无验证价值 | 用户明确需要多语言输出 |
| 数据库 | prod 直接 PostgreSQL | 计费数据并发正确性不容妥协；SQLite 多 worker 写易锁 | —（不重审） |
| 鉴权 | 匿名 JWT（不强制登录） | 降低首次使用门槛；email 登录结构已预留（§20） | 需要跨设备/账号体系时 |
| Explain | 融入 Reply（非独立功能） | 它是"先读懂再回"的辅助步骤，独立成页割裂心智 | —（不重审） |
| guidance 命名 | 统一用 guidance（非 instruction） | 是产品核心卖点，"AI follows your guidance" 比 instruction 自然 | —（不重审） |
| 主题 | 仅单一淡蓝玻璃 | 首版聚焦核心闭环，多主题/深色拖慢进度 | MVP 验证通过后 |
| 悬浮球 | 第一版不做 | 先验证"复制→母语指导→复制回"核心闭环；悬浮球是体验增强非验证项 | 核心闭环验证成功后 |
| request_hash | 仅后端计算 | 前后端序列化差异（浮点/布尔/空格）易致 hash 不一致、误报 409 | —（不重审） |
| 限频 | MVP 用 DB 计数 | 内存计数重启清零；DB 计数正确性优先，并发量小可接受稍慢 | 多实例/高并发时迁 Redis |
| explain 幂等 | 第一版不强制幂等键 | 不扣费、无预扣回滚，无需幂等复杂度 | explain 改计费时 |
| account linking 冲突 | MVP 不处理 | 未来 email 登录时，若该 email 已绑定另一 user_id（如用户在设备 A 匿名买了 credit、又登录设备 B 的老账号），属"两 user 合并"，需后端合并/转移 credit 池策略；MVP 暂不支持此复杂度 | 做 email 登录时 |

> 维护约定：每次推翻或新增一条上面的决策，在此表追加/修改一行并注明日期，保持文档与现实一致。
