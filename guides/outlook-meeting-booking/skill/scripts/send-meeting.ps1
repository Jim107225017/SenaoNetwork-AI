# Send a meeting request (or update) by EntryId. Only run after the user explicitly says to send.
# Usage: send-meeting.ps1 -EntryId "<id1>,<id2>"
# Item.Send() can return without error yet send nothing (seen on meetings moved between stores),
# so every send is verified against Sent Items. Result 'NOT VERIFIED' means: do not report success;
# open the meeting with -Display and ask the user to press Send / Send Update.
param(
    [Parameter(Mandatory)][string[]]$EntryId,
    [int]$VerifySeconds = 60,
    [string]$Mailbox
)
. "$PSScriptRoot\_common.ps1"
$ctx = Get-OutlookContext $Mailbox
$sentFolder = $ctx.Store.GetDefaultFolder(5)   # olFolderSentMail

function Get-SentCount([string]$Subject, [datetime]$After) {
    $filter = "[SentOn] >= '$($After.ToString('MM/dd/yyyy HH:mm'))'"
    @(@($sentFolder.Items.Restrict($filter)) | Where-Object { $_.Subject -eq $Subject -and $_.SentOn -ge $After }).Count
}

foreach ($id in (Split-List $EntryId)) {
    $m = Get-ItemById $ctx $id
    $start = $m.Start.ToString('yyyy-MM-dd ddd HH:mm')
    $subject = [string]$m.Subject
    if (-not $m.Recipients.ResolveAll()) {
        [pscustomobject]@{ Start = $start; Location = $m.Location; Result = 'NOT SENT: unresolved recipients' }
        continue
    }
    # SentOn has minute precision in the Restrict filter, so compare against a baseline count.
    $before = (Get-Date).AddSeconds(-1)
    $baseline = Get-SentCount $subject $before.AddMinutes(-1)
    $m.Send()

    $verified = $false
    $deadline = (Get-Date).AddSeconds($VerifySeconds)
    while ((Get-Date) -lt $deadline) {
        if ((Get-SentCount $subject $before.AddMinutes(-1)) -gt $baseline) { $verified = $true; break }
        Start-Sleep -Seconds 3
    }
    [pscustomobject]@{
        Start    = $start
        Location = $m.Location
        Result   = if ($verified) { 'sent (verified in Sent Items)' } else { 'NOT VERIFIED: nothing new in Sent Items' }
    }
}
