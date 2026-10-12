# Create a meeting in the Exchange calendar. Saves it UNSENT; sending is a separate, user-confirmed step.
# Usage:
#   new-meeting.ps1 -Subject "Daily Sync Up" -Date 2026-10-13 -Start 10:00 -End 10:30 `
#       -Required "a@corp.com,b@corp.com" [-Optional "c@corp.com"] -RoomAddress room909@corp.com `
#       [-Body "agenda"] [-Display] [-DryRun]
# -Display opens the meeting window (needed when the user must click "Teams Meeting" before sending).
# -DryRun builds the item, prints it and discards it without saving.
param(
    [Parameter(Mandatory)][string]$Subject,
    [Parameter(Mandatory)][string]$Date,
    [Parameter(Mandatory)][string]$Start,
    [Parameter(Mandatory)][string]$End,
    [Parameter(Mandatory)][string[]]$Required,
    [string[]]$Optional = @(),
    [string]$RoomAddress,
    [string]$Body,
    [switch]$Display,
    [switch]$DryRun,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox
$day = ([datetime]$Date).Date

# Items.Add on the Exchange calendar (not Application.CreateItem, which uses the default store).
$m = $ctx.Calendar.Items.Add(1)          # olAppointmentItem
$m.MeetingStatus = 1                      # olMeeting
$m.Subject = $Subject
$m.Start = $day + [timespan]$Start
$m.End = $day + [timespan]$End
if ($Body) { $m.Body = $Body }
foreach ($a in (Split-List $Required)) { ($m.Recipients.Add($a)).Type = 1 }   # olRequired
foreach ($a in (Split-List $Optional)) { ($m.Recipients.Add($a)).Type = 2 }   # olOptional
if ($RoomAddress) {
    $room = $m.Recipients.Add($RoomAddress); $room.Type = 3                     # olResource
    [void]$room.Resolve()
    $m.Location = $room.Name
}
$resolved = $m.Recipients.ResolveAll()

$summary = [pscustomobject]@{
    Subject    = $m.Subject
    Start      = $m.Start.ToString('yyyy-MM-dd ddd HH:mm')
    End        = $m.End.ToString('HH:mm')
    Location   = $m.Location
    Recipients = (@($m.Recipients) | ForEach-Object { "$($_.Name)[$(@('','req','opt','room')[$_.Type])]" }) -join ', '
    Resolved   = $resolved
    Folder     = $ctx.Calendar.FolderPath
    EntryId    = ''
}

if ($DryRun) { $m.Close(1); $summary.EntryId = '(dry run, discarded)'; return $summary }   # olDiscard
if (-not $resolved) { $m.Close(1); throw "Some recipients did not resolve: $($summary.Recipients)" }

$m.Save()
$summary.EntryId = $m.EntryID
if ($Display) { $m.Display() }
$summary
