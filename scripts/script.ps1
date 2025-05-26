# Ruta al CSV
$csvPath = "C:\ruta\al\archivo\usuaris.csv"

# Leer el archivo CSV
$usuarios = Import-Csv -Path $csvPath

foreach ($usuario in $usuarios) {
    $nombre = $usuario.nom
    $apellido1 = $usuario.cognom1
    $apellido2 = $usuario.cognom2
    $dni = $usuario.dni
    $nombreCompleto = "$nombre $apellido1 $apellido2"
    
    # Usuario y contraseña
    $username = $dni
    $password = "$nombre@2024"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

    # Verificar si el usuario ya existe
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Write-Host "El usuario $username ya existe. Se omite."
    }
    else {
        # Crear el usuario
        New-LocalUser -Name $username `
                      -FullName $nombreCompleto `
                      -Password $securePassword `
                      -UserMayNotChangePassword `
                      -PasswordNeverExpires `
                      -AccountNeverExpires `
                      -Description "$($usuario.dept) - $($usuario.descrip)"
        
        # Agregarlo al grupo "Usuarios"
        Add-LocalGroupMember -Group "Users" -Member $username

        Write-Host "Usuario $username creado correctamente."
    }
}
