<#
.SYNOPSIS
    Personaliza la terminal de PowerShell: Oh My Posh, una fuente con iconos y un banner con tu nombre.

.DESCRIPTION
    El script hace, en este orden:
      1. Te pregunta el nombre del banner, el tema y el color.
      2. Instala Oh My Posh con winget (el gestor de paquetes de Windows).
      3. Copia el tema oficial elegido a tu carpeta personal y dibuja tu banner.
      4. Instala la fuente Meslo Nerd Font (lleva los iconos que usan los temas).
      5. Descarga Terminal-Icons: colores e iconos al listar carpetas con ls o dir.
      6. Pone esa fuente en Windows Terminal.
      7. Permite que PowerShell cargue tu perfil (politica de ejecucion).
      8. Anade a tu perfil de PowerShell un bloque que arranca Oh My Posh, Terminal-Icons y el banner.

    No necesita permisos de administrador: todo se instala solo para tu usuario.

.PARAMETER Nombre
    Texto del banner: letras, numeros, espacios, guion, punto y guion bajo.
    Las tildes se quitan (Alvaro con tilde queda ALVARO); la enye se respeta.

.PARAMETER Tema
    Nombre de cualquier tema oficial de Oh My Posh (por ejemplo: dracula). Sin el, sale un menu.

.PARAMETER Color
    Color del banner: Cyan, Green, Magenta, Yellow, Blue, Red o White. Sin el, sale un menu.

.PARAMETER Desinstalar
    Quita el bloque de tus perfiles y la carpeta .terminal-smx.
    No desinstala Oh My Posh ni la fuente.

.PARAMETER Prueba
    Modo ensayo: no instala nada ni toca tu perfil real ni Windows Terminal.
    Todo se escribe en %TEMP%\terminal-smx-prueba para poder revisarlo.

.EXAMPLE
    .\Instalar-Terminal.ps1

.EXAMPLE
    .\Instalar-Terminal.ps1 -Nombre "Marta" -Tema dracula -Color Magenta

.NOTES
    Ciclo SMX - curso 2026-2027.
    Guarda este archivo en UTF-8 SIN BOM: con BOM falla al lanzarlo desde internet con irm.
#>

[CmdletBinding()]
param(
    [string]$Nombre,
    [string]$Tema,
    [string]$Color,
    [switch]$Desinstalar,
    [switch]$Prueba
)

# Si un comando falla, paramos en vez de seguir a ciegas.
$ErrorActionPreference = 'Stop'


# =====================================================================
#  Configuración
# =====================================================================

# Carpeta propia donde guardamos el tema, el banner y tus elecciones.
# $HOME es tu carpeta de usuario (C:\Users\tu_usuario).
$CarpetaSMX = Join-Path $HOME '.terminal-smx'
if ($Prueba) { $CarpetaSMX = Join-Path $env:TEMP 'terminal-smx-prueba' }

# Temas oficiales que salen en el menú. Con -Tema se puede usar cualquier otro.
$TemasMenu = @('jandedobbeleer', 'atomic', 'catppuccin_mocha', 'dracula', 'tokyonight_storm', 'powerlevel10k_rainbow')

# Colores de consola que acepta Write-Host -ForegroundColor.
$ColoresMenu = @('Cyan', 'Green', 'Magenta', 'Yellow', 'Blue', 'Red', 'White')

# Colores ("texto,fondo") con los que se turnan las carpetas de la ruta en el prompt.
$ColoresRuta = @('#1e1e2e,#89b4fa', '#1e1e2e,#a6e3a1', '#1e1e2e,#f9e2af', '#1e1e2e,#f38ba8', '#1e1e2e,#cba6f7', '#1e1e2e,#94e2d5')

# Fuente con iconos (Nerd Font): nombre para "oh-my-posh font install" y nombre que ve Windows.
$FuenteNerd = 'Meslo'
$FuenteCara = 'MesloLGM Nerd Font'

# Terminal-Icons: módulo libre (licencia MIT) que da colores e iconos al listado de ls y dir.
# Fijamos la versión y su huella SHA-256: si el archivo descargado no es idéntico, no se instala.
$IconosVersion = '0.11.0'
$IconosSha256  = '0D5086FBD48B4B12D5C00B1E226393B326B38C3E06DBF8825F522188E9DFE4DD'

# Marcas que rodean nuestro bloque en el perfil: así lo cambiamos o quitamos sin tocar lo demás.
$MarcaInicio = '# >>> TERMINAL SMX >>>'
$MarcaFin    = '# <<< TERMINAL SMX <<<'

# Letras por línea del banner. Cada letra ocupa 6 columnas: 12 letras caben en una ventana de 80.
$MaxLetrasLinea = 12

# Codificaciones de texto. El perfil lleva BOM para que Windows PowerShell 5.1 lo lea bien.
$Utf8SinBom = New-Object System.Text.UTF8Encoding $false
$Utf8ConBom = New-Object System.Text.UTF8Encoding $true


# =====================================================================
#  Tipografía del banner
# =====================================================================
# Cada carácter es un dibujo de 5 filas; al pintar, '#' se cambia por un bloque sólido.
# Todas las filas de un mismo carácter deben medir lo mismo.

$Letras = @{
    'A' = ' ### ', '#   #', '#####', '#   #', '#   #'
    'B' = '#### ', '#   #', '#### ', '#   #', '#### '
    'C' = ' ####', '#    ', '#    ', '#    ', ' ####'
    'D' = '#### ', '#   #', '#   #', '#   #', '#### '
    'E' = '#####', '#    ', '#### ', '#    ', '#####'
    'F' = '#####', '#    ', '#### ', '#    ', '#    '
    'G' = ' ####', '#    ', '#  ##', '#   #', ' ####'
    'H' = '#   #', '#   #', '#####', '#   #', '#   #'
    'I' = '###', ' # ', ' # ', ' # ', '###'
    'J' = '  ###', '   # ', '   # ', '#  # ', ' ##  '
    'K' = '#   #', '#  # ', '###  ', '#  # ', '#   #'
    'L' = '#    ', '#    ', '#    ', '#    ', '#####'
    'M' = '#   #', '## ##', '# # #', '#   #', '#   #'
    'N' = '#   #', '##  #', '# # #', '#  ##', '#   #'
    'O' = ' ### ', '#   #', '#   #', '#   #', ' ### '
    'P' = '#### ', '#   #', '#### ', '#    ', '#    '
    'Q' = ' ### ', '#   #', '# # #', '#  # ', ' ## #'
    'R' = '#### ', '#   #', '#### ', '#  # ', '#   #'
    'S' = ' ####', '#    ', ' ### ', '    #', '#### '
    'T' = '#####', '  #  ', '  #  ', '  #  ', '  #  '
    'U' = '#   #', '#   #', '#   #', '#   #', ' ### '
    'V' = '#   #', '#   #', '#   #', ' # # ', '  #  '
    'W' = '#   #', '#   #', '# # #', '## ##', '#   #'
    'X' = '#   #', ' # # ', '  #  ', ' # # ', '#   #'
    'Y' = '#   #', ' # # ', '  #  ', '  #  ', '  #  '
    'Z' = '#####', '   # ', '  #  ', ' #   ', '#####'
    '0' = ' ### ', '#  ##', '# # #', '##  #', ' ### '
    '1' = ' ## ', '# # ', '  # ', '  # ', '####'
    '2' = '#### ', '    #', ' ### ', '#    ', '#####'
    '3' = '#### ', '    #', ' ### ', '    #', '#### '
    '4' = '#   #', '#   #', '#####', '    #', '    #'
    '5' = '#####', '#    ', '#### ', '    #', '#### '
    '6' = ' ### ', '#    ', '#### ', '#   #', ' ### '
    '7' = '#####', '    #', '   # ', '  #  ', '  #  '
    '8' = ' ### ', '#   #', ' ### ', '#   #', ' ### '
    '9' = ' ### ', '#   #', ' ####', '    #', ' ### '
    ' ' = '  ', '  ', '  ', '  ', '  '
    '-' = '    ', '    ', '####', '    ', '    '
    '.' = ' ', ' ', ' ', ' ', '#'
    '_' = '     ', '     ', '     ', '     ', '#####'
}

# La eñe mayúscula se añade con su código Unicode (U+00D1) en lugar de escribirla:
# Windows PowerShell 5.1 lee los .ps1 sin BOM como ANSI y ese byte lo tomaría por una comilla.
$Letras[[string][char]0x00D1] = '#####', '##  #', '# # #', '#  ##', '#   #'


# =====================================================================
#  Mensajes en pantalla
# =====================================================================

function Write-Paso {
    param([int]$Numero, [int]$Total, [string]$Texto)
    Write-Host ''
    Write-Host "[$Numero/$Total] $Texto" -ForegroundColor Cyan
}

function Write-Ok    { param([string]$Texto) Write-Host "      [OK] $Texto" -ForegroundColor Green }
function Write-Aviso { param([string]$Texto) Write-Host "      [!]  $Texto" -ForegroundColor Yellow }


# =====================================================================
#  Banner
# =====================================================================

function ConvertTo-NombreLimpio {
    # Pasa el texto a mayúsculas, quita tildes y descarta lo que la tipografía no sabe dibujar.
    param([string]$Texto)

    $enie = [char]0x00D1
    $marca = [char]1

    # 1) Mayúsculas y la eñe apartada: la normalización la separaría en N + virgulilla.
    $t = $Texto.Trim().ToUpper().Replace([string]$enie, [string]$marca)

    # 2) FormD separa cada letra de su tilde (Á = A + ´); luego tiramos las tildes sueltas.
    $t = $t.Normalize([Text.NormalizationForm]::FormD)

    $limpio = New-Object System.Text.StringBuilder
    foreach ($c in $t.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -eq 'NonSpacingMark') { continue }
        if ($c -eq $marca) { $c = $enie }
        if ($Letras.ContainsKey([string]$c)) { [void]$limpio.Append($c) }
    }

    # 3) Un solo espacio entre palabras.
    return ($limpio.ToString() -replace '\s+', ' ').Trim()
}

function Split-LineasBanner {
    # Reparte las palabras en líneas de como mucho $MaxLetrasLinea caracteres.
    param([string]$Texto)

    $lineas = New-Object System.Collections.Generic.List[string]
    $actual = ''
    foreach ($palabra in $Texto.Split(' ')) {
        # Una palabra demasiado larga se corta en trozos.
        while ($palabra.Length -gt $MaxLetrasLinea) {
            if ($actual) { $lineas.Add($actual); $actual = '' }
            $lineas.Add($palabra.Substring(0, $MaxLetrasLinea))
            $palabra = $palabra.Substring($MaxLetrasLinea)
        }
        if (-not $palabra) { continue }

        if (-not $actual) { $actual = $palabra }
        elseif (($actual.Length + 1 + $palabra.Length) -le $MaxLetrasLinea) { $actual += " $palabra" }
        else { $lineas.Add($actual); $actual = $palabra }
    }
    if ($actual) { $lineas.Add($actual) }
    return $lineas.ToArray()
}

function New-Banner {
    # Dibuja el texto con la tipografía $Letras y devuelve el dibujo como un único texto.
    param([string]$Texto)

    $bloque = [string][char]0x2588   # carácter de bloque sólido
    $filas = New-Object System.Collections.Generic.List[string]

    foreach ($linea in @(Split-LineasBanner $Texto)) {
        for ($fila = 0; $fila -lt 5; $fila++) {
            # Tomamos la fila $fila de cada letra y las unimos con un espacio de separación.
            $trozos = foreach ($c in $linea.ToCharArray()) { $Letras[[string]$c][$fila] }
            $filas.Add('  ' + ((@($trozos) -join ' ').Replace('#', $bloque)).TrimEnd())
        }
        $filas.Add('')
    }
    return ($filas -join "`r`n").TrimEnd()
}


# =====================================================================
#  Preguntas al alumno
# =====================================================================

function Read-Opcion {
    # Muestra una lista numerada y devuelve la posición elegida (empezando en 0).
    param([string]$Pregunta, [string[]]$Opciones, [switch]$PintarConColor)

    Write-Host ''
    Write-Host "      $Pregunta"
    for ($i = 0; $i -lt $Opciones.Count; $i++) {
        $linea = '        {0}) {1}' -f ($i + 1), $Opciones[$i]
        if ($PintarConColor) { Write-Host $linea -ForegroundColor $Opciones[$i] }
        else { Write-Host $linea }
    }
    while ($true) {
        $respuesta = Read-Host '      Número (Intro = 1)'
        if (-not $respuesta) { return 0 }
        $n = 0
        if ([int]::TryParse($respuesta, [ref]$n) -and $n -ge 1 -and $n -le $Opciones.Count) { return $n - 1 }
        Write-Aviso "Escribe un número del 1 al $($Opciones.Count)."
    }
}

function Read-DatosAlumno {
    # Reúne nombre, tema y color. Lo que llega por parámetro no se pregunta la primera vez.
    $preguntar = -not ($Nombre -and $Tema -and $Color)
    $primeraVez = $true

    do {
        # --- Nombre
        $textoBanner = ''
        if ($primeraVez -and $Nombre) {
            $textoBanner = ConvertTo-NombreLimpio $Nombre
            if (-not $textoBanner) { throw "El nombre '$Nombre' no tiene nada que se pueda dibujar." }
        }
        while (-not $textoBanner) {
            Write-Host ''
            $entrada = Read-Host '      Escribe tu nombre o apodo para el banner'
            $textoBanner = ConvertTo-NombreLimpio $entrada
            if (-not $textoBanner) { Write-Aviso 'Usa letras, números, espacios, guion, punto o guion bajo.' }
        }

        # --- Tema
        if ($primeraVez -and $Tema) {
            # Solo letras, números, punto, guion y guion bajo: evita rutas como ..\..\algo
            if ($Tema -notmatch '^[\w.-]+$') { throw "Nombre de tema no válido: $Tema" }
            $temaElegido = $Tema
        }
        else {
            $temaElegido = $TemasMenu[(Read-Opcion '¿Qué tema quieres?' $TemasMenu)]
        }

        # --- Color
        if ($primeraVez -and $Color) {
            $colorElegido = $ColoresMenu | Where-Object { $_ -eq $Color } | Select-Object -First 1
            if (-not $colorElegido) { throw "Color no válido: $Color. Usa uno de estos: $($ColoresMenu -join ', ')" }
        }
        else {
            $colorElegido = $ColoresMenu[(Read-Opcion '¿De qué color quieres el banner?' $ColoresMenu -PintarConColor)]
        }

        # --- Vista previa
        $confirmado = $true
        if ($preguntar) {
            Write-Host ''
            Write-Host (New-Banner $textoBanner) -ForegroundColor $colorElegido
            Write-Host ''
            $respuesta = Read-Host "      Tema: $temaElegido. ¿Lo dejamos así? (S/n)"
            $confirmado = $respuesta -notmatch '^[nN]'
        }
        $primeraVez = $false
    } until ($confirmado)

    return [pscustomobject]@{ Texto = $textoBanner; Tema = $temaElegido; Color = $colorElegido }
}


# =====================================================================
#  Localizar programas y rutas
# =====================================================================

function Get-Winget {
    $cmd = Get-Command winget -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    # A veces winget está instalado pero su carpeta no está en el PATH de esta ventana.
    $alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path $alias) { return $alias }
    return $null
}

function Get-OhMyPosh {
    $cmd = Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    $candidatos = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\oh-my-posh.exe'),     # versión de la tienda (MSIX)
        (Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\bin\oh-my-posh.exe')    # instalador clásico
    )
    foreach ($ruta in $candidatos) { if (Test-Path $ruta) { return $ruta } }
    return $null
}

function Get-CarpetaTemas {
    # Los temas oficiales vienen dentro de Oh My Posh, pero su carpeta cambia con cada versión.
    if ($env:POSH_THEMES_PATH -and (Test-Path $env:POSH_THEMES_PATH)) { return $env:POSH_THEMES_PATH }

    $ubicacion = $null
    try {
        $paquete = Get-AppxPackage -Name 'ohmyposh.cli' -ErrorAction Stop | Sort-Object Version -Descending | Select-Object -First 1
        if ($paquete) { $ubicacion = $paquete.InstallLocation }
    }
    catch {
        # En PowerShell 7 Get-AppxPackage puede fallar: se lo preguntamos a Windows PowerShell.
        $ubicacion = & powershell.exe -NoProfile -Command "(Get-AppxPackage -Name ohmyposh.cli | Select-Object -First 1).InstallLocation"
    }
    if ($ubicacion) {
        $temas = Join-Path $ubicacion 'themes'
        if (Test-Path $temas) { return $temas }
    }

    $clasico = Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\themes'
    if (Test-Path $clasico) { return $clasico }
    return $null
}

function Get-RutasPerfil {
    # Un perfil es un script que PowerShell ejecuta cada vez que abres una ventana.
    # Windows PowerShell 5.1 y PowerShell 7 usan archivos distintos: configuramos los dos.
    $documentos = [Environment]::GetFolderPath('MyDocuments')   # respeta Documentos en OneDrive
    if ($Prueba) { $documentos = $CarpetaSMX }
    return @(
        (Join-Path $documentos 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path $documentos 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )
}

function Test-FuenteInstalada {
    param([string]$Cara)
    # Windows apunta las fuentes en el registro: HKCU para tu usuario, HKLM para todo el equipo.
    $claves = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
              'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    foreach ($clave in $claves) {
        $valores = Get-ItemProperty -Path $clave -ErrorAction SilentlyContinue
        if ($valores -and ($valores.PSObject.Properties.Name -like "$Cara*")) { return $true }
    }
    return $false
}


# =====================================================================
#  Cambios en el sistema
# =====================================================================

function Install-TerminalIcons {
    # Descarga el módulo de la PowerShell Gallery y lo deja dentro de nuestra carpeta.
    # No usamos Install-Module: en Windows PowerShell 5.1 pide instalar NuGet y confirmar la galería.
    $destino = Join-Path $CarpetaSMX 'modulos\Terminal-Icons'
    $manifiesto = Join-Path $destino 'Terminal-Icons.psd1'
    if ((Test-Path $manifiesto) -and ((Import-PowerShellDataFile $manifiesto).ModuleVersion -eq $IconosVersion)) {
        Write-Ok "Ya estaba instalado (versión $IconosVersion)."
        return
    }

    # La galería solo acepta TLS 1.2; Windows PowerShell 5.1 a veces intenta protocolos más antiguos.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    # La barra de progreso hace la descarga muchísimo más lenta en 5.1.
    $ProgressPreference = 'SilentlyContinue'

    # Un paquete .nupkg es un .zip con otro nombre, y Expand-Archive solo acepta la extensión .zip.
    $zip = Join-Path $env:TEMP "Terminal-Icons.$IconosVersion.zip"
    Write-Host '      Descargando de la PowerShell Gallery...'
    Invoke-WebRequest "https://www.powershellgallery.com/api/v2/package/Terminal-Icons/$IconosVersion" -OutFile $zip -UseBasicParsing

    # La huella SHA-256 cambia por completo si cambia un solo byte del archivo.
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $IconosSha256) {
        Remove-Item $zip -Force
        throw 'La huella SHA-256 no coincide: el archivo descargado no es el esperado.'
    }

    if (Test-Path $destino) { Remove-Item $destino -Recurse -Force }
    Expand-Archive $zip $destino -Force
    Remove-Item $zip -Force

    # Quitamos lo que solo le sirve al gestor de paquetes.
    foreach ($sobra in '_rels', 'package', '[Content_Types].xml', 'Terminal-Icons.nuspec') {
        Remove-Item -LiteralPath (Join-Path $destino $sobra) -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Ok "Instalado en $destino"
}

function Set-ColorRutaIconos {
    # Terminal-Icons pinta los nombres, pero la cabecera "Directorio: C:\..." sale sin color.
    # Retocamos su archivo de formato: antes del texto emite el color guardado en
    # $global:ColorRutaSMX (lo define el perfil) y al final de la ruta vuelve al color normal.
    $formato = Join-Path $CarpetaSMX 'modulos\Terminal-Icons\Terminal-Icons.format.ps1xml'
    if (-not (Test-Path $formato)) { return }
    $xml = [IO.File]::ReadAllText($formato)
    if ($xml.Contains('ColorRutaSMX')) { Write-Ok 'La ruta de las carpetas ya sale en color.'; return }

    $texto = '<Text AssemblyName="System.Management.Automation" BaseName="FileSystemProviderStrings" ResourceId="DirectoryDisplayGrouping"/>'
    $ruta  = '$_.PSParentPath.Replace("Microsoft.PowerShell.Core\FileSystem::", "")'
    if (-not ($xml.Contains($texto) -and $xml.Contains($ruta))) {
        Write-Aviso 'No reconozco el formato de Terminal-Icons: la ruta de las carpetas saldra sin color.'
        return
    }
    # [char]27 es ESC: con el codigo que le sigue, la terminal cambia de color (secuencias ANSI).
    $inicio = '<ExpressionBinding><ScriptBlock>if ($global:ColorRutaSMX) { $global:ColorRutaSMX }</ScriptBlock></ExpressionBinding>'
    $fin    = ' + $(if ($global:ColorRutaSMX) { [string][char]27 + ''[0m'' })'
    $xml = $xml.Replace($texto, $inicio + $texto).Replace($ruta, $ruta + $fin)
    [IO.File]::WriteAllText($formato, $xml, $Utf8SinBom)
    Write-Ok 'La ruta de las carpetas saldra en el color del banner.'
}

function Copy-TemaConRutaEnColores {
    # Copia el tema oficial cambiando su segmento "path" (la ruta del prompt):
    # muestra la ruta entera y pinta cada carpeta con un color distinto, para ver bien cada nivel.
    param([string]$Origen, [string]$Destino)

    $tema = [IO.File]::ReadAllText($Origen) | ConvertFrom-Json
    foreach ($bloque in @($tema.blocks)) {
        foreach ($segmento in @($bloque.segments)) {
            if ($segmento.type -ne 'path') { continue }
            # Las versiones nuevas de Oh My Posh llaman "options" a lo que antes era "properties".
            $nombre = 'options'
            if ($segmento.PSObject.Properties['properties']) { $nombre = 'properties' }
            if (-not $segmento.PSObject.Properties[$nombre]) {
                $segmento | Add-Member -NotePropertyName $nombre -NotePropertyValue ([pscustomobject]@{})
            }
            $opciones = $segmento.$nombre
            # "full" = ruta completa; "cycle" = lista de colores "texto,fondo" que se van turnando por carpeta.
            $opciones | Add-Member -Force -NotePropertyName style -NotePropertyValue 'full'
            $opciones | Add-Member -Force -NotePropertyName cycle -NotePropertyValue $ColoresRuta
        }
    }
    [IO.File]::WriteAllText($Destino, ($tema | ConvertTo-Json -Depth 32), $Utf8SinBom)
}

function Set-FuenteWindowsTerminal {
    $rutas = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    ) | Where-Object { Test-Path $_ }

    if (-not $rutas) {
        Write-Aviso 'No encuentro Windows Terminal, o aún no se ha abierto nunca.'
        Write-Aviso "Ábrelo una vez y vuelve a ejecutar, o pon a mano la fuente '$FuenteCara'."
        return
    }

    $n = 0
    foreach ($ruta in $rutas) {
        $n++
        if ($Prueba) {
            # En modo prueba trabajamos sobre una copia.
            $copia = Join-Path $CarpetaSMX "windows-terminal-$n.json"
            Copy-Item $ruta $copia -Force
            $ruta = $copia
        }

        try { $ajustes = [IO.File]::ReadAllText($ruta) | ConvertFrom-Json }
        catch {
            # Windows PowerShell 5.1 no entiende los comentarios // que a veces lleva este archivo.
            Write-Aviso "No puedo leer $ruta (¿tiene comentarios?). Pon la fuente '$FuenteCara' a mano."
            continue
        }
        if ($ajustes.profiles -is [array]) {
            Write-Aviso "Formato antiguo de Windows Terminal. Pon la fuente '$FuenteCara' a mano."
            continue
        }

        # profiles.defaults.font.face se aplica a todas las pestañas que no tengan su propia fuente.
        if (-not $ajustes.profiles.PSObject.Properties['defaults']) {
            $ajustes.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{})
        }
        $defecto = $ajustes.profiles.defaults
        if (-not $defecto.PSObject.Properties['font']) {
            $defecto | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{})
        }
        if ($defecto.font.PSObject.Properties['face']) { $defecto.font.face = $FuenteCara }
        else { $defecto.font | Add-Member -NotePropertyName face -NotePropertyValue $FuenteCara }

        if (-not $Prueba) { Copy-Item $ruta "$ruta.bak-smx" -Force }
        [IO.File]::WriteAllText($ruta, ($ajustes | ConvertTo-Json -Depth 32), $Utf8SinBom)
        Write-Ok "Fuente puesta en $ruta"
    }
}

function New-BloquePerfil {
    # Código que se copiará en el perfil. Va entre comillas simples (@' '@) para que
    # PowerShell no sustituya ahora las variables: deben evaluarse al abrir la terminal.
    $codigo = @'
# Bloque creado por Instalar-Terminal.ps1 (SMX). Para quitarlo, ejecuta DESINSTALAR.bat.
$TerminalSMX = __CARPETA__
if (Test-Path (Join-Path $TerminalSMX 'config.json')) {
    $configSMX = Get-Content (Join-Path $TerminalSMX 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $temaSMX = Join-Path $TerminalSMX 'tema.omp.json'
    if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $temaSMX)) {
        $shellSMX = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
        (@(& oh-my-posh init $shellSMX --config $temaSMX) -join "`n") | Invoke-Expression
    }
    $iconosSMX = Join-Path $TerminalSMX 'modulos\Terminal-Icons\Terminal-Icons.psd1'
    if (Test-Path $iconosSMX) { Import-Module $iconosSMX }
    $colorSMX = 'Cyan'
    if ([enum]::IsDefined([ConsoleColor], [string]$configSMX.color)) { $colorSMX = [string]$configSMX.color }
    $ansiSMX = @{ Cyan = 96; Green = 92; Magenta = 95; Yellow = 93; Blue = 94; Red = 91; White = 97 }
    if ($ansiSMX.ContainsKey($colorSMX)) { $global:ColorRutaSMX = [string][char]27 + "[$($ansiSMX[$colorSMX])m" }
    Clear-Host
    Write-Host ''
    Write-Host (Get-Content (Join-Path $TerminalSMX 'banner.txt') -Raw -Encoding UTF8) -ForegroundColor $colorSMX
    Write-Host ''
}
'@
    # La ruta va entre comillas simples; una comilla dentro del nombre de usuario se escribe doble.
    $rutaLiteral = "'" + $CarpetaSMX.Replace("'", "''") + "'"
    return $MarcaInicio + "`r`n" + $codigo.Replace('__CARPETA__', $rutaLiteral) + "`r`n" + $MarcaFin
}

function Set-BloquePerfil {
    # Pone (o quita, si $Bloque va vacío) nuestro bloque sin tocar el resto del perfil.
    param([string]$Ruta, [string]$Bloque)

    $contenido = ''
    if (Test-Path $Ruta) {
        $contenido = [IO.File]::ReadAllText($Ruta)
        $copia = "$Ruta.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item $Ruta $copia
    }
    else {
        New-Item -ItemType Directory -Force -Path (Split-Path $Ruta) | Out-Null
    }

    # Quitamos el bloque anterior, si lo había.
    $patron = '(?s)' + [regex]::Escape($MarcaInicio) + '.*?' + [regex]::Escape($MarcaFin) + '\r?\n?'
    $contenido = [regex]::Replace($contenido, $patron, '').TrimEnd()

    if ($contenido -match 'oh-my-posh') {
        Write-Aviso "Tu perfil ya arrancaba Oh My Posh por otro lado; revisa $Ruta"
    }

    if ($Bloque) {
        if ($contenido) { $contenido += "`r`n`r`n" }
        $contenido += $Bloque + "`r`n"
    }
    [IO.File]::WriteAllText($Ruta, $contenido, $Utf8ConBom)
}


# =====================================================================
#  Instalación y desinstalación
# =====================================================================

function Invoke-Instalacion {
    $total = 8

    Write-Host ''
    Write-Host (New-Banner 'SMX') -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Personaliza tu terminal de PowerShell'
    if ($Prueba) { Write-Aviso "Modo prueba: no se instala nada; todo va a $CarpetaSMX" }

    # --- 1. Datos
    Write-Paso 1 $total 'Tus datos'
    $datos = Read-DatosAlumno
    Write-Ok "Banner: $($datos.Texto) | Tema: $($datos.Tema) | Color: $($datos.Color)"

    # --- 2. Oh My Posh
    Write-Paso 2 $total 'Oh My Posh'
    $omp = Get-OhMyPosh
    if ($omp) {
        Write-Ok "Ya estaba instalado: $omp"
    }
    elseif ($Prueba) {
        Write-Aviso 'No está instalado y en modo prueba no se instala.'
    }
    else {
        $winget = Get-Winget
        if (-not $winget) { throw 'No encuentro winget. Actualiza «Instalador de aplicación» en Microsoft Store y repite.' }
        Write-Host '      Instalando con winget; puede tardar un par de minutos...'
        & $winget install --id JanDeDobbeleer.OhMyPosh --exact --source winget --silent --accept-package-agreements --accept-source-agreements
        # $LASTEXITCODE guarda el código con el que terminó el último programa externo (0 = bien).
        if ($LASTEXITCODE -ne 0) { throw "winget terminó con el código $LASTEXITCODE." }
        $omp = Get-OhMyPosh
        if (-not $omp) { throw 'winget ha terminado, pero no encuentro oh-my-posh. Cierra la ventana y vuelve a ejecutar.' }
        Write-Ok 'Instalado.'
    }

    # --- 3. Tema y banner
    Write-Paso 3 $total 'Tema y banner'
    New-Item -ItemType Directory -Force -Path $CarpetaSMX | Out-Null
    $carpetaTemas = Get-CarpetaTemas
    if (-not $carpetaTemas) {
        if ($Prueba) { Write-Aviso 'No encuentro los temas de Oh My Posh.' }
        else { throw 'No encuentro los temas de Oh My Posh.' }
    }
    else {
        $origen = Join-Path $carpetaTemas "$($datos.Tema).omp.json"
        if (-not (Test-Path $origen)) { throw "El tema '$($datos.Tema)' no existe. Los disponibles están en: $carpetaTemas" }
        Copy-TemaConRutaEnColores -Origen $origen -Destino (Join-Path $CarpetaSMX 'tema.omp.json')
        Write-Ok "Tema copiado a $CarpetaSMX\tema.omp.json"
    }
    [IO.File]::WriteAllText((Join-Path $CarpetaSMX 'banner.txt'), (New-Banner $datos.Texto), $Utf8SinBom)
    $config = [ordered]@{
        nombre = $datos.Texto
        tema   = $datos.Tema
        color  = $datos.Color
        fecha  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
    }
    [IO.File]::WriteAllText((Join-Path $CarpetaSMX 'config.json'), ($config | ConvertTo-Json), $Utf8SinBom)
    Write-Ok 'Banner y configuración guardados.'

    # --- 4. Fuente
    Write-Paso 4 $total "Fuente $FuenteCara"
    if (Test-FuenteInstalada $FuenteCara) {
        Write-Ok 'Ya estaba instalada.'
    }
    elseif ($Prueba) {
        Write-Aviso 'No está instalada y en modo prueba no se instala.'
    }
    else {
        & $omp font install $FuenteNerd
        if ($LASTEXITCODE -ne 0) { throw "oh-my-posh no pudo instalar la fuente (código $LASTEXITCODE)." }
        Write-Ok 'Instalada.'
    }

    # --- 5. Colores e iconos al listar
    Write-Paso 5 $total 'Colores e iconos al listar carpetas (Terminal-Icons)'
    try {
        Install-TerminalIcons
        Set-ColorRutaIconos
    }
    catch {
        # No es imprescindible: si falla (sin internet, proxy del centro...) seguimos con lo demás.
        Write-Aviso "No se ha podido instalar: $($_.Exception.Message)"
        Write-Aviso 'La terminal funcionará igual, pero ls saldrá sin colores.'
    }

    # --- 6. Windows Terminal
    Write-Paso 6 $total 'Windows Terminal'
    Set-FuenteWindowsTerminal

    # --- 7. Política de ejecución
    Write-Paso 7 $total 'Permiso para cargar el perfil'
    # Con la política "Restricted" (la de fábrica en Windows) PowerShell no ejecuta el perfil.
    # "RemoteSigned" permite scripts creados en tu equipo y exige firma a los descargados.
    $politica = Get-ExecutionPolicy
    if ($politica -in 'RemoteSigned', 'Unrestricted', 'Bypass') {
        Write-Ok "La política actual ya lo permite ($politica)."
    }
    elseif ($Prueba) {
        Write-Aviso "Política actual: $politica. En modo prueba no se cambia."
    }
    else {
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Ok 'Política RemoteSigned para tu usuario.'
        }
        catch {
            Write-Aviso "No se ha podido cambiar: $($_.Exception.Message)"
            Write-Aviso 'Puede que la bloquee el centro. Avisa al profesor.'
        }
    }

    # --- 8. Perfil
    Write-Paso 8 $total 'Perfil de PowerShell'
    $bloque = New-BloquePerfil
    foreach ($ruta in Get-RutasPerfil) {
        Set-BloquePerfil -Ruta $ruta -Bloque $bloque
        Write-Ok $ruta
    }

    Write-Host ''
    Write-Host '  Terminado. Cierra esta ventana y abre Windows Terminal para ver tu terminal nueva.' -ForegroundColor Green
    if ($Prueba) { Write-Host "  (Modo prueba: revisa los archivos en $CarpetaSMX)" -ForegroundColor Yellow }
}

function Invoke-Desinstalacion {
    Write-Paso 1 2 'Quitar el bloque de tus perfiles'
    foreach ($ruta in Get-RutasPerfil) {
        if ((Test-Path $ruta) -and [IO.File]::ReadAllText($ruta).Contains($MarcaInicio)) {
            Set-BloquePerfil -Ruta $ruta -Bloque ''
            Write-Ok "Quitado de $ruta (hay copia .bak junto a él)"
        }
    }

    Write-Paso 2 2 'Borrar la carpeta .terminal-smx'
    if (Test-Path $CarpetaSMX) {
        Remove-Item $CarpetaSMX -Recurse -Force
        Write-Ok "Borrada $CarpetaSMX"
    }
    else {
        Write-Ok 'No existía.'
    }

    Write-Host ''
    Write-Host '  Hecho. Oh My Posh y la fuente siguen instalados; para quitarlos:' -ForegroundColor Green
    Write-Host '    winget uninstall JanDeDobbeleer.OhMyPosh'
    Write-Host '    y borra la fuente desde Configuración > Personalización > Fuentes.'
}


# =====================================================================
#  Programa principal
# =====================================================================

try {
    if ($Desinstalar) { Invoke-Desinstalacion }
    else { Invoke-Instalacion }
}
catch {
    Write-Host ''
    Write-Host "  [X] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '      No se ha completado. Corrige el problema y vuelve a ejecutar.' -ForegroundColor Red
}
