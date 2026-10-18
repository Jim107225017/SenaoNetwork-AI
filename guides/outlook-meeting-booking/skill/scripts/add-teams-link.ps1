# Add a Teams meeting link to a saved (sent or unsent) meeting by pressing the Teams add-in's
# ribbon button through UI Automation. The Outlook object model cannot do this itself.
# Usage:
#   add-teams-link.ps1 -EntryId <id> [-KeepOpen] [-TimeoutSec 30]
# Opens the meeting window, presses "Teams Meeting", waits for the link, saves, and closes the
# window (unless -KeepOpen). Idempotent: a meeting that already has a link is left untouched,
# because the ribbon button is a toggle and a second press would remove the link.
# Output: EntryId, Subject, Status (added | already-present | failed), JoinUrl.
param(
    [Parameter(Mandatory)][string]$EntryId,
    [switch]$KeepOpen,
    [int]$TimeoutSec = 30,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

$TeamsUrlProp = 'http://schemas.microsoft.com/mapi/string/{00020329-0000-0000-C000-000000000046}/SkypeTeamsMeetingUrl'
function Get-TeamsUrl($Item) {
    try { [string]$Item.PropertyAccessor.GetProperty($TeamsUrlProp) } catch { '' }
}

$ctx = Get-OutlookContext $Mailbox
$m = Get-ItemById $ctx $EntryId
$result = [pscustomobject]@{ EntryId = $EntryId; Subject = $m.Subject; Status = 'failed'; JoinUrl = ''; Note = '' }

$existing = Get-TeamsUrl $m
if ($existing) {
    $result.Status = 'already-present'; $result.JoinUrl = $existing
    return $result
}

$m.Display()
$caption = $m.GetInspector.Caption

# Locate the inspector window (Office inspector class is rctrl_renwnd32) by its exact caption.
$root = [System.Windows.Automation.AutomationElement]::RootElement
$classCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ClassNameProperty, 'rctrl_renwnd32')
$win = $null
foreach ($i in 1..20) {
    foreach ($w in $root.FindAll([System.Windows.Automation.TreeScope]::Children, $classCond)) {
        if ($w.Current.Name -eq $caption) { $win = $w; break }
    }
    if ($win) { break }
    Start-Sleep -Milliseconds 500
}
if (-not $win) {
    $result.Note = "Meeting window '$caption' not found via UI Automation."
    return $result
}

# The Teams add-in button is named "Teams Meeting" / "Teams <local word for meeting>".
$btnCond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
$btn = $null
foreach ($i in 1..20) {
    foreach ($b in $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)) {
        if ($b.Current.Name -match '^Teams\b' -and $b.Current.IsEnabled) { $btn = $b; break }
    }
    if ($btn) { break }
    Start-Sleep -Milliseconds 500
}
if (-not $btn) {
    $result.Note = 'Teams button not found on the ribbon. Is the Teams Meeting add-in enabled?'
    return $result
}

$btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()

$deadline = (Get-Date).AddSeconds($TimeoutSec)
$url = ''
while (-not $url -and (Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500
    $url = Get-TeamsUrl $m
}
if (-not $url) {
    $result.Note = "Pressed '$($btn.Current.Name)' but no link appeared within $TimeoutSec s. Window left open."
    return $result
}

$m.Save()
if (-not $KeepOpen) { $m.Close(0) }   # olSave
$result.Status = 'added'; $result.JoinUrl = $url
$result
