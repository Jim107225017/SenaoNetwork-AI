# Read room (and attendee) replies to a meeting from the Exchange inbox.
# Usage: check-room-responses.ps1 -Subject "Daily Sync Up" -Since "2026-10-12 09:00"
# Output: latest reply per (Sender, MeetingDate): accepted | declined | tentative.
param(
    [Parameter(Mandatory)][string]$Subject,
    [Parameter(Mandatory)][string]$Since,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox
$sinceTime = [datetime]$Since
$kinds = @{ 55 = 'declined'; 56 = 'accepted'; 57 = 'tentative' }   # olMeetingResponseNegative/Positive/Tentative
$startProp = 'http://schemas.microsoft.com/mapi/id/{00062002-0000-0000-C000-000000000046}/820D0040'

$items = $ctx.Inbox.Items.Restrict("[ReceivedTime] >= '$($sinceTime.ToString('MM/dd/yyyy HH:mm'))'")
$rows = foreach ($it in @($items)) {
    if (-not $kinds.ContainsKey([int]$it.Class)) { continue }
    # Subject is "<prefix>: <subject>" with a localized prefix (Accepted / 已接受 ...).
    if (-not ($it.Subject -like "*: $Subject" -or $it.Subject -like "*$([char]0xFF1A)$Subject")) { continue }
    # This property already comes back in local time.
    $start = try { [datetime]$it.PropertyAccessor.GetProperty($startProp) } catch { $null }
    [pscustomobject]@{
        Sender      = $it.SenderName
        MeetingDate = if ($start) { $start.ToString('yyyy-MM-dd ddd') } else { '?' }
        Response    = $kinds[[int]$it.Class]
        Received    = ([datetime]$it.ReceivedTime).ToString('yyyy-MM-dd HH:mm')
    }
}
# Keep only the latest reply per room/person and meeting date (a room may decline, then accept an update).
$rows | Group-Object Sender, MeetingDate | ForEach-Object {
    $_.Group | Sort-Object Received -Descending | Select-Object -First 1
} | Sort-Object MeetingDate, Sender
