function Say-Hello {
    "Hello world!"
}

function From-ThreadJob {
    param($i)
    "From ThreadJob # $i"
}

$def = @(
    ${function:Say-Hello}.ToString()
    ${function:From-ThreadJob}.ToString()
)

function Run-Jobs {
    param($numerOfJobs, $functionDefinitions)

    $jobs = foreach($i in 1..$numerOfJobs) {
        Start-ThreadJob -ScriptBlock {
            # bring the functions definition to this scope
            $helloFunc, $threadJobFunc = $using:functionDefinitions
            # define them in this scope
            ${function:Say-Hello} = $helloFunc
            ${function:From-ThreadJob} = $threadJobFunc
            # sleep random seconds
            Start-Sleep (Get-Random -Maximum 10)
            # combine the output from both functions
            (Say-Hello) + (From-ThreadJob -i $using:i)
        }
    }

    Receive-Job $jobs -AutoRemoveJob -Wait
}

Run-Jobs -numerOfJobs 10 -functionDefinitions $def