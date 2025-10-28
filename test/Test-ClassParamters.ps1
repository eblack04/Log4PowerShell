[NoRunspaceAffinity()]
class Album {
    [string]$name
    [string]$band
    [string]$year

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
}


$album1 = [Album]::new("Dark Side of the Moon", "Pink Floyd", "1971")
Write-Host "$($album1.GetName()): by $($album1.GetBand()), from year $($album1.GetYear())"
$album2 = [Album]::new("Screaming for Vengeance", "Judas Priest")
Write-Host "$($album2.GetName()): by $($album2.GetBand()), from year $($album2.GetYear())"