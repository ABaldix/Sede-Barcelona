Import-Module ActiveDirectory

# Ruta del CSV
$csvPath = "C:\ruta\usuarios.csv"

# Contraseña fija
$defaultPassword = ConvertTo-SecureString "Batoi@1234" -AsPlainText -Force

# Leer el CSV
$usuarios = Import-Csv -Path $csvPath

foreach ($u in $usuarios) {
    $dni = $u.DNI
    $ou = $u.OU

    if ($dni -and $ou) {
        # Ruta LDAP de la OU donde buscar
        $ouPath = "OU=$ou,OU=Empresa,DC=barcelona,DC=lan"

        # Buscar usuario por DNI en el OU específico
        # Suponemos que el atributo LDAP para DNI es 'employeeID' o algún otro. Cambia si tienes otro.
        $usuario = Get-ADUser -Filter { employeeID -eq $dni } -SearchBase $ouPath -Properties SamAccountName -ErrorAction SilentlyContinue

        if ($usuario) {
            Write-Output "Modificando usuario: $($usuario.SamAccountName) → DNI: $dni"

            # Cambiar SamAccountName y UserPrincipalName (nombre de inicio de sesión moderno)
            Set-ADUser -Identity $usuario.DistinguishedName `
                       -SamAccountName $dni `
                       -UserPrincipalName "$dni@barcelona.lan"

            # Restablecer contraseña y forzar cambio
            Set-ADAccountPassword -Identity $usuario.DistinguishedName -Reset -NewPassword $defaultPassword
            Set-ADUser -Identity $usuario.DistinguishedName -ChangePasswordAtLogon $true
        }
        else {
            Write-Warning "Usuario no encontrado con DNI '$dni' en OU=$ou"
        }
    }
    else {
        Write-Warning "Faltan datos en la fila: $($u | Out-String)"
    }
}
