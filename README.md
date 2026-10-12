# SenaoNetwork-AI

分享 AI 與 agent 開發的使用方式、設定教學與可直接交給 agent 執行的 prompt，讓每個人更快開始用 agent 開發。

## 目錄

| 主題 | 說明 |
|---|---|
| [遠端 Agent 工作台](guides/remote-agent-workbench/) | 在遠端 Linux 伺服器跑 Claude Code／Codex，從 Windows 筆電用 agent-deck（瀏覽器）或 herdr（終端機）管理 agent，Windows Terminal 走 SSH，VS Code + GitLens 看 git 狀態。含一鍵設定 prompt。 |

## 怎麼用這個 repo

- 每個主題一個資料夾，放在 `guides/<主題>/` 底下，資料夾內的 `README.md` 說明這個主題是什麼、怎麼開始。
- 教學頁是 `index.html`，下載或 clone 後用瀏覽器直接打開。
- 要交給 agent 執行的 prompt 放在主題底下的 `prompts/`，複製貼給 Claude Code 等 agent 即可。

## 結構

```
SenaoNetwork-AI/
├── README.md                     # 本檔：總目錄
└── guides/
    └── <主題>/
        ├── README.md             # 主題說明
        ├── index.html            # 教學頁（可離線開啟）
        └── prompts/              # 可直接交給 agent 的 prompt
```

## 新增主題

1. 在 `guides/` 底下建立資料夾，名稱用小寫英文加連字號，例如 `guides/claude-code-basics/`。
2. 至少放一份 `README.md`：目的、適合誰、怎麼開始、實測版本。
3. 在上面的目錄表格加一列。
4. 不要提交任何個人資訊或機密：IP、帳號、token、私鑰路徑、內部 repo 路徑一律改成 `<代號>`。
