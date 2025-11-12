# Example: Producer-Consumer with Start-ThreadJob
$threadSafeQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

# Producer job
Start-ThreadJob {
    param($q)
    for ($i = 1; $i -le 5; $i++) {
        $q.Enqueue("Data Item $i")
        Start-Sleep -Milliseconds 100
    }
    $q.Enqueue("`0") # Signal to quit
} -ArgumentList $threadSafeQueue | Out-Null

# Consumer job
$consumerJob = Start-ThreadJob {
    param($q)
    $element = $null
    while ($true) {
        if ($q.TryDequeue([ref]$element)) {
            if ("`0" -eq $element) {
                Write-Host "Consumer: Quit signal received."
                return
            }
            Write-Host "Consumer: Processing $element"
            Start-Sleep -Milliseconds 200
        } else {
            Start-Sleep -Milliseconds 50 # Wait a bit if queue is empty
        }
    }
} -ArgumentList $threadSafeQueue -StreamingHost $Host

Wait-Job $consumerJob | Out-Null
Receive-Job $consumerJob
Remove-Job $consumerJob