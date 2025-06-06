Import-Module ActiveDirectory

$csvPath = "C:\ruta\usuarios.csv"
$defaultPassword = ConvertTo-SecureString "Batoi@1234" -AsPlainText -Force

$domain = "barcelona.lan"
$baseOU = "OU=Empresa,DC=barcelona,DC=lan"

$usuarios = Import-Csv -Path $csvPath

foreach ($u in $usuarios) {
    $sede = $u.sede
    $dept = $u.dept
    $dni = $u.dni

    $userOU = "OU=$dept,OU=$sede,$baseOU"

    $usuario = Get-ADUser -Filter { employeeID -eq $dni } -SearchBase $userOU -Properties SamAccountName, UserPrincipalName -ErrorAction SilentlyContinue

    if ($usuario) {
        Write-Output "Procesando usuario $($usuario.SamAccountName) con DNI $dni"

        # Solo informar si el SamAccountName no coincide con DNI
        if ($usuario.SamAccountName -ne $dni) {
            Write-Warning "SamAccountName actual ($($usuario.SamAccountName)) NO coincide con DNI ($dni). No se cambia para evitar conflicto."
        }

        # Igual con UserPrincipalName
        $expectedUPN = "$dni@$domain"
        if ($usuario.UserPrincipalName -ne $expectedUPN) {
            Write-Warning "UserPrincipalName actual ($($usuario.UserPrincipalName)) NO coincide con esperado ($expectedUPN). No se cambia para evitar conflicto."
        }

        # Cambiar contraseña y forzar cambio
        Set-ADAccountPassword -Identity $usuario.DistinguishedName -Reset -NewPassword $defaultPassword
        Set-ADUser -Identity $usuario.DistinguishedName -ChangePasswordAtLogon $true
    }
    else {
        Write-Warning "Usuario con DNI $dni no encontrado en OU $userOU"
    }
}
