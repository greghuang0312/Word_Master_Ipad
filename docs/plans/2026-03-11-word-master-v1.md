# Word Master V1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 交付一个可在 iPadOS 使用的英文单词背诵 App（登录、复习、添加、库、统计、我的），并接入 Supabase 与 DeepSeek。

**Architecture:** 采用 SwiftUI + Feature 模块化结构，业务规则（艾宾浩斯调度、状态转移）集中在 Core 层；数据访问通过 Repository 封装 Supabase；候选词通过 DeepSeekClient 获取并支持手写兜底。

**Tech Stack:** SwiftUI, Swift Concurrency, Supabase Swift, URLSession, Keychain, Postgres(RLS)

---

### Task 1: 项目骨架与导航容器

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `swift_swiftui`

**Files:**
- Create: `WordMaster/WordMasterApp.swift`
- Create: `WordMaster/App/AppRouter.swift`
- Create: `WordMaster/App/MainTabView.swift`
- Create: `WordMaster/Features/Auth/LoginView.swift`
- Test: `WordMasterTests/AppRouterTests.swift`

**Step 1: Write the failing test**

```swift
func testUnauthenticatedUserShowsLogin() {
    let router = AppRouter(isAuthenticated: false)
    XCTAssertEqual(router.currentRoute, .login)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/AppRouterTests`  
Expected: FAIL（`AppRouter` 未定义）

**Step 3: Write minimal implementation**

实现 `AppRouter` 的 `currentRoute` 与登录态初始化逻辑；`MainTabView` 放置 5 个 Tab 占位。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/WordMasterApp.swift WordMaster/App WordMaster/Features/Auth/LoginView.swift WordMasterTests/AppRouterTests.swift
git commit -m "feat: scaffold app shell and auth gate"
```

### Task 2: 复习领域模型与艾宾浩斯调度器

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `swift_swiftui`

**Files:**
- Create: `WordMaster/Core/Models/WordItem.swift`
- Create: `WordMaster/Core/Review/ReviewScheduler.swift`
- Test: `WordMasterTests/ReviewSchedulerTests.swift`

**Step 1: Write the failing test**

```swift
func testUnknownResetsToStage1AndTomorrow() {
    let scheduler = ReviewScheduler()
    let result = scheduler.nextState(currentStage: 4, result: .unknown, today: .mock("2026-03-11"))
    XCTAssertEqual(result.stage, 1)
    XCTAssertEqual(result.nextReviewDate, .mock("2026-03-12"))
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/ReviewSchedulerTests`  
Expected: FAIL（`ReviewScheduler` 未定义）

**Step 3: Write minimal implementation**

实现阶段数组 `1/2/4/7/15/30`、`known` 进阶、`unknown` 回退阶段 1 且次日复习。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/Core/Models/WordItem.swift WordMaster/Core/Review/ReviewScheduler.swift WordMasterTests/ReviewSchedulerTests.swift
git commit -m "feat: add review scheduler with forgetting reset rule"
```

### Task 3: Supabase 鉴权与词条仓储

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `supabase-postgres-best-practices`

**Files:**
- Create: `WordMaster/Data/Supabase/SupabaseClientFactory.swift`
- Create: `WordMaster/Data/Auth/AuthRepository.swift`
- Create: `WordMaster/Data/Words/WordRepository.swift`
- Test: `WordMasterTests/WordRepositoryTests.swift`

**Step 1: Write the failing test**

```swift
func testFetchDueWordsUsesLessOrEqualTodayFilter() async throws {
    let repo = MockWordRepository()
    _ = try await repo.fetchDueWords(today: .mock("2026-03-11"))
    XCTAssertEqual(repo.lastFilter, "next_review_date<=2026-03-11")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/WordRepositoryTests`  
Expected: FAIL（仓储接口未实现）

**Step 3: Write minimal implementation**

实现登录/退出、按 `next_review_date <= today` 查询、按 `(user_id,en_word)` 合并更新（upsert）。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/Data WordMasterTests/WordRepositoryTests.swift
git commit -m "feat: implement supabase auth and word repository contracts"
```

### Task 4: 复习页交互闭环

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `swift_swiftui`

**Files:**
- Create: `WordMaster/Features/Review/ReviewViewModel.swift`
- Create: `WordMaster/Features/Review/ReviewView.swift`
- Test: `WordMasterTests/ReviewViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testRevealThenTapMarksUnknown() async {
    let vm = makeReviewVM()
    vm.revealEnglish()
    await vm.tapCard()
    XCTAssertEqual(vm.lastResult, .unknown)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/ReviewViewModelTests`  
Expected: FAIL

**Step 3: Write minimal implementation**

实现“英文翻译”状态位、卡片点击判定、词条切换与队列清空提示。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/Features/Review WordMasterTests/ReviewViewModelTests.swift
git commit -m "feat: implement review card flow and result transitions"
```

### Task 5: 添加页（DeepSeek 候选 + 手写兜底）

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `deepseek`

**Files:**
- Create: `WordMaster/Data/LLM/DeepSeekClient.swift`
- Create: `WordMaster/Features/Add/AddWordViewModel.swift`
- Create: `WordMaster/Features/Add/AddWordView.swift`
- Test: `WordMasterTests/AddWordViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testManualEnglishFallbackWhenNoCandidateSelected() async throws {
    let vm = makeAddVM()
    vm.zhText = "苹果"
    vm.manualEnglish = "apple"
    try await vm.save()
    XCTAssertEqual(vm.savedWord?.enWord, "apple")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/AddWordViewModelTests`  
Expected: FAIL

**Step 3: Write minimal implementation**

实现候选拉取、候选点选、手写兜底、重复英文合并更新提示。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/Data/LLM WordMaster/Features/Add WordMasterTests/AddWordViewModelTests.swift
git commit -m "feat: add deepseek candidate selection and manual fallback"
```

### Task 6: 库页（列表 + 删除 + 阶段展示）

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `supabase-postgres-best-practices`

**Files:**
- Create: `WordMaster/Features/Library/LibraryViewModel.swift`
- Create: `WordMaster/Features/Library/LibraryView.swift`
- Test: `WordMasterTests/LibraryViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testDeleteWordRemovesItemFromList() async throws {
    let vm = makeLibraryVM(seedCount: 2)
    try await vm.deleteWord(at: 0)
    XCTAssertEqual(vm.items.count, 1)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/LibraryViewModelTests`  
Expected: FAIL

**Step 3: Write minimal implementation**

实现词条列表加载、阶段标签显示、删除操作与本地刷新。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/Features/Library WordMasterTests/LibraryViewModelTests.swift
git commit -m "feat: implement library list stage display and delete action"
```

### Task 7: 统计页（指标 + 分布 + 时间轴）

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `swift_swiftui`

**Files:**
- Create: `WordMaster/Features/Stats/StatsCalculator.swift`
- Create: `WordMaster/Features/Stats/StatsView.swift`
- Test: `WordMasterTests/StatsCalculatorTests.swift`

**Step 1: Write the failing test**

```swift
func testOverdueCountOnlyIncludesPastDueItems() {
    let calculator = StatsCalculator()
    let result = calculator.summary(words: mockWords(), today: .mock("2026-03-11"))
    XCTAssertEqual(result.overdue, 2)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/StatsCalculatorTests`  
Expected: FAIL

**Step 3: Write minimal implementation**

实现总量/进行中/逾期/已掌握计算、阶段分布数据与时间轴对照数据。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/Features/Stats WordMasterTests/StatsCalculatorTests.swift
git commit -m "feat: add stats summary distribution and timeline model"
```

### Task 8: 我的页（API Key + 退出）与方向适配

**Required Skills (Method):** `test-driven-development`  
**Required Skills (Stack):** `swift_swiftui`

**Files:**
- Create: `WordMaster/Features/Profile/ProfileViewModel.swift`
- Create: `WordMaster/Features/Profile/ProfileView.swift`
- Create: `WordMaster/Shared/Security/KeychainStore.swift`
- Modify: `WordMaster/App/MainTabView.swift`
- Test: `WordMasterTests/ProfileViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testSaveApiKeyPersistsToKeychain() throws {
    let vm = makeProfileVM()
    try vm.saveApiKey("sk-test")
    XCTAssertEqual(vm.loadApiKey(), "sk-test")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/ProfileViewModelTests`  
Expected: FAIL

**Step 3: Write minimal implementation**

实现 API Key 读写、退出登录；补齐横竖屏布局分支，确保旋转后状态不丢失。

**Step 4: Run test to verify it passes**

Run: 同 Step 2  
Expected: PASS

**Step 5: Commit**

```bash
git add WordMaster/Features/Profile WordMaster/Shared/Security/KeychainStore.swift WordMaster/App/MainTabView.swift WordMasterTests/ProfileViewModelTests.swift
git commit -m "feat: add profile api-key management logout and orientation adaptation"
```

### Task 9: Supabase 部署配置文档

**Required Skills (Method):** `writing-plans`  
**Required Skills (Stack):** `supabase-postgres-best-practices`

**Files:**
- Create: `docs/supabase-setup.md`
- Test: `docs/supabase-setup.md`（人工校对）

**Step 1: Write the failing check**

检查清单初版缺少以下三项即视为 FAIL：RLS 策略、管理员建号流程、环境变量安全边界。

**Step 2: Run check to verify it fails**

Run: 人工对照 `docs/requirements.md`  
Expected: FAIL（初稿不完整）

**Step 3: Write minimal implementation**

补齐 SQL 模板、RLS 策略、Auth 配置、排错清单与上线前核对表。

**Step 4: Run check to verify it passes**

Run: 人工复核  
Expected: PASS(manual)

**Step 5: Commit**

```bash
git add docs/supabase-setup.md
git commit -m "docs: add supabase setup and rls guide for word master"
```

