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

        # Comprobar si SamAccountName ya está en uso por otro usuario
        $usuarioConSam = Get-ADUser -Filter { SamAccountName -eq $dni } -ErrorAction SilentlyContinue

        $puedeCambiarSam = $true

        if ($usuarioConSam) {
            if ($usuarioConSam.DistinguishedName -ne $usuario.DistinguishedName) {
                Write-Warning "SamAccountName '$dni' ya está en uso por otro usuario $($usuarioConSam.SamAccountName). No se cambiará."
                $puedeCambiarSam = $false
            }
        }

        if ($puedeCambiarSam -and $usuario.SamAccountName -ne $dni) {
            # Cambiar SamAccountName y UPN
            $newUPN = "$dni@$domain"
            Set-ADUser -Identity $usuario.DistinguishedName -SamAccountName $dni -UserPrincipalName $newUPN
            Write-Output "SamAccountName y UPN cambiados a $dni y $newUPN"
        }
        else {
            Write-Output "No se cambió SamAccountName (ya está bien o está en uso por otro)"
        }

        # Cambiar contraseña y forzar cambio
        Set-ADAccountPassword -Identity $usuario.DistinguishedName -Reset -NewPassword $defaultPassword
        Set-ADUser -Identity $usuario.DistinguishedName -ChangePasswordAtLogon $true
    }
    else {
        Write-Warning "Usuario con DNI $dni no encontrado en OU $userOU"
    }
}
