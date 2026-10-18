# Outlook 會議預約 skill

讓 Claude Code 透過傳統版 Outlook 幫你約會議、訂會議室：依你的優先順序找空的會議室、邀請多位參與者、檢查參與者有沒有空、寄出前先讓你確認，寄出後再確認會議室是否接受，被拒絕就改用下一間。

## 適合誰

- Windows 上使用**傳統版 Outlook**（Microsoft 365 / Exchange 帳號）的人。New Outlook 不支援 COM 自動化，無法使用。
- 常常要重複預約固定會議（例如每天的 Daily Sync Up），或常常搶會議室的人。

## 能做什麼

| 功能 | 說明 |
|---|---|
| 解析參與者 | 中文名字或 email 都可以，同名時列出候選人 |
| 查空檔 | 一次查多位參與者、多間會議室、多天的同一時段 |
| 依優先順序選會議室 | 每天取第一間有空的會議室，都沒空時列出其他選擇 |
| 建立會議 | 建立在 Exchange 行事曆，先不寄出 |
| 加 Teams 連結 | 自動替你按下會議視窗的「Teams 會議」按鈕，不用手動點 |
| 寄出 | **一定先問你**，你同意後才寄出 |
| 確認會議室回覆 | 讀取會議室的接受或拒絕回信，被拒絕就提議改用下一間 |

## 怎麼開始

1. 把 [`skill/`](skill/) 資料夾複製到 `%USERPROFILE%\.claude\skills\outlook-meeting-booking\`：

   ```powershell
   Copy-Item -Recurse .\guides\outlook-meeting-booking\skill "$HOME\.claude\skills\outlook-meeting-booking"
   ```

2. 打開 `SKILL.md`，把「預設值」裡的會議室優先順序改成你常用的會議室，例如 `909`、`901`、`812`（會議室名稱括號內的房號）。
3. 確認 Outlook 已經開啟並登入，然後在 Claude Code 裡說：「幫我約明天 10:00–10:30 的 Daily Sync Up，邀請王小明」。

## 限制與注意事項

- **Teams 連結是靠 UI Automation 按按鈕加上的**。Outlook 的物件模型沒有辦法直接加 Teams 連結（網路上常見的做法是 SendKeys 模擬按鍵，或改走 Microsoft Graph API，前者不穩定、後者要向 IT 申請應用程式權限）。這個 skill 改用 Windows UI Automation 找到會議視窗上的「Teams 會議」按鈕直接按下，過程中會短暫跳出會議視窗 2 到 5 秒再自動關閉，期間請不要操作 Outlook。按不到時（例如 Teams 增益集被停用、Outlook 介面語言不是中文或英文）會退回請你手動點的流程。
- 有些電腦的 Outlook 預設資料檔是本機 PST。skill 一律把會議建在 Exchange 信箱的行事曆，以免會議只存在本機。
- 查空檔只看得到忙碌狀態，看不到別人的會議內容。

## 實測版本

- Windows 11 Pro、Windows PowerShell 5.1
- Microsoft Outlook（傳統版）16.0、Exchange Online
- Claude Code desktop app
