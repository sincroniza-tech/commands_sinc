# frozen_string_literal: true

require_relative "commands_sinc/version"

module CommandsSinc
  class Error < StandardError; end
  class ExcelImporter
    def initialize(file_path)
      read_excel_file(file_path)
    end
  end

  class ContactsConfirmation
    def initialize

    end
  end

  private

  def make_http_request(url, data, success_counter, error_counter, invalid_contacts, token)
    response = HTTParty.post(url, body: data.to_json, headers: { 'Content-Type' => 'application/json', 'Authorization' => token })
  end

  def setup_database_connection

    ActiveRecord::Base.establish_connection(
    adapter:  'postgresql',
    host:     'rds-recept.c4nynpwsf0ai.us-east-1.rds.amazonaws.com',
    database: 'api_sinc',
    user:     'Admin_DB_RCPT',
    password: ENV['SINC_DATABASE_PASSWORD'],
    )
  end

  def generate_token(company_number)

    account = Account.where("whatsapp ILIKE ?", "%#{company_number}%")
    public_id = account.ids

    body = { public_id: public_id }.to_json
    token_response = HTTParty.post("#{BASE_URL}/sessions", body: body, headers: { 'Content-Type' => 'application/json' })


    binding.pry if token_response.code == 500

    response_body = JSON.parse(token_response.body)
    "Bearer #{response_body['token']}"
  end
  # Your code goes here...
end


def read_excel_file(file_path)
  excel = Roo::Spreadsheet.open(file_path)
  sheet = excel.sheet(0) # assuming the data is on the first sheet

  data = []
  sheet.each_row_streaming(pad_cells: true) do |row|
    name = row[0]&.value
    ddd = row[1]&.value
    number = row[2]&.value

    next if name.nil? || ddd.nil? || number.nil? # Skip the row if any of the required fields are missing

    formatted_data = {
      number: "+55#{ddd}#{number}",
      name: name,
      channel: "qQOV"
    }

    data << formatted_data
  end

  data
end

def make_http_request(url, data, success_counter, error_counter, invalid_contacts, token)
  response = HTTParty.post(url, body: data.to_json, headers: { 'Content-Type' => 'application/json', 'Authorization' => token })

  if response.success?
    success_counter.increment
    puts "HTTP request successful!"
    puts "Response body: #{response.body}"
    puts "Estamos em #{success_counter.value}"
  elsif response.code == 500 || response.body.include?('invalid_wpp')
    error_counter.increment
    puts "Número de WhatsApp inválido. Atualizando planilha..."


    update_excel_file(data)
    if error_counter.value >= 10 && success_counter.value >= 10
      error_counter.value = 0 # Reset error counter
      invalid_contacts << data # Guarda a request com erro 500 na array
      puts "Erro 500. Guardando request para reenvio posterior."
    end
  elsif response.code == 401
    puts "Unauthorized. Generating new token..."
    token = generate_token
    make_http_request(url, data, success_counter, error_counter, invalid_contacts, token)
  elsif response.body.include?('exist_contact')
    puts "Contato já existente. Ignorando envio."
  else
    puts "HTTP request failed!"
    puts "Error message: #{response.message}"
    puts "Cannot retry request. Error: Code => #{response.code} Body => #{response.body}"
  end
  binding.pry
end

def generate_token
  file = File.read('config.json')
  config = JSON.parse(file)
  public_id = config['public_id']

  body = { public_id: public_id }.to_json
  token_response = HTTParty.post('https://gateway.sinc.digital/api/v1/sessions', body: body, headers: { 'Content-Type' => 'application/json' })

  # Extrair o token da resposta JSON
  response_body = JSON.parse(token_response.body)
  token = "Bearer #{response_body['token']}"
end

def update_excel_file(data)
  excel_file_path = '/Users/matheus.lopes/Downloads/LISTAGEM JUCERJA_NOVAS_EMPRESAS_9_MIL_CNPJ.xlsx'
  excel_file_path = '/path/to/your/excel/file.xlsx'
  workbook = WriteXLSX.new(excel_file_path)

  worksheet = workbook.add_worksheet('Contacts')

  worksheet.write(0, 0, 'Contact')
  worksheet.write(0, 1, 'Name')

  row = 1
  data.each do |contact|
    worksheet.write(row, 0, contact[:number])
    worksheet.write(row, 1, contact[:name])
    row += 1
  end

  workbook.close
end

# Specify the file path, URL, and make the function call
# excel_file_path = '/Users/matheus.lopes/Downloads/LISTAGEM JUCERJA_NOVAS_EMPRESAS_9_MIL_CNPJ.xlsx'
# api_url = 'https://gateway.sinc.digital/api/v1/contact/import'

# data = read_excel_file(excel_file_path)


# success_counter = Concurrent::AtomicFixnum.new(0)
# error_counter = Concurrent::AtomicFixnum.new(0)
# invalid_contacts = []

# pool_size = 10 # Número de processos a serem criados

# pool = Concurrent::FixedThreadPool.new(pool_size)

# token = generate_token

# data.each do |hash|
#   pool.post do
#     begin
#       make_http_request(api_url, hash, success_counter, error_counter, invalid_contacts, token)
#     rescue => e
#       puts "Exceção ocorreu em uma das threads do pool:"
#       puts "#{e.class}: #{e.message}"
#       puts e.backtrace.join("\n")
#     end
#   end
# end

# pool.shutdown
# pool.wait_for_termination

# puts "Total de contatos importados com sucesso: #{success_counter.value}"

# puts "Contatos inválidos:"
# invalid_contacts.each { |contact| puts contact.to_json }
