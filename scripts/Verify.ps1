param([ValidateRange(1, 20)][int]$Runs = 5)

$ErrorActionPreference = 'Stop'
$projectFolder = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$reportsFolder = Join-Path $projectFolder 'reports'
New-Item -ItemType Directory -Path $reportsFolder -Force | Out-Null
$verification = [Collections.Generic.List[string]]::new()

for ($run = 1; $run -le $Runs; $run++) {
    $output = @(& dotnet run --project $projectFolder --no-build)
    if ($LASTEXITCODE -ne 0) { throw "Запуск $run завершився з помилкою." }
    if ($run -eq 1) { $output | Set-Content -LiteralPath (Join-Path $reportsFolder 'run-output.txt') -Encoding utf8 }
    if ($output.Count -ne 6) { throw 'Неочікувана структура виводу.' }
    if ($output[0] -notmatch '^Основний масив: (.+)$') { throw 'Не знайдено fullArray.' }
    $sourceValues = @($Matches[1] -split ', ' | ForEach-Object { [int]$_ })
    $evenValues = @($output[2] -split ', ' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    $oddValues = @($output[4] -split ', ' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })

    if ($sourceValues.Count -ne 1000) { throw 'Масив має містити 1000 елементів.' }
    foreach ($value in $sourceValues) { if ($value -lt 1 -or $value -gt 10) { throw 'Елемент поза межами 1..10.' } }
    foreach ($value in $evenValues) { if ($value % 2 -ne 0) { throw 'У evenList є непарне число.' } }
    foreach ($value in $oddValues) { if ($value % 2 -ne 1) { throw 'У oddList є парне число.' } }
    if ($evenValues.Count + $oddValues.Count -ne 1000) { throw 'Сума довжин списків не дорівнює 1000.' }
    if ($output[1] -cne "Парні елементи ($($evenValues.Count)):") { throw 'Неправильний лічильник парних.' }
    if ($output[3] -cne "Непарні елементи ($($oddValues.Count)):") { throw 'Неправильний лічильник непарних.' }
    if ($output[5] -cne 'Усього розподілено: 1000.') { throw 'Неправильний підсумок.' }

    # Порівняння частот виявляє втрати та зайве додавання навіть за однакової загальної кількості.
    $frequencies = New-Object 'int[]' 11
    foreach ($value in $sourceValues) { $frequencies[$value]++ }
    foreach ($value in @($evenValues) + @($oddValues)) {
        if ($value -lt 1 -or $value -gt 10) { throw 'Зайве значення в результатах.' }
        $frequencies[$value]--
    }
    foreach ($frequency in $frequencies) { if ($frequency -ne 0) { throw 'Частоти значень не збігаються.' } }
    $verification.Add("PASS: запуск $run — fullArray=1000; evenList=$($evenValues.Count); oddList=$($oddValues.Count); діапазон, парність і частоти правильні.")
}
$verification.Add("Успішно запусків: $Runs/$Runs.")
$verification | Set-Content -LiteralPath (Join-Path $reportsFolder 'verification.txt') -Encoding utf8
$verification
