require 'sinatra'
require 'httparty'
require 'redis'
require 'json'

set :bind, '0.0.0.0'

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
end

def redis_client
  @redis ||= Redis.new(host: 'redis', port: 6379)
end

get '/api/quotes' do
  content_type :json
  
  # 1. Tenta buscar os dados unificados no cache do Redis
  begin
    cached_data = redis_client.get('market_quotes')
    return cached_data if cached_data
  rescue => e
    puts "Aviso do Redis: #{e.message}"
  end

  # Lista de ativos exigidos divididos um por um
  # Já incluí seu token pessoal ativo!
  tickers = ['USDBRL=X', 'LWSA3', '%5EBVSP']
  combined_results = []

  # 2. Faz um loop buscando um ativo de cada vez para respeitar o plano gratuito da API
  tickers.each do |ticker|
    url = "https://brapi.dev/api/quote/#{ticker}?token=npSbe4r7nY3hndoCSpKGry"
    begin
      response = HTTParty.get(url, verify: false, timeout: 5)
      if response.success?
        data = JSON.parse(response.body)
        # Se a API retornou o resultado correto, extrai o primeiro item da lista deles
        if data && data['results'] && data['results'][0]
          combined_results << data['results'][0]
        end
      end
    rescue => e
      puts "Erro ao buscar ativo #{ticker}: #{e.message}"
    end
  end

  # 3. Se conseguimos pegar os dados, empacota tudo no formato que o Vue espera receber
  if combined_results.any?
    final_payload = { results: combined_results }.to_json
    
    # Salva no Redis por 30 segundos para não estourar seu limite diário de requisições
    begin
      redis_client.setex('market_quotes', 30, final_payload)
    rescue
    end

    return final_payload
  else
    status 502
    return { error: "Não foi possível obter nenhuma cotação da API externa." }.to_json
  end
end

get '/swagger' do
  content_type :json
  {
    openapi: "3.0.0",
    info: { title: "API de Cotações Locaweb", version: "1.0.0" },
    paths: {
      "/api/quotes": {
        get: {
          summary: "Retorna cotações de IBOV, LWSA3 e Dólar",
          responses: { "200": { description: "Sucesso" } }
        }
      }
    }
  }.to_json
end