

> 来源：FlClash（Flutter + Go ClashMeta 代理客户端）鸿蒙移植实战，真机 Huawei Mate 80 Pro（HDC `5JV0225B14001088`，OpenHarmony-6.1.1.120，model SGT-AL00）。
> 记录的是移植过程中踩到的难题和解决方案。

---

## 1. VPN 扩展（VpnExtensionAbility）开发要点 —— 移植最难的部分

### 1.1 架构：VPN 跑在**独立进程**里
- `type: "vpn"` 的 ExtensionAbility 是**系统托管的单例**，运行在 `<bundle>:vpn` 独立进程，和主 App 进程内存不共享。
- 后果：主 App 的 UI 和真正在转发流量的 core **不在一个进程**，必须用**进程间通道**打通（见 1.4）。

### 1.2 TUN 的 TCP 数据路径会「静默失效」（本项目最硬的坑）
- 现象：VPN 起来了、`vpn-tun` 有流量、UDP/DNS 正常，但**所有 TCP（网页）全部超时**，`curl -x 127.0.0.1:<port>` 回环却完全正常 → 说明 core/节点/DNS 都没问题，**只有 TUN→代理的数据路径是死的**。
- 根因：mihomo 默认 `mixed` 栈里 **UDP 走 gVisor（用户态注入），但 TCP 走 System NAT** —— NAT 把 SYN 改写成 `tunAddr:port` 再写回，**依赖内核把包环回到本地 TCP listener**。这个内核环回**在 OHOS VpnExtension 里不发生**，于是每个 TCP SYN 被静默丢弃。
- **修复（两步都必需）**：
  1. 在 OHOS 构建强制 `TunGvisor` 栈，让 TCP 也全程在用户态处理（不依赖内核环回）。
  2. gVisor 的 `fdbased.New()` 会对 tun fd 调 `unix.Fstat` 判断是不是 socket，**OHOS 沙箱拒绝对 VPN tun fd 做 Fstat**（permission denied）导致栈起不来 → 打补丁：Fstat 失败时当作非 socket（走 readv 分发）。
- **可迁移教训**：在鸿蒙 VpnExtension 里，凡是「依赖内核 loopback / 对特殊 fd 做 Fstat」的三方网络栈代码，都要预期失效，优先选**纯用户态**路径。

### 1.3 `isInternal` 与 DNS 传播
- 用 `isInternal: true` 建 VPN，**netsys 不会把 VPN 的 DNS 下发给应用**（出现 `network_for_dns -1` / `dns server is empty`），应用 DNS 还走原网络。
- 设成 `isInternal: false`（VPN 作为真实网络），系统连通性检查才通过、DNS 才下发。
- 华为浏览器用 **HTTPDNS（DoH 到 `*.dbankcloud.cn`）**，不吃 `dns-hijack 0.0.0.0:53`；要把这些 HTTPDNS 的 CIDR 配成**本地直连**，否则请求会在隧道里卡 10s 超时。
- **fake-ip-filter 是双刃剑**：被列进 filter 的域名会走**真实 DNS**；在被污染的网络里，这等于把域名推回 GFW 污染路径（YouTube→Facebook IP）。想让某域名走代理，就**别**把它放进 fake-ip-filter，让它拿 fake-ip 按域名路由。

### 1.4 进程间「UI ↔ 运行中 core」live link
- 关键弄清谁是 client/server：FlClash 里 **Go core 是 socket client（主动 dial），Dart 侧是 server（bind unix socket）**。
- VPN 进程里的 core 起来后，要**显式让它 dial 主 App 监听的 socket**，UI 才能拿到实时状态/流量/连接列表/切换节点生效。否则 UI 永远卡「连接中」、速度/流量读 0。
- 做法：把主 App 的 unix socket 路径一路透传（Dart → MethodChannel → ArkTS want 参数 → VpnAbility → NAPI bridge），bridge 里 `dlopen` **同一个** libclash.so 跑 `dial(socketPath)`。

### 1.5 状态机：非正常退出留下的 stale 状态
- VPN 扩展被**非正常杀死**（进程死亡 / force-stop）时来不及写「已停止」状态，会残留 `started`。
- 后果：主 App 以为 VPN 还开着 → `startVpn` 短路、`stopVpn` 永远等不到 stopped → **重启永久卡死**。
- **修复思路**：`type:"vpn"` 是系统单例，「发了 stop 请求 + 超时后状态仍是 started」就等价于「扩展已消失」→ 此时**主动 reconcile 成 stopped**（重置状态文件 + 上报成功），下次 start 就不再被挡。

---

## 2. Go / native（NAPI C++ bridge）集成坑

- **TLS 模型**：给鸿蒙编 `.so`（CGO）时，musl 加载器**拒绝 `initial-exec` 动态 TLS 解析**，必须让编译产物用 `R_AARCH64_TLSDESC` 模型 —— FlClash 为此准备了一条**打过补丁的独立 Go 工具链**（`go-nonglibc`）。否则 `.so` 一 load 就失败。
- **NAPI bridge 生命周期坑**：非阻塞「detached 启动」子进程/线程后，**不要**在启动线程里立刻 `dlclose` handle 或清掉跟踪状态 —— 那会把刚启动、还在后台运行的东西的追踪状态一并抹掉。
- **core 调用要离开主线程**：把 native core 的同步调用放到主线程会卡 UI（真机上表现为界面冻结）。
- 沙箱里 core 的落盘日志走 `.../files/`，是唯一能读到库内行为的通道。例如 `flclash-*.log`、数据库文件、VPN 状态文件都在这。

---

## 3. ArkTS / hvigor 构建（FlClash 特定坑）

- **插件注册漂移**：`GeneratedPluginRegistrant.ets` 会被工具重新生成，容易把手改的自定义注册**覆盖掉**；纯 HAR（预编译）插件如果没有 source module 会导致 OhmUrl 解析失败。本项目用 node 回归测试 `test/ohos/*.test.mjs` 钉住这些源码模式，防止再次漂移。
- 分析/测试门禁：`flutter analyze --no-fatal-infos`、`flutter test`、以及 `node --test test/ohos/*.test.mjs`（OHOS 脚本的源码模式回归测试，**不是** flutter test）。

---

## 4. 真机验证方法论

### 4.1 没有真实订阅也能测 VPN
设备常常没有 profile（`profiles` 表空、`currentProfileId:null`），这会让所有代理检查失败、core 卡「连接中」。用开发 Mac 上现成的代理当上游节点：
1. `hdc rport tcp:1088 tcp:7890`（设备 1088 → Mac 7890）+ `hdc fport tcp:17890 tcp:7890`（从 Mac 测设备 7890）。
2. `python3 -m http.server` 托一份 Clash 配置（节点 `{type: http, server: 127.0.0.1, port: 1088}`，`rules:[MATCH,PROXY]`），再 `hdc rport` 映射进设备。
3. App 内导入该 URL → 起 VPN → 系统弹「允许」授权（真机有 `com.huawei.hmos.vpndialog`，**模拟器镜像通常没有这个包**，所以模拟器上 VPN 授权流程走不通，只能关掉 VPN 验证其余功能）。
4. 确认：`ifconfig vpn-tun` 有 `inet addr`；端口转发后 `curl -x 127.0.0.1:17890 https://www.youtube.com` → 200；用 `vpn-tun` RX 字节增长证明应用流量真的过了 VPN。
   - 注意：FlClash 自己 dashboard 的 checkIp 按设计**排除自身**流量，显示国内直连 IP 是正常的，不代表路由失败。

### 4.2 deep-link 测试的**陷阱**（别被误导）
- `scheme://install-config?url=...` 这类**带确认弹窗**的 deep link，**只 `aa start -U` 触发是不会导入的** —— 导入回调被 `if (确认 != true) return` 挡住。自动化脚本如果不点弹窗，会**误判成「link 没被消费 / 功能坏了」**。
- 正确验证：fire → 等 UI 起来（postFrame 才注册 listener，需要 ~10s）→ dumpLayout 找到「确定」按钮坐标 → 点击 → **再等落库**（FlClash `validateConfig` 有 10s 超时，太早查 DB 会漏掉刚建的记录）。
- 教训：**「日志里没看到 = 功能坏了」是错的**，尤其当你为了清理刚把相关日志删了的时候。要用**最终可观测状态**（DB 行数、tun 字节、截屏弹窗）来判定，不要只看日志缺失。

---

## 5. 其它真机 gotcha

- **X（Twitter）在纯 TCP 上游下内容加载失败**：X 用 QUIC（UDP 443），HTTP 代理扛不了。临时加规则 `AND,((NETWORK,udp),(DST-PORT,443)),REJECT` 逼它回落 TCP → 正常。真正 UDP-capable 的节点不需要这条。
- 中国 4G 的 DNS 对 YouTube 被污染（`www.youtube.com → 31.13.92.37` 是 Facebook IP），所以**唯一**能通的路径就是强制走代理解析（fake-ip / hijack）。
- start FAB（启动按钮）只在**仪表盘**页存在；顶部「连接中」只是状态标签，不是按钮 —— 自动化要先导航到仪表盘。
- 内置浏览器：`aa start -a MainAbility -b com.huawei.hmos.browser -U <url>`；Chrome（安卓兼容层）：`aa start -a com.google.android.apps.chrome.Main -b com.android.chrome -U <url>`。

---

## 6. 一句话速查表

- VPN 是独立进程，UI 要 live 数据必须打通 socket 通道。
- TUN 里 TCP 不通但 UDP 通 → 十有八九是 System NAT 内核环回失效，强制 gVisor 用户态栈。
- 三方网络栈对 tun fd `Fstat` 失败要容错。
- Go `.so` 用 `R_AARCH64_TLSDESC` TLS 模型，否则 musl 加载失败。
- `isInternal:false` 才会下发 VPN DNS。
- 想走代理的域名别放进 fake-ip-filter。
- 非正常退出留下的 stale `started` 要能 reconcile，否则重启死锁。
- deep-link/带弹窗的功能，用「最终状态」验证，别信「日志没看到」。
- 设备没 profile 时用 Mac 代理当上游节点做测试。
- FlClash 自身流量被 checkIp 排除，显示直连 IP 是正常的。
- 模拟器上 VPN 授权流程走不通（缺少 vpndialog 包），只能关掉 VPN 验证其他功能。
