# frozen_string_literal: true

require_relative "commands_sinc/version"

module CommandsSinc
  BASE_URL = 'https://gateway.sinc.digital/api/v1'.freeze

  class Error < StandardError; end
  class ExcelImporterService
    require 'roo'
    def self.call(*args)
      new(*args).call
    end

    def initialize(file_path)
      @file_path = file_path
    end

    def call
      data = read_excel_file(file_path)
      update_excel_file(data)
    end

    private


    def read_excel_file(file_path)
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0) # assuming you want the first sheet

      data = []
      sheet.each_row_streaming(offset: 1) do |row| # offset: 1 if your spreadsheet contains a header
        # assuming first column contains 'number' and second column contains 'name'
        data << { number: row[0].value, name: row[1].value }
      end

      data
    end

    def update_excel_file(data)
      excel_file_path = "#{data}"
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
  end

  class ContactsConfirmationService
    def self.call(*args)
      new(*args).call
    end

    def initialize
      setup_database_connection
      @token = generate_token
      @channel_id = choose_channel
      @contacts = get_contacts
      @success_counter = Concurrent::AtomicFixnum.new(0)
      @error_counter = Concurrent::AtomicFixnum.new(0)
      @imported_contacts = [] # Array para guardar os contatos importados
    end

    def call

    end
  end

  private

  def make_http_request(url, method, data, success_counter, error_counter, invalid_contacts, token)
    response = HTTParty.send(method, url, body: data.to_json, headers: { 'Content-Type' => 'application/json', 'Authorization' => token })
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

  def choose_channel
    response = HTTParty.get("#{BASE_URL}/channel/all", headers: { 'Content-Type' => 'application/json', 'Authorization' => @token })

    if response.success?
      channels = JSON.parse(response.body)['list']

      # Encontra o primeiro canal que não tem a variável waba setada como true
      channel = channels.find { |channel| channel['waba'] == true && channel['primary'] == true }

      # Retorna o id do canal
      channel['id']
    else
      puts "Erro ao recuperar canais: #{response.body}"
      nil
    end
  end

  def get_contacts
    data = []
    begin
      Parallel.each(1..50, in_threads: 10) do |page|
        response = HTTParty.get("#{BASE_URL}/contact/all?p=#{page}", headers: { 'Content-Type' => 'application/json', 'Authorization' => @token })
        protocols = JSON.parse(response.body)["list"]
        protocols.each do |protocol|
          data << { number: protocol["number"], name: protocol["name"] }
        end
        data.uniq!
      end
    rescue => e
      puts "Error: #{e.message}"
    end
    # data.concat([
    #   { number: "5521998729009", name: "Matheus Lopes"},
    #   # { number: "5521991852646", name: "Julia Rocha"},
    #   # { number: "5521995353198", name: "Luigi"},
    #   # { number: "5521996504030", name: "Sandro Silva"}
    # ])
  end
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
