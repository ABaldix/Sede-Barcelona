#------------------#
# Leer fichero CSV #
#------------------#
$usuarios = Import-Csv "./usuaris.csv"
Foreach ($usuario in $usuarios) {
    $nom = $usuario.nom
    $apellido1 = $usuario.cognom1
    $apellido2 = $usuario.cognom2
    $dni = $usuario.dni
    $sede = $usuario.sede
    $departamento = $usuario.dept
    $descripcion = $usuario.descrip

if ($departamento -eq "Barcelona"){    
    # Username variables
    $usrName = ($nom.Substring(0,1) + $apellido1).ToLower()

    Write-Host ""
    Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
    Write-Host "Creando usuario $usrName con su departamento $departamento..."

    # Variables
    $ouString = "OU=$departamento,OU=Empresa,DC=barcelona,DC=lan"
    $getOU = Get-ADOrganizationalUnit -SearchBase $ouString -Filter {Name -eq $departamento}

    #--------------------------------------------#
    # Comprobar si existe su grupo, si no crealo #
    #--------------------------------------------#
    
    # Variables
    $grp = "gg" + $departamento
    $getGg = Get-ADGroup -SearchBase $ouString -Filter {Name -eq $grp}

    if ($descripcion -eq "Jefe") {
        $grp = "ggJefe" + $departamento
        $jefeOUString = "OU=$departamento,OU=Barcelona,DC=barcelona,DC=lan"
        $getJefeGg = Get-ADGroup -SearchBase $jefeOUString -Filter {Name -eq $grp}

        if ($getJefeGg -eq $null) {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "No existe un grupo para el jefe del departamento $departamento, creandolo ahora..."
            
            New-ADGroup -Name $grp -GroupScope Global -Path $jefeOUString -SamAccountName $grp
            
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Grupo $grp creado con exito, continuando..."
        } else {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Ya existe un grupo para el jefe del departamento $departamento, continuando con el siguiente..."
        }
    } else {
        if ($getGg -eq $null) {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "No existe un grupo para el departamento $departamento, creandolo ahora..."

            New-ADGroup -Name $grp -GroupScope Global -Path $ouString -SamAccountName $grp

            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Grupo $grp creado con exito, continuando..."
        } else {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Ya existe un grupo para el departamento $departamento, continuando con el siguiente..."
        }
    }


    #----------------------------------------------#
    # Comprobar si existe el usuario, si no crealo #
    #----------------------------------------------#

    # Variables
    $surName = $apellido1 + " " + $apellido2
    $principalName = $usrName + "@barcelona.lan"
    $passFormat = "Batoi@1234"
    $pass = ConvertTo-SecureString $passFormat -AsPlainText -Force
    $carpPers = "\\barcelona.lan\DatosBarcelona\AdminDominio\CarpPers\" + $usrName

    $getUsr = Get-ADUser -SearchBase $ouString -Filter {SamAccountName -eq $usrName}

    if ($getUsr -eq $null) {
            Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
            Write-Host "No existe el usuario $usrName, creandolo ahora..."
        if ($departamento -eq "Comercial") {
            # Variables
            $homeDirUsr = "\\barcelona.lan\DatosBarcelona\AdminDominio\PerfMov\" + $usrName

            New-ADUser -GivenName $nom -Surname $surName -Name $nom -UserPrincipalName $principalName -DisplayName $displayName -Description $descripcion -Office $departamento -SamAccountName $usrName -AccountPassword $pass -ChangePasswordAtLogon $False -Enabled $True -Path "OU=$departamento,OU=Barcelona,DC=barcelona,DC=lan" -ProfilePath $homeDirUsr -HomeDrive "Z" -HomeDirectory $homeDirUsr
        } else {
            $ObligHomeDir = "\\barcelona.lan\DatosBarcelona\AdminDominio\PerfOblig\"

            New-ADUser -GivenName $nom -Surname $surName -Name $nom -UserPrincipalName $principalName -DisplayName $displayName -Description $descripcion -Office $departamento -SamAccountName $usrName -AccountPassword $pass -ChangePasswordAtLogon $False -Enabled $True -Path "OU=$departamento,OU=Barcelona,DC=barcelona,DC=lan" -ProfilePath $ObligHomeDir -HomeDrive "Z" -HomeDirectory $homeDirUsr
        }

        Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
        Write-Host "Usuario $usrName creado con exito, continuando..."

        Write-Host "[GG] " -ForegroundColor Green -NoNewline
        Write-Host "Agregando usuario $usrName al grupo $grp..."

        # Add to jefe group if necessary
        if ($descripcion -eq "Jefe") {
            $grp = "ggJefe" + $departamento
        }

        Add-ADGroupMember -Identity $grp -Members $usrName

        Write-Host "[GG] " -ForegroundColor Green -NoNewline
        Write-Host "Usuario $usrName agregado al grupo $grp con exito, continuando..."
    } else {
        Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
        Write-Host "Ya existe el usuario $usrName, continuando con el siguiente..."
    }
    }



}
