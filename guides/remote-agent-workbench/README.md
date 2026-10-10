# 遠端 Agent 工作台

Claude Code、Codex 這類 AI agent 跑在遠端 Linux 伺服器上，從 Windows 筆電連線、管理、看 git 狀態。筆電關機、SSH 斷線，agent 都會繼續工作。

| 工具 | 負責什麼 |
|---|---|
| **agent-deck** | 管 agent（瀏覽器）：開 agent、看每個 agent 在跑、在等你、還是出錯，在網頁裡直接操作 |
| **herdr** | 管 agent（終端機）：agent 專用的多工器，側欄自動顯示狀態，agent 之間能互相傳訊息、分工 |
| **Windows Terminal** | 用 SSH 連到遠端 Linux 伺服器 |
| **VS Code + GitLens** | 用 Remote-SSH 開伺服器上的 repo，只顯示你選的 repo，用 GitLens 看分支與變更 |

agent-deck 和 herdr 二選一或同時裝都可以，hooks 互不衝突。怎麼選見 index.html 的「herdr vs agent-deck」分頁。

## 怎麼看

用瀏覽器直接打開 [index.html](index.html)（下載或 clone 後雙擊即可，不需要網路以外的任何東西）。內容用分頁分類：

| 分頁 | 內容 |
|---|---|
| 架構 | 筆電與伺服器各跑什麼、關鍵觀念（斷線、隧道、token） |
| agent-deck 設定 | 手動設定步驟 00–07（SSH、PATH、tmux、安裝、deck-up、Windows Terminal、VS Code） |
| agent-deck 介面 | 網頁每個區塊與欄位的功能 |
| herdr | 安裝步驟、基本觀念、快捷鍵、agent 互相溝通、注意事項 |
| herdr vs agent-deck | 功能比較與優缺點 |
| 日常使用 | 兩套工具的一天怎麼用、什麼情況 agent 會停 |
| 更新與移除 | agent-deck、herdr 的更新與完整移除方式 |
| 疑難排解 | 實際踩過的問題與解法 |
| 一鍵設定 Prompt | 填表產生 prompt，交給 agent 自動設定 |

## 讓 agent 幫你裝

不想手動做的話，把 prompt 貼給筆電上的 Claude Code：

- [prompts/agent-deck-setup.md](prompts/agent-deck-setup.md)：agent-deck + Windows Terminal + VS Code
- [prompts/herdr-setup.md](prompts/herdr-setup.md)：herdr

prompt 裡的 `<HOST>`、`<KEY>`、`<REPO_ROOT>` 等代號換成自己的值，留著不填 agent 會先問你。prompt 已經把實際部署時踩過的問題寫成規則，例如 agent-deck TUI 不能放在 tmux 裡、PATH 要帶進 tmux、Codex 第一次啟動要信任 herdr 的 hook。

## 檔案

```
remote-agent-workbench/
├── README.md                 # 本檔
├── index.html                # 完整教學頁（單一檔案，可離線開啟）
└── prompts/
    ├── agent-deck-setup.md   # agent-deck 一鍵設定 prompt
    └── herdr-setup.md        # herdr 一鍵安裝 prompt
```

## 版本

內容以下列版本實測：agent-deck v1.16.26、herdr 0.9.3、Claude Code 2.1.296、Codex CLI 0.160.0、Ubuntu 24.04、Windows 11。新版若行為不同，以官方文件為準：

- agent-deck：https://github.com/asheshgoplani/agent-deck
- herdr：https://herdr.dev/docs/

## 修改這份教學

`index.html` 是單一檔案，CSS 與 JS 都寫在裡面。兩份 prompt 同時存在 `index.html`（`<script type="text/plain" id="prompt-tpl">` 與 `id="prompt-tpl-herdr"`）和 `prompts/*.md`，改其中一邊時記得同步另一邊。不要把任何人的 IP、帳號、token 或 repo 路徑寫進來，一律用代號。
