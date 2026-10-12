---
name: outlook-meeting-booking
description: 用傳統版 Outlook 預約會議與會議室：依優先順序找空的會議室、邀請多位參與者、檢查參與者有沒有空、寄出前讓使用者確認、寄出後確認會議室是否接受，被拒絕就改用下一間。觸發語句如「幫我約會議」「訂會議室」「這週每天 10 點約 Daily Sync Up」「改會議室」「會議室有回覆了嗎」。
---

# Outlook 會議預約

透過 Outlook COM 操作**傳統版 Outlook**（New Outlook 不支援）。所有腳本在 `scripts/`，用下列方式執行（中文參數可以直接傳）：

```powershell
$S = "$HOME\.claude\skills\outlook-meeting-booking\scripts"
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$S\<script>.ps1" <參數>
```

清單參數一律用逗號分隔的單一字串，例如 `-Names "王小明,a@corp.com"`。下文範例中的 `& ... "$S\x.ps1"` 都是上面這行呼叫的縮寫。

## 預設值

- **會議室優先順序**：`<你的會議室，例如 909,901,812>`。安裝後改成自己常用的會議室，填會議室名稱括號內的房號，或任何能唯一比對到該會議室的關鍵字。每次都要先問使用者這次要不要沿用。
- **信箱**：自動使用 Outlook 中的 Exchange 帳號。

## 硬性規則

1. **寄出前一定要問**。建立會議只會存成未寄出；寄出邀請、寄出更新（改會議室、改時間）都要等使用者明確說「寄出」或同意，才可以執行 `send-meeting.ps1`。同意只對當次有效。
2. **會議一律建在 Exchange 信箱的行事曆**，不可以用 `Application.CreateItem`。有些電腦的 Outlook 預設資料檔是本機 PST，用預設位置建立的會議只會存在這台電腦。`new-meeting.ps1` 已經處理好這件事。
3. **Teams 連結無法用程式加**。需要 Teams 時，用 `-Display` 開啟會議視窗，請使用者點「Teams 會議」後自己按傳送。這時不要再執行 `send-meeting.ps1`，避免重複寄出。
4. 不要刪除會議或郵件，也不要動使用者自己開著、跟本次任務無關的 Outlook 視窗。

## 流程

### 1. 收集資訊
問清楚以下資訊，缺什麼就問什麼：
- 主旨
- 日期：可以是多天，例如「這週二到週五」，要換算成實際日期
- 起訖時間
- 參與者：可以多位，分必要和選擇性
- 要不要 Teams 連結
- 議程內文（選填）
- **會議室優先順序**：提供上面設定的預設順序讓使用者確認或修改

### 2. 解析參與者
```powershell
& ... "$S\resolve-people.ps1" -Names "王小明,someone@<company>.com"
```
- `ok`：取得 Smtp，後續都用 email。
- `ambiguous`：列出候選人請使用者選。
- `not-found`：請使用者提供 email 或其他寫法。
- 中文名字會掃描整個通訊錄，大約需要 15 秒，屬於正常情況。

### 3. 檢查參與者和會議室有沒有空
```powershell
& ... "$S\check-availability.ps1" -Dates "2026-10-13,2026-10-14" -Start 10:00 -End 10:30 `
    -People "a@<company>.com,b@<company>.com" -Rooms "<room1>,<room2>,<room3>"
```
- Status 有：`free`、`tentative`、`busy`、`oof`（外出）、`elsewhere`（在其他地方工作）、`unknown`（沒有權限查看）、`unresolved`。
- **參與者**：只要是 `busy` 或 `oof`，就列出衝突的日期和人，問使用者要繼續、換時間還是略過那天。`tentative` 也要提醒，但可以繼續。
- **會議室**：每一天依優先順序取第一間 `free` 的會議室。三間都沒空時，用全部會議室清單查同樓層或附近有空的會議室給使用者選：
  `-Rooms` 可以傳任何房號，或用 `"<棟別樓層>"` 這類關鍵字。關鍵字比對到多間時，Note 欄會列出比對到的會議室。
- 解讀時要注意：使用者自己已經訂好的會議，也會讓會議室顯示 `busy`、讓參與者顯示 `tentative`（邀請還沒回覆時）。重新檢查之前已經預約的時段前，先用 `list-meetings.ps1` 比對。

### 4. 給使用者確認表
用表格列出每一場：日期、時間、會議室、各參與者有沒有空、有沒有 Teams 連結。等使用者確認後再建立會議。

### 5. 建立會議（未寄出）
建立之前，先對要用的會議室再跑一次 `check-availability.ps1`，避免會議室在這段時間被別人訂走。
```powershell
& ... "$S\new-meeting.ps1" -Subject "Daily Sync Up" -Date 2026-10-13 -Start 10:00 -End 10:30 `
    -Required "a@<company>.com,b@<company>.com" -Optional "c@<company>.com" -RoomAddress <room-email> `
    [-Body "議程"] [-Display]
```
- 會議室 email 從 `check-availability.ps1` 輸出的 `Address` 取得。
- 需要 Teams 時加 `-Display`。
- 每一場都要記下輸出的 `EntryId`。
- 可以先用 `-DryRun` 驗證收件人能不能解析，這個模式不會存檔。

### 6. 寄出（必須經過確認）
- **需要 Teams**：請使用者在每個會議視窗點「Teams 會議」，然後按傳送。
- **不需要 Teams**：列出要寄出的每一場，使用者說「寄出」後才執行：
  ```powershell
  & ... "$S\send-meeting.ps1" -EntryId "<id1>,<id2>"
  ```
- **必須確認真的寄出了，不能只看指令有沒有報錯**。`Item.Send()` 可能沒報錯，實際上卻沒有寄出任何信（從其他資料檔搬過來的會議就發生過）。
  - `send-meeting.ps1` 會到寄件備份確認。結果是 `NOT VERIFIED` 時，**不可以回報成功**，要改用 `-Display` 開啟會議視窗，請使用者自己按「傳送」或「傳送更新」。
  - 使用者手動送出的會議，`list-meetings.ps1` 的 `Sent` 欄位不能當作依據（第一次寄出後就一直是 True，之後的更新有沒有寄出都看不出來）。要用步驟 7 的會議室回覆和會議室的空檔狀態確認。

### 7. 確認會議室有沒有接受預約
寄出後等 1 到 2 分鐘再查：
```powershell
& ... "$S\check-room-responses.ps1" -Subject "Daily Sync Up" -Since "2026-10-12 09:00"
```
`-Since` 填寄出前的時間。每間會議室、每個日期只會顯示最新一次的回覆，所以會議室先拒絕、後來又接受更新時，結果會是接受。

同時用 `check-availability.ps1 -Rooms <房號>` 查會議室在該時段的狀態：預約成功後應該變成 `busy` 或 `tentative`。如果寄出幾分鐘後會議室還是 `free`、也沒有回信，就代表會議室沒有收到預約，回到步驟 6 處理。
- `accepted`：完成。
- `declined`：依優先順序找下一間 `free` 的會議室，然後問使用者要不要改成那一間。使用者同意後依序：
  1. 用 `list-meetings.ps1` 取得該場會議的 EntryId。
  2. 執行 `change-room.ps1 -EntryId <id> -NewRoomAddress <room smtp>`。這一步只修改會議並存檔，不會寄出。
  3. 執行 `send-meeting.ps1 -EntryId <id>` 寄出更新。使用者同意改會議室，就代表同意寄出這次更新。結果是 `NOT VERIFIED` 時，比照步驟 6 處理。
  4. 回到步驟 7，再確認一次新會議室的回覆。
- **沒有回覆**：告訴使用者哪幾場還沒收到會議室的回覆，並提議稍後再查。

### 8. 最後彙總
用表格列出每一場：日期、時間、會議室、會議室的回覆、參與者有沒有空、Teams 連結的狀態。

## 其他工具

- `list-meetings.ps1 -Subject <主旨> -From <日期> -To <日期>`：列出已建立的會議，包含 EntryId、是否已寄出和收件人。

## 已知問題

- 字串傳給 Outlook COM 前，必須是單純的 `[string]`。`_common.ps1` 的 `Split-List` 已經處理；自己另外寫指令時，經過管線處理的字串要先轉型，否則 `CreateRecipient` 會卡住。
- PowerShell 變數名稱不分大小寫，所以不要用 `$since` 去接 `[string]$Since` 參數轉型後的值，否則日期會被轉回字串。
- 會議回覆郵件裡的會議開始時間（屬性 820D0040），讀出來就已經是本地時間，不要再轉換時區。
- **絕對不要把已寄出的會議在資料檔之間搬移**（例如從本機 PST 搬到 Exchange 行事曆）。搬過去的會議會變成「複製」的副本（`MeetingStatus = 3`，畫面會顯示「此會議已複製到您的行事曆，將不接收更新」），失去主辦人身分，之後不能再寄更新或取消，`Send()` 也不會報錯。萬一會議被建在錯的資料檔，就讓它留在原處，從原處修改；並請使用者把預設資料檔改成 Exchange 信箱。
- 改會議室或時間前，先確認 `MeetingStatus` 是 1（主辦人的會議）。如果是 3，代表無法寄出更新，要改成重新建立一場會議，並告訴使用者舊的邀請要另外處理。
