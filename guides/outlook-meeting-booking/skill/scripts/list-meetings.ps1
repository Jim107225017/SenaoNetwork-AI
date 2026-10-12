# List meetings in the Exchange calendar by subject and date range, with EntryId and sent state.
# Usage: list-meetings.ps1 -Subject "Daily Sync Up" -From 2026-10-12 -To 2026-10-16
param(
    [Parameter(Mandatory)][string]$Subject,
    [Parameter(Mandatory)][string]$From,
    [Parameter(Mandatory)][string]$To,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox
$fromDate = ([datetime]$From).Date
$toDate = ([datetime]$To).Date.AddDays(1)
$escaped = $Subject.Replace("'", "''")

# Filtering by subject first is reliable; piping the whole Items collection is flaky over COM.
@($ctx.Calendar.Items.Restrict("[Subject] = '$escaped'")) |
    Where-Object { $_.Start -ge $fromDate -and $_.Start -lt $toDate } |
    Sort-Object Start |
    ForEach-Object {
        [pscustomobject]@{
            Start      = $_.Start.ToString('yyyy-MM-dd ddd HH:mm')
            End        = $_.End.ToString('HH:mm')
            Location   = $_.Location
            Sent       = (Test-MeetingSent $_)
            Recipients = (@($_.Recipients) | ForEach-Object { "$($_.Name)[$(@('','req','opt','room')[$_.Type])]" }) -join ', '
            EntryId    = $_.EntryID
        }
    }
