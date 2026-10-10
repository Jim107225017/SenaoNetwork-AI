# herdr 一鍵安裝 Prompt

讓 agent 幫你完成：在遠端 Linux 伺服器安裝 herdr 與 Claude／Codex integration、herdr skill，在 Windows Terminal 加上「<ALIAS> · herdr」分頁（模式 A），並帶你做驗收與 agent 互傳訊息的 demo。

## 使用方式

1. 在 Windows 筆電上開 Claude Code（desktop app 或終端機）。
2. 把下面整段複製貼上，先把 `<代號>` 換成自己的值（也可以留著，agent 會先問你）。
3. 跟著 agent 的指示完成互動步驟（SSH host key、登入、授權對話框）。

也可以用 [index.html](../index.html) 的「一鍵設定 Prompt」分頁填表產生。

## 代號

| 代號 | 意思 | 範例 |
|---|---|---|
| `<HOST>` | 伺服器 IP 或主機名稱 | `10.x.x.x` |
| `<USER>` | SSH 帳號 | `alice` |
| `<SSH_PORT>` | SSH port | `22` |
| `<KEY>` | 筆電上的私鑰路徑 | `C:\Users\alice\.ssh\id_ed25519` |
| `<ALIAS>` | SSH 別名，也是 Windows Terminal 分頁名稱 | `devbox` |
| `<TEST_REPO>` | 驗收用的 repo（伺服器上的絕對路徑） | `/home/alice/repository/app-api` |

## Prompt

~~~~text
請幫我在這台 Windows 筆電上設定 herdr（https://github.com/herdrdev/herdr，agent 專用的終端機多工器）：herdr 裝在遠端 Linux 伺服器上，我用 Windows Terminal 透過 SSH 連進去執行 herdr（模式 A），在裡面跑 Claude Code 和 Codex，側欄自動顯示每個 agent 的狀態（working / blocked / done / idle），agent 之間也能用 herdr CLI 互相傳訊息。

## 我的環境值
- 伺服器位址 HOST：<HOST>
- SSH 帳號 USER：<USER>
- SSH port：<SSH_PORT>
- 筆電私鑰 KEY：<KEY>
- SSH 別名 ALIAS：<ALIAS>
- 驗收用的 repo（伺服器上的絕對路徑）：<TEST_REPO>
仍是 <…> 形式的值代表我還沒填，請先一次問完再開始。也請一併問我：要不要做模式 B（Windows 原生 herdr），以及要不要裝 herdr skill（讓 Claude 能用 herdr 指揮其他 agent）。預設只做模式 A + skill。

## 規則（一定要遵守）
1. 分階段做，每階段做完就驗證，通過才進下一階段；結果和預期不符時停下來告訴我，不要自己繞路。
2. 不要動伺服器上我現有的 tmux session 或 agent-deck：禁止 tmux kill-server、不要 kill 不是你建立的 session、不要移除 agent-deck。herdr 和它們可以並存。
3. 不要在 herdr 的 pane 裡再跑 tmux。
4. 修改任何既有檔案前先備份成 <檔名>.bak-YYYYMMDD-HHMMSS；加進既有檔案的內容用「# >>> herdr-setup >>>」「# <<< herdr-setup <<<」標記區塊包起來。
5. 需要 sudo 的指令先問我；在 Windows 安裝任何軟體也要先問。
6. 需要互動的步驟交給我：第一次 SSH 的 host key 確認、密碼、claude/codex 登入、herdr 第一次啟動的問題、Codex 的 Hooks 審核與指令授權對話框。
7. 從筆電對伺服器下指令一律用非互動的 ssh <ALIAS> '...'；不要用非互動方式直接執行 herdr（它會開互動畫面）。Windows PowerShell 5.1 會吃掉傳給 ssh.exe 的內層雙引號：遠端指令有巢狀引號時改用 Git Bash，或用 ssh <ALIAS> 'bash -s' 搭配 heredoc。
8. 不要執行 herdr server stop、herdr update，或任何會讓 herdr 伺服器重啟的事，除非我明確同意。
9. 不要修改 repo 的 CLAUDE.md、AGENTS.md，也不要自行修改 ~/.codex/AGENTS.md。
10. 下載的安裝腳本一律先存成檔案、讀過內容（確認會不會呼叫 sudo、改哪些檔案）再執行，不要 curl | sh。

## Phase 0：檢查
- 筆電：ssh -V、wt 是否存在、Windows Terminal settings.json 位置（%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json 或 %LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json）、~/.ssh/config 是否已有指向 <HOST> 的 Host（有就問我要沿用哪個別名）。
- 伺服器：uname -sm（必須是 x86_64 或 aarch64）、OS、bash -lc 'command -v claude codex herdr' 與版本、~/.claude 與 ~/.codex 是否存在（不存在就請我先登入一次）、CLAUDE_CONFIG_DIR / CODEX_HOME 是否有設、tmux ls（只記錄不要動）、~/.claude/settings.json 目前有哪些 hooks 與 statusLine（之後要比對）。

## Phase 1：SSH
若 <ALIAS> 已存在且 ssh -o BatchMode=yes <ALIAS> echo ok 成功就沿用；否則備份 ~/.ssh/config，加入標記區塊：Host <ALIAS>，HostName/User/Port/IdentityFile，加上 ServerAliveInterval 30、ServerAliveCountMax 4。herdr 不需要 LocalForward。

## Phase 2：伺服器安裝 herdr
把 https://herdr.dev/install.sh 下載到伺服器暫存檔，讀過後用 sh 執行（預設裝到 ~/.local/bin，會驗證 SHA-256）。驗證 bash -lc 'herdr --version'。登入 shell 找不到的話，問我要不要在 ~/.profile 用標記區塊把 $HOME/.local/bin 加進 PATH。維持 stable 頻道。

## Phase 3：integration
先備份 ~/.claude/settings.json、~/.codex/config.toml、~/.codex/hooks.json（若有）。執行 herdr integration install claude、herdr integration install codex、herdr integration status（claude 與 codex 應為 current）。
驗證：Claude 設定仍是合法 JSON；用 jq 比對備份，除了 hooks 以外的設定完全沒變；原本的 hooks（包含 agent-deck 的 hook-handler，如果有）與 statusLine 都還在；Codex 的 config.toml 只多了 [features] hooks = true。

## Phase 4：herdr skill（我同意才做）
mkdir -p ~/.claude/skills/herdr && herdr --skill > ~/.claude/skills/herdr/SKILL.md（目錄已存在就先問我）。伺服器沒有 Node 也沒關係，不要用 npx。

## Phase 5：Windows Terminal（模式 A）
備份 settings.json（JSONC，保留註解與既有設定），在 profiles.list 加一個 profile，GUID 用 [guid]::NewGuid() 產生，不要改 defaultProfile：
name「<ALIAS> · herdr」，commandline: ssh -t <ALIAS> "bash -lc herdr"，bellStyle ["window","taskbar"]，tabTitle "herdr"，suppressApplicationTitle true。
驗證：用 PowerShell 解析 JSON 成功；幫我用 wt -w 0 nt -p "{該 GUID}" 開分頁，數秒後在伺服器確認 pgrep -a herdr 有 herdr server，且 ~/.config/herdr/herdr-server.log 出現 client connected。

## Phase 6：模式 B（我同意才做）
先問我。把 https://herdr.dev/install.ps1 下載成檔案讀過，再用 powershell -NoProfile -ExecutionPolicy Bypass -File 執行（只裝在使用者目錄、會改使用者 PATH）。若出現 Access is denied 或被防毒擋下，那是公司安全政策：停下來告訴我，不要繞過，改用模式 A，並告訴我殘留的 %USERPROFILE%\.herdr 可以自行刪除。成功的話請我自己在新的 Windows Terminal 執行 herdr machine add <ALIAS>，並在 %APPDATA%\herdr\config.toml 用標記區塊加入 [ui.toast] delivery = "system"。

## Phase 7：教我用並一起驗收
先用繁體中文簡短教我：工作區／分頁／pane、四種狀態、滑鼠操作、Ctrl+B 前綴快捷鍵（? c v - h j k l z x Shift+N w g b q）。然後逐項請我操作並記錄結果：
1. 在 pane 執行 cd <TEST_REPO> && claude，給小任務，狀態應 working → done → idle。
2. 叫 claude 做需要授權的事，狀態應變 blocked（若顯示 idle 記錄下來，這是已知限制）。
3. 另一個 pane 執行 codex --no-daemon。提醒我：第一次會跳 Hooks 審核（herdr 的 hook），按 t 信任。
4. Ctrl+B 再按 g，點某個 agent 能跳過去。
5. 關掉分頁再重開「<ALIAS> · herdr」，agent 還在。
6. agent 溝通 demo：在 <TEST_REPO> 開一個 agent-demo 工作區（herdr workspace create --cwd <TEST_REPO> --label agent-demo --focus），用 herdr pane split 切出右邊 pane，用 herdr agent start alice --kind claude 與 herdr agent start bob --kind codex -- --no-daemon 各開一個；用 herdr agent prompt alice "用 herdr 傳 hi 給名叫 bob 的 agent，讀它的回覆並告訴我" --wait 讓兩邊互傳，再用 herdr agent read 讀畫面給我看。注意：prompt 一定要提到 herdr，否則 Claude 會改用自己的跨 session 訊息功能；Codex 沙盒擋 herdr CLI 時會停在 blocked 詢問畫面，先用 herdr agent read <名字> --source visible 看清楚，再問我要按 y（只允許這次）還是 p（以後不問），不要自己替我決定 p。Claude 輸入框裡的灰字只是建議輸入，不是我打的。

## 完成後的報告
1. 筆電與伺服器各改了哪些檔案，以及每個檔案的備份路徑。
2. herdr 的版本與安裝位置。
3. 每個 Phase 與驗收項目的結果、錯誤訊息。
4. 日常用法：開「<ALIAS> · herdr」→ 每個 repo 一個工作區 → pane 裡跑 claude 或 codex --no-daemon → 看側欄，Ctrl+B g 跳到要處理的 agent；要 agent 互相溝通時 prompt 裡寫「用 herdr …」。
5. 重開機：herdr 不會隨開機啟動；開「<ALIAS> · herdr」就會啟動並還原版面、接回 Claude/Codex 對話，重開機前正在跑的指令會中斷。
6. 更新：herdr update 前先讓 agent 停在可中斷的地方。移除：herdr server stop（要先問我）、herdr integration uninstall claude / codex、從備份還原 Codex config.toml、刪除 herdr 執行檔與 ~/.claude/skills/herdr、問我要不要刪 ~/.config/herdr、刪 Windows Terminal profile。

~~~~
