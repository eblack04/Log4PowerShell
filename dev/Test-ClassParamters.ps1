[NoRunspaceAffinity()]
class Album {
    [string]$name
    [string]$band
    [string]$year
    [string]$logFile = "C:\Users\EdwardBlackwell\Documents\logs\classTest.log"
    
    Album([string]$name, [string]$band, [string]$year) {
        $this.name = $name
        $this.band = $band
        $this.year = $year
    }

    [string]GetName() {
        return $this.name
    }

    [string]GetBand() {
        return $this.band
    }

    [string]GetYear() {
        return $this.year
    }

    [void]hidden WriteYear() {
        Add-Content -Path $this.logFile -Value $this.year
    }

    [void]WriteParameter() {
        $job = Start-ThreadJob -Name "classTestJob" -ScriptBlock {
            param ($Album)

            Add-Content -Path $Album.logFile -Value $Album.band
            $Album.WriteYear()
        } -ArgumentList $this
        Wait-Job -Job $job
        Remove-Job -Job $job
    }
}


$album1 = [Album]::new("Dark Side of the Moon", "Pink Floyd", "1971")
Write-Host "$($album1.GetName()): by $($album1.GetBand()), from year $($album1.GetYear())"
$album2 = [Album]::new("Screaming for Vengeance", "Judas Priest", "1982")
Write-Host "$($album2.GetName()): by $($album2.GetBand()), from year $($album2.GetYear())"
$album2.WriteParameter()