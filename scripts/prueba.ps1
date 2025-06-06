Import-Module ActiveDirectory

$csvPath = "C:\ruta\usuarios.csv"
$defaultPassword = ConvertTo-SecureString "Batoi@1234" -AsPlainText -Force

$domain = "barcelona.lan"
$baseOU = "OU=Empresa,DC=barcelona,DC=lan"

$usuarios = Import-Csv -Path $csvPath

# Paso 1: Poner SamAccountName y UPN temporales para evitar conflictos
foreach ($u in $usuarios) {
    $sede = $u.sede
    $dept = $u.dept
    $dni = $u.dni
    $userOU = "OU=$dept,OU=$sede,$baseOU"

    $usuario = Get-ADUser -Filter { employeeID -eq $dni } -SearchBase $userOU -Properties SamAccountName -ErrorAction SilentlyContinue

    if ($usuario) {
        $tempSam = "$dni`_temp"
        $tempUPN = "$tempSam@$domain"
        try {
            Set-ADUser -Identity $usuario.DistinguishedName -SamAccountName $tempSam -UserPrincipalName $tempUPN
            Write-Output "Temporal: SamAccountName y UPN de usuario $dni cambiados a $tempSam / $tempUPN"
        } catch {
            Write-Warning "Error cambiando temporal SamAccountName para usuario $dni: $_"
        }
    }
    else {
        Write-Warning "Usuario con DNI $dni no encontrado en OU $userOU"
    }
}

# Paso 2: Poner SamAccountName, UPN definitivos y DisplayName + cambiar contraseña y forzar cambio
foreach ($u in $usuarios) {
    $sede = $u.sede
    $dept = $u.dept
    $dni = $u.dni
    $nombre = $u.nom
    $cognom1 = $u.cognom1
    $cognom2 = $u.cognom2
    $userOU = "OU=$dept,OU=$sede,$baseOU"

    $usuario = Get-ADUser -Filter { employeeID -eq $dni } -SearchBase $userOU -Properties SamAccountName -ErrorAction SilentlyContinue

    if ($usuario) {
        $newSam = $dni
        $newUPN = "$dni@$domain"
        $newDisplayName = "$nombre $cognom1 $cognom2"

        try {
            Set-ADUser -Identity $usuario.DistinguishedName -SamAccountName $newSam -UserPrincipalName $newUPN -DisplayName $newDisplayName
            Set-ADAccountPassword -Identity $usuario.DistinguishedName -Reset -NewPassword $defaultPassword
            Set-ADUser -Identity $usuario.DistinguishedName -ChangePasswordAtLogon $true
            Write-Output "Actualizado usuario $dni: SamAccountName, UPN, DisplayName y contraseña"
        } catch {
            Write-Warning "Error actualizando usuario $dni: $_"
        }
    }
    else {
        Write-Warning "Usuario con DNI $dni no encontrado en OU $userOU"
    }
}
