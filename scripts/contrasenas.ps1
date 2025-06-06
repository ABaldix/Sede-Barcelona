Import-Module ActiveDirectory

# Contraseña fija y segura
$defaultPassword = ConvertTo-SecureString "Batoi@1234" -AsPlainText -Force

# Buscar todos los usuarios dentro de la OU "Empresa" y sus sub-OUs
$usuarios = Get-ADUser -Filter * -SearchBase "OU=Empresa,DC=barcelona,DC=lan" -SearchScope Subtree -Properties GivenName, Surname

foreach ($usuario in $usuarios) {
    $nombre = $usuario.GivenName
    $apellido = $usuario.Surname

    if ($nombre -and $apellido) {
        # Crear nombre de usuario: primera letra del nombre + apellido, en minúsculas
        $username = ($nombre.Substring(0,1) + $apellido).ToLower()

        Write-Output "Usuario: $($usuario.Name) -> Nuevo username: $username"

        # Si quieres cambiar el SamAccountName o UserPrincipalName, descomenta esto:
        # Set-ADUser -Identity $usuario -SamAccountName $username -UserPrincipalName "$username@barcelona.lan"

        # Asignar contraseña y forzar cambio en el primer inicio
        Set-ADAccountPassword -Identity $usuario -Reset -NewPassword $defaultPassword
        Set-ADUser -Identity $usuario -ChangePasswordAtLogon $true
    }
    else {
        Write-Warning "Faltan datos (nombre o apellido) en el usuario: $($usuario.SamAccountName)"
    }
}
