<#

meltGlacier - Feb 2022
Tool to delete archives in bulk from AWS glacier storage - stuXORstu <stuXORstu@gmail.com>

meltGlacier.ps1 -Filename output.json -Vaultname <VAULT_NAME> -Region <REGION_NAME> -Limit <NUM_LIMIT> (Default: 10)

Requires AWS CLI tools installed and authentication preconfigured or additionally applied via the command line.

AWS glacier storage can be fiddly to delete.  You can't just remove it from the
console.  You have to:
1. Invoke an inventory job, which can take a very long time.

    aws glacier initiate-job `
        --job-parameters '{\"Type\": \"inventory-retrieval\"}' `
        --vault-name <VAULT_NAME> --region <REGION_NAME> --account-id -


2. Check periodically that the job is completed, and still running.

    aws glacier list-jobs `
        --vault-name <VAULT_NAME> --account-id -

3. Download the results of that inventory file (write down that JobId from the previous step before it expires!)

    aws glacier get-job-output --job-id <JOB_ID> `
    --vault-name <VAULT_NAME> --region <REGION_NAME> `
    --account-id - ./output.json

4. Delete each object (or archive I think the correct terminology is).  Loop for ages, since you might 
have 100,000+ to delete 1 by 1.  Which is why the below is implemented to run in parallel.

The optimal -Limit (e.g. number of parallel request workers) will depend upon various factors and for reference I found
the following for a ~650 delete-archive operations:
    -Limit 5    1m 15s
    -Limit 10   46s
    -Limit 20   37s
    -Limit 50   37s

#>

param ($Filename, $Vault, $Region, $Limit = 10)
Write-Output "`nmeltGlacier`nRunning with $($Limit) threads..`n"

$_dict = [System.Collections.Concurrent.ConcurrentDictionary[string, Int32]]::new()
$_dict["tally"] = 0

$al = ConvertFrom-Json $(Get-Content $Filename)

$al.ArchiveList.archiveid | ForEach-Object -Parallel {
    $dict = $using:_dict
    $n = $dict["tally"]
    $maxn = $using:al.ArchiveList.Count
    $complete = [Math]::Round((($n / $maxn) * 100))

    Write-Progress -Activity "Bulk 'aws glacier delete-archive' in progrss" -Status "$complete% ($($n) / $($maxn)) Complete:" -PercentComplete $complete
    aws glacier delete-archive --archive-id=$_ --vault-name $using:Vault --account-id - ;

    $dict["tally"]++
    } -ThrottleLimit $Limit