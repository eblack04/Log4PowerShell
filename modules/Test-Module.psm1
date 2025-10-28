Function Get-First {
    Param (
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][String]$First
    )

    Write-Host "First string: $First"
}

Function Get-Second {
    Param (
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][String]$Second
    )

    Write-Host "Second string: $Second"
}

Function Get-Third {
    Param (
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][String]$Third
    )

    Write-Host "Third string: $Third"
}

Add-Type -Language CSharp -TypeDefinition @"
  public class MyClass {
      public string Name { get; set; }
      public int Age { get; set; }
  }

  public enum MyEnum {
      Value1,
      Value2
  }
"@

Export-ModuleMember -Function Get-First
Export-ModuleMember -Function Get-Third