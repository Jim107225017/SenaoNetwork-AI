# agent-deck 一鍵設定 Prompt

讓 agent 幫你完成：Windows Terminal 以 SSH 連到遠端 Linux 伺服器、在伺服器上用 agent-deck 管理 Claude Code／Codex 並從瀏覽器監控、VS Code（Remote-SSH + GitLens）只顯示你選的 repo。

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
| `<PORT>` | agent-deck 網頁 port（兩端相同） | `8420` |
| `<REPO_ROOT>` | 伺服器上放 repo 的資料夾（絕對路徑） | `/home/alice/repository` |
| `<REPOS>` | VS Code 要顯示的 repo（相對路徑，逗號分隔；留空讓 agent 列出來選） | `app-api, tools/cli` |

## Prompt

~~~~text
請幫我在這台 Windows 筆電上完成「遠端 Agent 工作台」設定：用 Windows Terminal 透過 SSH 連到遠端 Linux 伺服器，在伺服器上用 agent-deck 管理 Claude Code／Codex 等 agent，並從筆電瀏覽器監控；再設定 VS Code（Remote-SSH + GitLens）開伺服器上的 repo 看 git 狀態。

## 我的環境值
- 伺服器位址 HOST：<HOST>
- SSH 帳號 USER：<USER>
- SSH port：<SSH_PORT>
- 筆電私鑰 KEY：<KEY>
- SSH 別名 ALIAS：<ALIAS>（另一個帶隧道的別名叫 <ALIAS>-deck）
- agent-deck 網頁 port：<PORT>（伺服器只綁 127.0.0.1:<PORT>，筆電透過 SSH 隧道開 http://localhost:<PORT>）
- 伺服器上 repo 根目錄 REPO_ROOT：<REPO_ROOT>
- VS Code 要顯示的 repo：<REPOS>
仍是 <…> 形式的值代表我還沒填，請先一次問完再開始。

## 規則（一定要遵守）
1. 分階段做，每階段做完就驗證，通過才進下一階段；結果和預期不符時停下來告訴我，不要自己繞路。
2. 不要動伺服器上我現有的 tmux session：禁止 tmux kill-server，只能 kill 你自己建立的 session。
3. 修改任何既有檔案前先備份成 <檔名>.bak-YYYYMMDD-HHMMSS；加進既有檔案的內容用「# >>> agent-workflow >>>」「# <<< agent-workflow <<<」標記區塊包起來。
4. 需要 sudo 的指令先問我。不要把 <PORT> 開到 127.0.0.1 以外，不要改防火牆。
5. 需要互動的步驟交給我：第一次 SSH 的 host key 確認、輸入密碼、claude/codex 登入、agent-deck 第一次啟動的遙測詢問。
6. 從筆電對伺服器下指令一律用非互動的 ssh <ALIAS> '...'。注意 Windows PowerShell 5.1 會吃掉傳給 ssh.exe 的內層雙引號：遠端指令有巢狀引號時改用 Git Bash，或用 ssh <ALIAS> 'bash -s' 搭配 heredoc。
7. 不要把 agent-deck 的 token 寫進 prompt 回覆、會同步或分享的檔案。
8. 不要在開機啟動資料夾或排程裡建立常駐程式，除非我明確同意。

## Phase 0：檢查
- 筆電：ssh -V、Windows Terminal 是否安裝（wt）、settings.json 位置（%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json 或 %LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json）、~/.ssh/config 是否已有同一台主機的 Host（有的話問我要沿用還是新增別名）、VS Code 是否有 Remote - SSH 與 GitLens 擴充套件。
- 伺服器：OS、tmux 版本（需 ≥ 3.3，太舊就回報我）、jq、curl、tmux ls、<PORT> 是否被占用。
- 分別在「登入 shell」（bash -lc）與「互動 shell」（bash -ic）檢查 command -v claude codex。如果只有互動 shell 找得到，記下所在目錄，Phase 2 要加進 ~/.profile。

## Phase 1：筆電 SSH
在 ~/.ssh/config 加入標記區塊：Host <ALIAS> 與 Host <ALIAS>-deck，兩者都有 HostName/User/Port/IdentityFile 與 ServerAliveInterval 30、ServerAliveCountMax 4；只有 <ALIAS>-deck 多一行 LocalForward <PORT> 127.0.0.1:<PORT>。
驗證：用 Windows 內建 ssh.exe 執行 ssh -o BatchMode=yes <ALIAS> echo ok。

## Phase 2：伺服器 PATH 與 tmux
- 若 Phase 0 發現 claude/codex 不在登入 shell 的 PATH：在 ~/.profile 加標記區塊，把該目錄與 $HOME/.local/bin 加進 PATH（用 case 判斷避免重複）。驗證 bash -lc 'command -v claude codex'。
- ~/.tmux.conf 加標記區塊：set -g mouse on、set -g allow-passthrough on、set -s extended-keys on、set -as terminal-features 'xterm*:extkeys'。tmux server 在跑就 tmux source-file ~/.tmux.conf。
- 驗證：tmux -f ~/.tmux.conf -L agentcheck new -d -s t && tmux -L agentcheck show -g allow-passthrough; tmux -L agentcheck kill-server，應輸出 allow-passthrough on。

## Phase 3：安裝 agent-deck（https://github.com/asheshgoplani/agent-deck）
- 先把 https://raw.githubusercontent.com/asheshgoplani/agent-deck/main/install.sh 下載到伺服器暫存檔，讀過內容（特別是會不會呼叫 sudo），確認 tmux 與 jq 已存在後，再執行 bash <檔案> --non-interactive --skip-tmux-config。驗證 bash -lc 'agent-deck version'。
- 備份 ~/.claude/settings.json 與 ~/.codex/config.toml，然後 agent-deck hooks install、agent-deck codex-hooks install，並用 status 確認；確認 Claude 設定仍是合法 JSON、原本設定（含 statusLine）都在。
- 建立 token：install -d -m 700 ~/.config/agent-deck; install -m 600 /dev/null ~/.config/agent-deck/web-token; head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > ~/.config/agent-deck/web-token（已存在就保留）。

## Phase 4：啟動腳本 ~/.local/bin/deck-up（權限 755）
重要：新版 agent-deck 的 TUI 拒絕在 tmux 裡執行，所以網頁伺服器用 --no-tui 常駐在 tmux session「deck」，TUI 在 SSH 終端機裡直接跑；並用 -e "PATH=$PATH" 把登入 shell 的 PATH 帶進 tmux，否則 agent-deck 找不到 claude。內容：

#!/usr/bin/env bash
if ! tmux has-session -t deck 2>/dev/null; then
  tmux new-session -d -s deck -e "PATH=$PATH" \
    "$HOME/.local/bin/agent-deck web --no-tui --push --listen 127.0.0.1:<PORT> --token-file $HOME/.config/agent-deck/web-token"
  sleep 1
fi
tmux has-session -t deck 2>/dev/null && echo "agent-deck web: running (tmux session deck, 127.0.0.1:<PORT>)"
[ -n "$TMUX" ] && exit 0
"$HOME/.local/bin/agent-deck"
exec bash -l

驗證：bash -lc 'command -v deck-up'。不要用 TMUX=x 之類的技巧跳過 TUI（tmux 會把 $TMUX 當 socket 路徑）。若要在這一步先把網頁伺服器帶起來，必須透過登入 shell 執行 tmux new-session 那一行，並檢查 /proc/<pane_pid>/environ 的 PATH 含有 claude 所在目錄、127.0.0.1:<PORT> 回 HTTP 200。

## Phase 5：Windows Terminal
備份 settings.json（JSONC，保留註解與既有設定），在 profiles.list 加兩個 profile（GUID 用 [guid]::NewGuid() 產生），不要改 defaultProfile：
- name「<ALIAS> · deck」，commandline: ssh -t <ALIAS>-deck "bash -lc ~/.local/bin/deck-up"，bellStyle ["window","taskbar"]，tabTitle "deck"，suppressApplicationTitle true
- name「<ALIAS> · shell」，commandline: ssh <ALIAS>，bellStyle ["window","taskbar"]
驗證：用 PowerShell 解析 JSON 成功；幫我用 wt -w 0 nt -p "{deck 的 GUID}" 開 deck 分頁，數秒後 curl.exe -s -o NUL -w "%{http_code}" http://localhost:<PORT>/ 應回 200。若失敗，到伺服器用 tmux capture-pane 與 ~/.local/share/agent-deck/logs/ 找原因再回報。
最後告訴我：用 ssh <ALIAS> cat ~/.config/agent-deck/web-token 取得 token（我自己執行），瀏覽器開 http://localhost:<PORT>/?token=<token>，再到 Tweaks 開 Notifications。

## Phase 6：VS Code
- 備份 %APPDATA%\Code\User\settings.json，加入 "remote.SSH.remotePlatform": {"<ALIAS>": "linux"} 與 "remote.portsAttributes": {"<PORT>": {"label": "agent-deck (use <ALIAS>-deck tunnel)", "onAutoForward": "ignore"}}（已有同名物件就合併）。
- 列出 <REPO_ROOT> 底下所有 git repo（含子資料夾，排除 .worktrees、.claude/worktrees、.venv、node_modules 這類 worktree 或第三方套件），編號給我選；若我已填 <REPOS> 就直接用。
- 在伺服器建立 <REPO_ROOT>/<ALIAS>.code-workspace（已存在就不要覆蓋，先問我），folders 列出選定的 repo（相對路徑），加一行註解說明增刪方式。
- 用 code --file-uri "vscode-remote://ssh-remote+<ALIAS><REPO_ROOT>/<ALIAS>.code-workspace" 開啟。VS Code 一律用 <ALIAS>，不要用 <ALIAS>-deck。

## 完成後的報告
1. 筆電與伺服器各改了哪些檔案，以及每個檔案的備份路徑。
2. 每個 Phase 的驗證結果與遇到的問題。
3. 日常用法：開「<ALIAS> · deck」並保持開著 → 瀏覽器 http://localhost:<PORT> → 網頁 + New 開 agent；VS Code 從 Open Recent 開 workspace。
4. 更新：agent-deck update，然後 tmux kill-session -t deck 再重開 deck 分頁。移除：agent-deck hooks uninstall、agent-deck codex-hooks uninstall、agent-deck uninstall（--keep-data 保留資料）、刪 deck-up，並移除各檔案的 agent-workflow 標記區塊。

~~~~
