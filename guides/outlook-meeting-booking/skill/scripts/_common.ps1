# Shared helpers for the outlook-meeting-booking skill.
# Requires classic Outlook (COM) with an Exchange account. New Outlook is not supported.
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less scripts with the ANSI code page.

$ErrorActionPreference = 'Stop'
# Chinese names come out garbled through redirected stdout without this.
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

# -File passes "a,b" as one string; split every list parameter on commas.
# The [string[]] cast matters: pipeline output is PSObject-wrapped, and passing a
# wrapped string to an Outlook COM method (CreateRecipient, Recipients.Add) hangs.
function Split-List([string[]]$Values) {
    [string[]]$out = @($Values | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    , $out
}

# Always work in the Exchange mailbox, never in Outlook's default data file
# (the default store may be a local PST, which hides meetings from phone/web).
function Get-OutlookContext([string]$Mailbox) {
    $app = New-Object -ComObject Outlook.Application
    $ns = $app.GetNamespace('MAPI')
    $accounts = @($ns.Accounts)
    if ($Mailbox) {
        $acct = $accounts | Where-Object { $_.SmtpAddress -eq $Mailbox -or $_.DisplayName -eq $Mailbox } | Select-Object -First 1
    } else {
        $acct = $accounts | Where-Object { $_.AccountType -eq 0 } | Select-Object -First 1
    }
    if (-not $acct) { throw 'No Exchange account found. Classic Outlook with an Exchange account is required.' }
    $store = $acct.DeliveryStore
    [pscustomobject]@{
        App      = $app
        NS       = $ns
        Account  = $acct
        Store    = $store
        Calendar = $store.GetDefaultFolder(9)   # olFolderCalendar
        Inbox    = $store.GetDefaultFolder(6)   # olFolderInbox
    }
}

function Get-Smtp($Entry) {
    try { $u = $Entry.GetExchangeUser(); if ($u) { return $u.PrimarySmtpAddress } } catch {}
    return $Entry.Address
}

function Get-RoomEntries($Ctx) {
    $lists = @($Ctx.NS.AddressLists)
    $roomList = $lists | Where-Object { $_.Name -eq 'All Rooms' } | Select-Object -First 1
    if (-not $roomList) { $roomList = $lists | Where-Object { $_.Name -match 'Room' } | Select-Object -First 1 }
    if (-not $roomList) { throw 'Room address list (All Rooms) not found.' }
    @($roomList.AddressEntries)
}

# Match a short token such as "909" against room names like "...(909)".
function Find-Room($Ctx, [string]$Token, $RoomEntries) {
    if (-not $RoomEntries) { $RoomEntries = Get-RoomEntries $Ctx }
    $hit = @($RoomEntries | Where-Object { $_.Name -eq $Token -or $_.Name -like "*($Token)*" })
    if ($hit.Count -eq 0) { $hit = @($RoomEntries | Where-Object { $_.Name -like "*$Token*" }) }
    $hit
}

# Worst status over [Start, End) on Day, using 15-minute free/busy slots.
# Returns: free | tentative | busy | oof | elsewhere | unknown | unresolved
function Get-SlotStatus($Ctx, [string]$Address, [datetime]$Day, [string]$Start, [string]$End) {
    $r = $Ctx.NS.CreateRecipient($Address)
    if (-not $r.Resolve()) { return 'unresolved' }
    try { $fb = $r.FreeBusy($Day.Date, 15, $true) } catch { return 'unknown' }
    $s = [int][math]::Floor(([timespan]$Start).TotalMinutes / 15)
    $e = [int][math]::Ceiling(([timespan]$End).TotalMinutes / 15)
    $codes = $fb.Substring($s, $e - $s).ToCharArray() | ForEach-Object { [string]$_ }
    # Severity: oof > busy > tentative > elsewhere > free
    foreach ($pair in @(@('3', 'oof'), @('2', 'busy'), @('1', 'tentative'), @('4', 'elsewhere'))) {
        if ($codes -contains $pair[0]) { return $pair[1] }
    }
    'free'
}

function Get-ItemById($Ctx, [string]$EntryId) {
    $Ctx.NS.GetItemFromID($EntryId, $Ctx.Store.StoreID)
}

# True once the meeting request has been sent (PidLidFInvited).
function Test-MeetingSent($Item) {
    try { [bool]$Item.PropertyAccessor.GetProperty('http://schemas.microsoft.com/mapi/id/{00062002-0000-0000-C000-000000000046}/8229000B') } catch { $false }
}
