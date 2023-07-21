#!/bin/bash

rm anne-log.txt

# Define a chave da API da OpenAI
OPENAI_KEY="<key>"

# Função para logar o erro
log_error() {
    local error_message="$1"
    local api_response="$2"
    local log_date=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[ERROR][$log_date] $error_message" >> "$log_file"
    echo "API Response: $api_response" >> "$log_file"
}

# Função para obter o gênero usando a API da OpenAI
get_gender() {
    local first_name="$1"

    local gender=$(curl -s -X POST "https://api.openai.com/v1/engines/text-davinci-003/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_KEY" \
        -d "{\"prompt\": \"Is the name $first_name more likely to be male, female, or undetermined? (Response should only be Masculino, Feminino or Indefinido, dont return anything else and the context is Brazil population whatsapp accoutns)\", \"max_tokens\": 20, \"stop\": [\".\"]}")

    # Remove all occurrences of '\n' from the curl response
    gender=$(echo "$gender" | tr -d '\n')
    gender=$(echo "$gender" | tr -d '\n\n')
    # Extract the gender from the API response using grep with Perl-compatible regular expressions
    local gender_result=$(echo "$gender" | grep -o -P "(?<=\\n)?(Masculino|Feminino|Indefinido)")

    # Check if the gender_result is valid (Masculino, Feminino, or Indefinido)
    if [[ "$gender_result" == "Masculino" || "$gender_result" == "Feminino" || "$gender_result" == "Indefinido" ]]; then
        echo "$gender_result"
    else
        echo "Erro API"
    fi
}


# Define o nome do arquivo de entrada e de saída
input_file="original.csv"
output_file="revisado.csv"
log_file="log.txt"

# Inicializa variável para contar linhas processadas
lines_processed=0

# Loop para analisar linha a linha do arquivo de entrada (ignorando a primeira linha com os nomes das colunas)
{
  echo "telefone,sobrenome,primeiro-nome,gênero"
  tail -n +2 "$input_file" | while IFS=',' read -r telefone sobrenome primeiro_nome; do
    # Tenta obter o gênero usando a API da OpenAI
    genero=$(get_gender "$primeiro_nome")

    # Adiciona a linha no novo arquivo CSV com a coluna "gênero" preenchida
    echo "$telefone,$sobrenome,$primeiro_nome,$genero"
    
    # Incrementa o contador de linhas processadas
    ((lines_processed++))

    # Aguarda 1 segundo a cada 100 linhas processadas para respeitar o rate limit da API
    if ((lines_processed % 100 == 0)); then
      echo "Processado $lines_processed linhas..."
      sleep 1
    fi
  done
} > "$output_file"

# Loga o status do processamento no arquivo de log
echo "Processamento concluído. Total de linhas processadas: $lines_processed" >> "$log_file"

# Return the whole file
cat "$output_file"
