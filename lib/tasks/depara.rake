require 'benchmark'
require 'rest_client'
require 'uri'

namespace :depara do

  desc "TODO"
  task sync: :environment do
    update_regions

    update_pos_tax_codes_to_records

    correct_brand_to_question

    update_stores

    update_gallery

    hierarquie_dealers

    create_rules

    update_kpi_knowledge
    update_kpi_attendance
    update_kpi_communication
    update_kpi_maintenance
    update_kpi_exposition

    change_question_in_action_plans

  end


  task update_regions: :environment do
    update_regions
  end

  def update_regions
    Record.where(state_code: ['AM', 'RR', 'AP', 'PA', 'TO', 'RO', 'AC']).update_all(region: 'NORTE')
    Record.where(state_code: ['MA', 'PI', 'CE', 'RN', 'PE', 'PB', 'SE', 'AL', 'BA']).update_all(region: 'NORDESTE')
    Record.where(state_code: ['MT', 'MS', 'GO', 'DF']).update_all(region: 'CENTRO-OESTE')
    Record.where(state_code: ['SP', 'RJ', 'ES', 'MG']).update_all(region: 'SUDESTE')
    Record.where(state_code: ['PR', 'RS', 'SC']).update_all(region: 'SUL')
    puts 'update_regions: Done!'
  end

  task update_stores: :environment do
    update_stores
  end

  def update_stores
    puts 'Start: update_stores!'
    attributes = [:pos, :pos_code, :pos_tax_code, :execution_date_time, :channel, :retail, :pos_flag, :postal_code, :address_type, :address, :district, :city, :state_code, :region, :shopping, :promoter_name, :promoter_code, :vacancy_code, :trader_name, :trader_code, :supervisor_name, :supervisor_code, :latitude, :longitude, :cycle]
    puts 'Verify...'
    new_stores = Record.distinct(:pos_code).joins('LEFT JOIN stores ON stores.pos_code = records.pos_code AND stores.cycle = records.cycle').pluck(:pos_code, :week_date).uniq
    puts new_stores.count.inspect
    Store.transaction do
        new_stores.map do |store|
          next if store.first.nil? || store.last.nil?
          ids = Record.where(pos_code: store[0], week_date: store[1], campaign_id: '18').pluck('DISTINCT ON (pos_code) id')
          Record.where(id: ids).pluck(*attributes).map{|pa| Hash[*attributes.zip(pa).flatten]}.each do |store|
            puts "Erro na loja: #{store}" unless Store.find_or_create_by(store)
          end
        end
      end
    puts 'update_stores: Done!'
  end

  task create_users: :environment do
    create_users
  end

  def create_users
    puts 'Start create_users...'
    file = File.read(Rails.root + 'lib/assets/create_users.json')
    json = JSON.parse(file)
    array = {}
    # 0 => DEALER, 1 => pos_tax_code, 2 => TIPO, 3 => COD PDV, 4 => EMAIL, 5 => SENHA
    json.each do |value|
      @store = Store.find_by_pos_code(value[1])
      array[value[4]] ||= []
      array[value[4]] << @store.id if !@store.nil?
    end


    json.each do |value|

      user = User.find_by_email(value[4].downcase)

      if user.nil?
        user = User.new()
        user.name = value[0]
        user.email = value[4]
        user.password = value[5]
        user.password_confirmation = value[5]
        user.role_id = 3
        user.created_at = Time.now
        user.updated_at = Time.now
      end
      user.store_ids = array[value[4]]
      user.save
    end

    puts "DONE !"
  end

  task update_gallery: :environment do
    update_gallery
  end


   def update_gallery

    attributes = [:visit_id, :profile, :execution_date_time, :pos, :pos_code, :pos_tax_code, :channel, :retail, :pos_flag, :postal_code, :address_type, :address, :district, :city, :state_code, :form_name, :question, :answer, :created_at, :updated_at, :indication, :region, :cycle, :latitude, :longitude, :model_type, :model, :category, :week_date, :brand, :dealer, :store_type]
    puts 'Start rake...'

    loop do
      has_data = false
      max_visit_id = Gallery.maximum(:visit_id)
      puts 'max_visit_id: ' + max_visit_id.inspect

      max_visit_id = max_visit_id.nil? ? 0 : max_visit_id



      Record.where("visit_id > ?", max_visit_id).where("answer LIKE '%https://baseman-production%'").order(visit_id: :asc).limit(1000).pluck(*attributes).map{|pa| Hash[*attributes.zip(pa).flatten]}.each do |record|
        puts 'Doing: '+record[:visit_id].to_s
         has_data = true
        Gallery.create(record)
      end

    break unless has_data

    end

    Gallery.where(model: 'NEGATIVO').update_all(model: 'DIVERGENTE')
    puts 'End rake'
  end



 task update_pos_tax_codes_to_records: :environment do
    update_pos_tax_codes_to_records
  end


  def update_pos_tax_codes_to_records
    puts "Start depara"

    puts "Update in Record"
    Record.where(pos: 'BRANDSHOP - JK SHOPPING & TOWER - LOJA').update_all(pos_code: '12309173000841', pos_tax_code: '12309173000841')
    Record.where(pos: 'BRANDSHOP - SHOPPING 3 AMERICAS - QUIOSQUE').update_all(pos_code: '01030685001234', pos_tax_code: '01030685001234')
    Record.where(pos: 'BRANDSHOP - SHOPPING PALMAS - QUIOSQUE').update_all(pos_code: '04906728001452', pos_tax_code: '04906728001452')
    Record.where(pos: 'BRANDSHOP - SHOPPING ESTACAO  - QUIOSQUE').update_all(pos_code: '81214819001710', pos_tax_code: '81214819001710')
    Record.where(pos: 'BRANDSHOP - SHOPPING CENTER SAO JOSE - QUIOSQUE').update_all(pos_code: '81214819001397', pos_tax_code: '81214819001397')
    Record.where(pos: 'BRANDSHOP - FLAMBOYANT SHOPPING CENTER - QUIOSQUE').update_all(pos_code: '07851862002382', pos_tax_code: '07851862002382')
    Record.where(pos: 'BRANDSHOP - RIBEIRANEA SHOPPING - LOJA').update_all(pos_code: '10278888002800', pos_tax_code: '10278888002800')
    Record.where(pos: 'BRANDSHOP - STA. CRUZ  - QUIOSQUE').update_all(pos_code: '05053441005991', pos_tax_code: '05053441005991')
    Record.where(pos: 'BRANDSHOP - MIDWAY MALL - LOJA').update_all(pos_code: '24073694004495', pos_tax_code: '24073694004495')
    Record.where(pos: 'BRANDSHOP - CAPIM DOURADO SHOPPING - LOJA').update_all(pos_code: '04906728001371', pos_tax_code: '04906728001371')
    Record.where(pos: 'BRANDSHOP - FLAMBOYANT SHOPPING CENTER - LOJA').update_all(pos_code: '07851862000410', pos_tax_code: '07851862000410')
    Record.where(pos: 'BRANDSHOP - SHOPPING PASSEIO DAS AGUAS - LOJA').update_all(pos_code: '07851862001572', pos_tax_code: '07851862001572')
    Record.where(pos: 'BRANDSHOP - SHOPPING CURITIBA - QUIOSQUE').update_all(pos_code: '81214819001630', pos_tax_code: '81214819001630')
    Record.where(pos: 'BRANDSHOP - SHOPPING DA BAHIA PISO 3 - LOJA').update_all(pos_code: '00660296000339', pos_tax_code: '00660296000339')
    Record.where(pos: 'BRANDSHOP - NORTH SHOPPING FORTALEZA 2 - LOJA').update_all(pos_code: '04906728000219', pos_tax_code: '04906728000219')
    Record.where(pos: 'BRANDSHOP - SHOPPING NOVA IGUACU - QUIOSQUE').update_all(pos_code: '05053441001902', pos_tax_code: '05053441001902')

    Store.where(pos: 'BRANDSHOP - JK SHOPPING & TOWER - LOJA').update_all(pos_code: '12309173000841', pos_tax_code: '12309173000841')
    Store.where(pos: 'BRANDSHOP - SHOPPING 3 AMERICAS - QUIOSQUE').update_all(pos_code: '01030685001234', pos_tax_code: '01030685001234')
    Store.where(pos: 'BRANDSHOP - SHOPPING PALMAS - QUIOSQUE').update_all(pos_code: '04906728001452', pos_tax_code: '04906728001452')
    Store.where(pos: 'BRANDSHOP - SHOPPING ESTACAO  - QUIOSQUE').update_all(pos_code: '81214819001710', pos_tax_code: '81214819001710')
    Store.where(pos: 'BRANDSHOP - SHOPPING CENTER SAO JOSE - QUIOSQUE').update_all(pos_code: '81214819001397', pos_tax_code: '81214819001397')
    Store.where(pos: 'BRANDSHOP - FLAMBOYANT SHOPPING CENTER - QUIOSQUE').update_all(pos_code: '07851862002382', pos_tax_code: '07851862002382')
    Store.where(pos: 'BRANDSHOP - RIBEIRANEA SHOPPING - LOJA').update_all(pos_code: '10278888002800', pos_tax_code: '10278888002800')
    Store.where(pos: 'BRANDSHOP - STA. CRUZ  - QUIOSQUE').update_all(pos_code: '05053441005991', pos_tax_code: '05053441005991')
    Store.where(pos: 'BRANDSHOP - MIDWAY MALL - LOJA').update_all(pos_code: '24073694004495', pos_tax_code: '24073694004495')
    Store.where(pos: 'BRANDSHOP - CAPIM DOURADO SHOPPING - LOJA').update_all(pos_code: '04906728001371', pos_tax_code: '04906728001371')
    Store.where(pos: 'BRANDSHOP - FLAMBOYANT SHOPPING CENTER - LOJA').update_all(pos_code: '07851862000410', pos_tax_code: '07851862000410')
    Store.where(pos: 'BRANDSHOP - SHOPPING PASSEIO DAS AGUAS - LOJA').update_all(pos_code: '07851862001572', pos_tax_code: '07851862001572')
    Store.where(pos: 'BRANDSHOP - SHOPPING CURITIBA - QUIOSQUE').update_all(pos_code: '81214819001630', pos_tax_code: '81214819001630')
    Store.where(pos: 'BRANDSHOP - SHOPPING DA BAHIA PISO 3 - LOJA').update_all(pos_code: '00660296000339', pos_tax_code: '00660296000339')
    Store.where(pos: 'BRANDSHOP - NORTH SHOPPING FORTALEZA 2 - LOJA').update_all(pos_code: '04906728000219', pos_tax_code: '04906728000219')
    Store.where(pos: 'BRANDSHOP - SHOPPING NOVA IGUACU - QUIOSQUE').update_all(pos_code: '05053441001902', pos_tax_code: '05053441001902')


    Gallery.where(pos: 'BRANDSHOP - JK SHOPPING & TOWER - LOJA').update_all(pos_code: '12309173000841', pos_tax_code: '12309173000841')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING 3 AMERICAS - QUIOSQUE').update_all(pos_code: '01030685001234', pos_tax_code: '01030685001234')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING PALMAS - QUIOSQUE').update_all(pos_code: '04906728001452', pos_tax_code: '04906728001452')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING ESTACAO  - QUIOSQUE').update_all(pos_code: '81214819001710', pos_tax_code: '81214819001710')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING CENTER SAO JOSE - QUIOSQUE').update_all(pos_code: '81214819001397', pos_tax_code: '81214819001397')
    Gallery.where(pos: 'BRANDSHOP - FLAMBOYANT SHOPPING CENTER - QUIOSQUE').update_all(pos_code: '07851862002382', pos_tax_code: '07851862002382')
    Gallery.where(pos: 'BRANDSHOP - RIBEIRANEA SHOPPING - LOJA').update_all(pos_code: '10278888002800', pos_tax_code: '10278888002800')
    Gallery.where(pos: 'BRANDSHOP - STA. CRUZ  - QUIOSQUE').update_all(pos_code: '05053441005991', pos_tax_code: '05053441005991')
    Gallery.where(pos: 'BRANDSHOP - MIDWAY MALL - LOJA').update_all(pos_code: '24073694004495', pos_tax_code: '24073694004495')
    Gallery.where(pos: 'BRANDSHOP - CAPIM DOURADO SHOPPING - LOJA').update_all(pos_code: '04906728001371', pos_tax_code: '04906728001371')
    Gallery.where(pos: 'BRANDSHOP - FLAMBOYANT SHOPPING CENTER - LOJA').update_all(pos_code: '07851862000410', pos_tax_code: '07851862000410')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING PASSEIO DAS AGUAS - LOJA').update_all(pos_code: '07851862001572', pos_tax_code: '07851862001572')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING CURITIBA - QUIOSQUE').update_all(pos_code: '81214819001630', pos_tax_code: '81214819001630')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING DA BAHIA PISO 3 - LOJA').update_all(pos_code: '00660296000339', pos_tax_code: '00660296000339')
    Gallery.where(pos: 'BRANDSHOP - NORTH SHOPPING FORTALEZA 2 - LOJA').update_all(pos_code: '04906728000219', pos_tax_code: '04906728000219')
    Gallery.where(pos: 'BRANDSHOP - SHOPPING NOVA IGUACU - QUIOSQUE').update_all(pos_code: '05053441001902', pos_tax_code: '05053441001902')


    StoreResult.where(pos_code: '8,12148E+13').update_all(pos_code: '81214819001710')
    StoreResult.where(pos_code: '05053441001902?????').update_all(pos_code: '05053441001902')

  end


  task hierarquie_dealers: :environment do
    hierarquie_dealers
  end

  def hierarquie_dealers

    Record.update_all(dealer: nil, store_type: nil)
    Store.update_all(dealer: nil, store_type: nil)
    Gallery.update_all(dealer: nil, store_type: nil)

    puts 'Start record hierarquie...'
    file = File.read(Rails.root + 'lib/assets/dealer_hierarquie.json')
    json = JSON.parse(file)
    array = {}
    # 0 => POX_TAX_CODE, 1 => DEALER, 2 => TYPE
    json.each do |value|
      puts 'Put in records'
      Record.where(pos_code: value[0]).update_all(dealer: value[1], store_type: value[2])
      puts 'Put in stores'
      Store.where(pos_code: value[0]).update_all(dealer: value[1], store_type: value[2])
      puts 'Put in galleries'
      Gallery.where(pos_code: value[0]).update_all(dealer: value[1], store_type: value[2])
    end
    puts 'Done!'
  end

  task correct_brand_to_question: :environment do
    correct_brand_to_question
  end

  def correct_brand_to_question
    puts "Start change!"
    Record.where(question: '[PRODUTO OFERTADO] QUAL?', brand: 'NONE').update_all(brand: 'CONHECIMENTO')
    puts "Done!"
  end

  task create_rules: :environment do
    create_rules
  end

  def create_rules
    puts "start create rules"

    Rule.delete_all()
    StoreResult.delete_all()

    file = File.read(Rails.root + 'lib/assets/rules.json')
    json = JSON.parse(file)
    array = {}
    stores = Store.pluck(:pos_code)
    # 0 => QUESTION_FORM, 1 => QUESTION_DASH, 2 => CRITERION, 3 => POINTS
    json.each do |value|

      Record.where(question: value[0]).update_all(question_dash: value[1])

      stores.each do |pos_code|
        store_result = StoreResult.new

        store_result.pos_code = pos_code
        store_result.brand = value[4]
        store_result.question_default = value[0]
        store_result.question_dashboard = value[1]
        store_result.criterion = value[2]
        store_result.points_expectative = value[3]
        store_result.save
      end

    end

    puts "Done!"
  end

  task update_kpi_knowledge: :environment do
    update_kpi_knowledge
  end

  def update_kpi_knowledge
    puts "Start update kpi knowledge"
    valid = {}
    points = {}
    total_question_knowledge = {}
    total_score = {}
    question_key = {}
    Store.update_all(knowledge: false)

    records = Record.where(brand: 'CONHECIMENTO', question: ["[BENEFÍCIO CÂMERA REVOLUCIONÁRIA GALAXY S7] O VENDEDOR CITOU SOBRE A MAIOR VELOCIDADE E QUALIDADE?", "[BENEFÍCIO DESIGN GALAXY S7] O VENDEDOR CITOU MAIOR CONFORTO?", "[BENEFÍCIO DIFERENCIAIS GALAXY S7] O VENDEDOR CITOU A SEGURANÇA E FACILIDADE?", "[BENEFÍCIO PRATICIDADE GALAXY S7] O VENDEDOR CITOU SOBRE O USO NA CHUVA E NA PRAIA?", "[DEMONSTRAÇÃO CÂMERA REVOLUCIONÁRIA GALAXY S7] TESTOU A CÂMERA?", "[DEMONSTRAÇÃO DESIGN GALAXY S7] ENTREGOU O TELEFONE PARA USAR?", "[DEMONSTRAÇÃO DIFERENCIAIS GALAXY S7] TESTOU O SISTEMA?", "[DEMONSTRAÇÃO PRATICIDADE GALAXY S7] MOSTROU COMODIDADE?", "[EXPLICAÇÃO CÂMERA REVOLUCIONÁRIA GALAXY S7] O VENDEDOR EXPLICOU SOBRE O AJUSTE RÁPIDO DE FOCO?", "[EXPLICAÇÃO DESIGN GALAXY S7] O VENDEDOR EXPLICOU SOBRE O MATERIAL SOFISTICADO E LINHAS SUAVES?", "[EXPLICAÇÃO DIFERENCIAIS GALAXY S7] O VENDEDOR EXPLICOU SOBRE A CARTEIRA NO SEU SMARTPHONE?", "[EXPLICAÇÃO PRATICIDADE GALAXY S7] O VENDEDOR EXPLICOU SOBRE A RESISTÊNCIA À ÁGUA?", "[PRODUTO OFERTADO] QUAL?"]).pluck(:pos_code, :question, :answer, :cycle, :brand)

    records.each do |record|
      valid[record[0]] = {}
      valid[record[0]][record[3]] = 0
      points[record[0]] ||= {}
      points[record[0]][record[3]] ||= {}
      points[record[0]][record[3]][record[1]] ||= '0'
      total_question_knowledge[record[0]] ||= 0
      question_key[record[0]] ||= {}
      question_key[record[0]][record[3]] ||= nil

    end

    records.each do |record|
      total_question_knowledge[record[0]] += 1

      case record[1]
      when '[BENEFÍCIO CÂMERA REVOLUCIONÁRIA GALAXY S7] O VENDEDOR CITOU SOBRE A MAIOR VELOCIDADE E QUALIDADE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when  '[BENEFÍCIO DESIGN GALAXY S7] O VENDEDOR CITOU MAIOR CONFORTO?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[BENEFÍCIO DIFERENCIAIS GALAXY S7] O VENDEDOR CITOU A SEGURANÇA E FACILIDADE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[BENEFÍCIO PRATICIDADE GALAXY S7] O VENDEDOR CITOU SOBRE O USO NA CHUVA E NA PRAIA?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[DEMONSTRAÇÃO CÂMERA REVOLUCIONÁRIA GALAXY S7] TESTOU A CÂMERA?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[DEMONSTRAÇÃO DESIGN GALAXY S7] ENTREGOU O TELEFONE PARA USAR?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[DEMONSTRAÇÃO DIFERENCIAIS GALAXY S7] TESTOU O SISTEMA?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[DEMONSTRAÇÃO PRATICIDADE GALAXY S7] MOSTROU COMODIDADE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[EXPLICAÇÃO CÂMERA REVOLUCIONÁRIA GALAXY S7] O VENDEDOR EXPLICOU SOBRE O AJUSTE RÁPIDO DE FOCO?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[EXPLICAÇÃO DESIGN GALAXY S7] O VENDEDOR EXPLICOU SOBRE O MATERIAL SOFISTICADO E LINHAS SUAVES?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[EXPLICAÇÃO DIFERENCIAIS GALAXY S7] O VENDEDOR EXPLICOU SOBRE A CARTEIRA NO SEU SMARTPHONE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[EXPLICAÇÃO PRATICIDADE GALAXY S7] O VENDEDOR EXPLICOU SOBRE A RESISTÊNCIA À ÁGUA?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'CONHECIMENTO', points: points[record[0]][record[3]][record[1]])
      when '[PRODUTO OFERTADO] QUAL?'
        question_key[record[0]][record[3]] = 'ACCEPT' if record[2] == 'GALAXY S7'
      end
    end

    valid.each do |pos_code, cycles|
      cycles.each do |cycle, valid_total|

        Store.where(pos_code: pos_code, cycle: cycle).update_all(points_knowledge: valid_total.to_s)
        if !question_key[pos_code][cycle].nil?
          if ((valid_total.to_f / 240) * 100) >= 70.0
            Store.where(pos_code: pos_code, cycle: cycle).update_all(knowledge: true)
          end
        end
      end
    end
    puts "Done!"
  end

  task update_kpi_attendance: :environment do
    update_kpi_attendance
  end

  def update_kpi_attendance
    puts "Start update kpi attendance"
    array_store = {}
    valid = {}
    points = {}
    total_question_attendance = {}
    total_vendors_attendance = {}
    total_vendors_calcados = {}

    is_valid = {}

    Store.update_all(attendance: false)

    records = Record.where(question: ['[ABORDAGEM] RECOMENDAÇÃO DE PRODUTO DE ACORDO COM AS NECESSIDADES DO CLIENTE?', '[ABORDAGEM] ATITUDE AMIGÁVEL E CORTÊS NO ATENDIMENTO AO CLIENTE?', '[ABORDAGEM] REALIZOU PERGUNTAS PARA IDENTIFICAR AS NECESSIDADES?', '[ABORDAGEM] QUAL FOI O TEMPO DA ABORDAGEM?', '[QTD CRACHÁ] QUANTIDADE DE VENDEDORES SEM CRACHÁ:', '[QTD ADEREÇOS GRANDES] QUANTIDADE DE VENDEDORES COM ADEREÇOS GRANDES:', '[QTD UNIFORME RASGADO] QUANTIDADE DE VENDEDORES COM UNIFORME RASGADO:', '[QTD UNIFORME DESBOTADO] QUANTIDADE DE VENDEDORES COM UNIFORME DESBOTADO:', '[QTD UNIFORME REFORMADO] QUANTIDADE DE VENDEDORES COM UNIFORME REFORMADO:', '[QTD CALÇADO PRETO (MULHER)] QUANTIDADE DE VENDEDORAS COM CALÇADO PRETO CORRETO?', '[QTD CALÇADO PRETO (HOMEM)] QUANTIDADE DE VENDEDORES COM CALÇADO PRETO CORRETO?', '[QTD CALÇA AZUL ESCURO] QUANTIDADE DE VENDEDORES COM A CALÇA AZUL ESCURA CORRETA:', '[QTD CAMISETA] QUANTIDADE DE VENDEDORES COM A CAMISETA CORRETA:','[PROGRAMA SMART (CONCIÉRGE)] POSSUI ÚLTIMA VERSÃO DO PROGRAMA SMART INSTALADA (4.16.0202)? ', '[DISPONIBILIDADE DE CABO IPHONE] POSSUI DISPONIBILIDADE DE CABO PARA IPHONE?', '[CABO OTG (CONCIÉRGE)] POSSUI CABO OTG (ON-THE-GO) PARA SMART SWITCH?', '[VENDEDOR EXPERT] O VENDEDOR QUE PARTICIPOU DO TREINAMENTO EXPERT ESTÁ PRESENTE?', '[INFORMAÇÕES CRM] O GERENTE COLETA INFORMAÇÕES PARA CRM?', '[MÍDIAS SOCIAIS] QUAL MÍDIA O GERENTE UTILIZA PARA DIVULGAR A LOJA?']).pluck(:pos_code, :question, :answer, :cycle, :brand)
    total_promotores = Record.where(brand: 'ATENDIMENTO', question: '[VENDEDORES] QUANTOS?').pluck(:pos_code, :question, :answer, :cycle, :brand)
    verify_valid = Record.where(question: '[MÍDIAS SOCIAIS] O GERENTE UTILIZA MÍDIAS SOCIAIS PARA DIVULGAR A LOJA?').pluck(:pos_code, :answer, :cycle)

    total_promotores.each do |total_promoter|
      total_vendors_attendance[total_promoter[0]] ||= {}
      total_vendors_attendance[total_promoter[0]][total_promoter[3]] ||= 0

      total_vendors_attendance[total_promoter[0]][total_promoter[3]] = total_promoter[2].to_i
    end

    records.each do |record|
      array_store[record[0]] ||= {}
      array_store[record[0]][record[3]] ||= []
      total_question_attendance[record[0]] ||= 0
      valid[record[0]] = {}
      valid[record[0]][record[3]] = 0
      points[record[0]] ||= {}
      points[record[0]][record[3]] ||= {}
      points[record[0]][record[3]][record[1]] ||= '0'
      total_vendors_calcados[record[0]] = {}
      total_vendors_calcados[record[0]][record[3]] = 0

      is_valid[record[0]] = {}
      is_valid[record[0]][record[3]] = nil
    end

    records.each do |record|
      if record[1] == '[QTD CALÇADO PRETO (MULHER)] QUANTIDADE DE VENDEDORAS COM CALÇADO PRETO CORRETO?' || record[1] == '[QTD CALÇADO PRETO (HOMEM)] QUANTIDADE DE VENDEDORES COM CALÇADO PRETO CORRETO?'
        total_vendors_calcados[record[0]][record[3]] += record[2].to_i
      end
    end

    verify_valid.each do |answer|
      is_valid[answer[0]][answer[2]] = answer[1]
    end

    records.each do |record|
      total_question_attendance[record[0]] += 1

      if (record[1] == '[QTD CALÇADO PRETO (MULHER)] QUANTIDADE DE VENDEDORAS COM CALÇADO PRETO CORRETO?' && record[2] == 0 ) || (record[1] == '[QTD CALÇADO PRETO (HOMEM)] QUANTIDADE DE VENDEDORES COM CALÇADO PRETO CORRETO?' && record[2] == 0 )
        total_question_attendance[record[0]] -= 1
      end

      case record[1]
      when '[ABORDAGEM] RECOMENDAÇÃO DE PRODUTO DE ACORDO COM AS NECESSIDADES DO CLIENTE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[ABORDAGEM] ATITUDE AMIGÁVEL E CORTÊS NO ATENDIMENTO AO CLIENTE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[ABORDAGEM] REALIZOU PERGUNTAS PARA IDENTIFICAR AS NECESSIDADES?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[PROGRAMA SMART (CONCIÉRGE)] POSSUI ÚLTIMA VERSÃO DO PROGRAMA SMART INSTALADA (4.16.0202)? '
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[ABORDAGEM] QUAL FOI O TEMPO DA ABORDAGEM?'
        valid[record[0]][record[3]] += 30 if record[2] == 'IMEDIATO'
        points[record[0]][record[3]][record[1]] = '30' if record[2] == 'IMEDIATO'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[DISPONIBILIDADE DE CABO IPHONE] POSSUI DISPONIBILIDADE DE CABO PARA IPHONE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[CABO OTG (CONCIÉRGE)] POSSUI CABO OTG (ON-THE-GO) PARA SMART SWITCH?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[VENDEDOR EXPERT] O VENDEDOR QUE PARTICIPOU DO TREINAMENTO EXPERT ESTÁ PRESENTE?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[INFORMAÇÕES CRM] O GERENTE COLETA INFORMAÇÕES PARA CRM?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[MÍDIAS SOCIAIS] QUAL MÍDIA O GERENTE UTILIZA PARA DIVULGAR A LOJA?'
        valid[record[0]][record[3]] += 20 if record[2] == 'SITE E MÍDIAS SOCIAIS DO SHOPPING'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'SITE E MÍDIAS SOCIAIS DO SHOPPING'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], points: points[record[0]][record[3]][record[1]])
      when '[QTD CRACHÁ] QUANTIDADE DE VENDEDORES SEM CRACHÁ:'
        if ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100) == 0.0
          valid[record[0]][record[3]] += 15
          points[record[0]][record[3]][record[1]] = '15'
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: points[record[0]][record[3]][record[1]])
        else
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: '0')
        end
      when '[QTD ADEREÇOS GRANDES] QUANTIDADE DE VENDEDORES COM ADEREÇOS GRANDES:'
        if ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100) == 0.0
          valid[record[0]][record[3]] += 10
          points[record[0]][record[3]][record[1]] = '10'
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: points[record[0]][record[3]][record[1]])
        else
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: '0')
        end
      when '[QTD UNIFORME RASGADO] QUANTIDADE DE VENDEDORES COM UNIFORME RASGADO:'
        if ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100) == 0.0
          valid[record[0]][record[3]] += 10
          points[record[0]][record[3]][record[1]] = '10'
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: points[record[0]][record[3]][record[1]])
        else
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: '0')
        end
      when '[QTD UNIFORME DESBOTADO] QUANTIDADE DE VENDEDORES COM UNIFORME DESBOTADO:'
        if ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100) == 0.0
          valid[record[0]][record[3]] += 10
          points[record[0]][record[3]][record[1]] = '10'
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: points[record[0]][record[3]][record[1]])
        else
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: '0')
        end
      when '[QTD UNIFORME REFORMADO] QUANTIDADE DE VENDEDORES COM UNIFORME REFORMADO:'
        if ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100) == 0.0
          valid[record[0]][record[3]] += 10
          points[record[0]][record[3]][record[1]] = '10'
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: points[record[0]][record[3]][record[1]])
        else
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, points: '0')
        end
      when '[QTD CALÇADO PRETO (HOMEM)] QUANTIDADE DE VENDEDORES COM CALÇADO PRETO CORRETO?'
        if ((total_vendors_calcados[record[0]][record[3]].to_f / total_vendors_attendance[record[0]][record[3]]) * 100) == 100.0
          valid[record[0]][record[3]] += 15
          points[record[0]][record[3]]['CALÇADOS'] = '15'
          new_answer = ((total_vendors_calcados[record[0]][record[3]].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: '[QTD CALÇADO PRETO (HOMEM)] QUANTIDADE DE VENDEDORES COM CALÇADO PRETO CORRETO?').update_all(answer: new_answer, brand: 'ATENDIMENTO', points: points[record[0]][record[3]]['CALÇADOS'])
        else
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: '[QTD CALÇADO PRETO (HOMEM)] QUANTIDADE DE VENDEDORES COM CALÇADO PRETO CORRETO?').update_all(answer: new_answer, brand: 'ATENDIMENTO', points: '0')
        end
      when '[QTD CALÇA AZUL ESCURO] QUANTIDADE DE VENDEDORES COM A CALÇA AZUL ESCURA CORRETA:', '[QTD CAMISETA] QUANTIDADE DE VENDEDORES COM A CAMISETA CORRETA:'
        if ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100) == 100.0
          valid[record[0]][record[3]] += 15
          points[record[0]][record[3]][record[1]] = '15'
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, brand: 'ATENDIMENTO', points: points[record[0]][record[3]][record[1]])
        else
          new_answer = ((record[2].to_f / total_vendors_attendance[record[0]][record[3]]) * 100).to_s
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: new_answer, brand: 'ATENDIMENTO', points: '0')
        end
      end

      if is_valid[record[0]][record[3]] == 'NÃO'
        StoreResult.where(pos_code: record[0], question_default: '[MÍDIAS SOCIAIS] QUAL MÍDIA O GERENTE UTILIZA PARA DIVULGAR A LOJA?').update_all(answer: 'SEM RESPOSTA', points: '0')
      end
    end

    valid.each do |pos_code, cycles|
      cycles.each do |cycle, valid_total|
        Store.where(pos_code: pos_code, cycle: cycle).update_all(points_attendance: valid_total.to_s)
        if ((valid_total.to_f / 180) * 100) >= 70
          Store.where(pos_code: pos_code, cycle: cycle).update_all(attendance: true)
        end
      end
    end
    puts "Done!"

  end

  task update_kpi_communication: :environment do
    update_kpi_communication
  end

  def update_kpi_communication
    puts "Start update kpi communication"
    total = {}
    valid = {}
    points = {}
    total_question_communication = {}
    total_vendors_attendance = {}

    Store.update_all(communication: false)

    records = Record.where(brand: 'COMUNICACAO VISUAL', question: ['[CO-DISPLAY CARREGADOR WIRELESS] A LOJA POSSUI CARREGADOR CO DISPLAY WIRELESS?', '[SMART SERVICE (CONCIÉRGE)] O ATENDIMENTO AO CLIENTE (CONCIÉRGE) POSSUI ALGUM TIPO DE COMUNICAÇÃO SMART SERVICE?', '[MATERIAL PDV] A LOJA POSSUI FOLHETO, CARTAZETE OU OUTRO TIPO DE MATERIAL?']).pluck(:pos_code, :question, :answer, :cycle, :brand)

    records.each do |record|
      total[record[0]] ||= {}
      total[record[0]][record[3]] ||= 0
      total_question_communication[record[0]] ||= 0
      valid[record[0]] = {}
      valid[record[0]][record[3]] = 0
      points[record[0]] ||= {}
      points[record[0]][record[3]] ||= {}
      points[record[0]][record[3]][record[1]] ||= '0'

    end

    records.each do |record|
      store = Store.where(pos_code: record[0], cycle: record[3]).pluck(:store_type)[0]

        case record[1]
        when '[CO-DISPLAY CARREGADOR WIRELESS] A LOJA POSSUI CARREGADOR CO DISPLAY WIRELESS?'
          total[record[0]][record[3]] += 30
          valid[record[0]][record[3]] += 30 if record[2] == 'SIM'
          points[record[0]][record[3]][record[1]] = '30' if record[2] == 'SIM'
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'COMUNICACAO VISUAL', points: points[record[0]][record[3]][record[1]])
        when '[SMART SERVICE (CONCIÉRGE)] O ATENDIMENTO AO CLIENTE (CONCIÉRGE) POSSUI ALGUM TIPO DE COMUNICAÇÃO SMART SERVICE?'
          if store == 'SES'
            total[record[0]][record[3]] += 30
            valid[record[0]][record[3]] += 30 if record[2] == 'SIM'
            points[record[0]][record[3]][record[1]] = '30' if record[2] == 'SIM'
            StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'COMUNICACAO VISUAL', points: points[record[0]][record[3]][record[1]])
          else
            StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: 'NÃO AVALIADO', brand: 'COMUNICACAO VISUAL', points: '30')
          end
        when '[MATERIAL PDV] A LOJA POSSUI FOLHETO, CARTAZETE OU OUTRO TIPO DE MATERIAL?'
          total[record[0]][record[3]] += 30
          valid[record[0]][record[3]] += 30 if record[2] == 'SIM'
          points[record[0]][record[3]][record[1]] = '30' if record[2] == 'SIM'
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'COMUNICACAO VISUAL', points: points[record[0]][record[3]][record[1]])
        end
    end

    valid.each do |pos_code, cycles|
      cycles.each do |cycle, valid_total|
        Store.where(pos_code: pos_code, cycle: cycle).update_all(points_communication: valid_total.to_s )

        if ((valid_total.to_f / total[pos_code][cycle]) * 100) >= 70
          Store.where(pos_code: pos_code, cycle: cycle).update_all(communication: true)
        end
      end
    end
    puts "Done!"

  end

  task update_kpi_maintenance: :environment do
    update_kpi_maintenance
  end

  def update_kpi_maintenance
    puts "Start update kpi maintenance"
    array_store = {}
    valid = {}
    total = {}
    points = {}
    total_question_product = {}
    product_points = {}

    Store.update_all(maintenance: false)

    records = Record.where(brand: 'MANUTENCAO', question: ['[CADEIRA DANIFICADA] HÁ CADEIRAS DANIFICADAS NA LOJA (INCLUSIVE DOS FUNCIONÁRIOS)?','[SMART TABLE MESAS/BANCADAS LATERAIS] HÁ DANOS, MANCHAS OU AVARIAS NAS MESAS OU BANCADAS LATERAIS?', '[COMUNICAÇÃO CONCIÉRGE] HÁ DANOS NOS LETREIROS "SAMSUNG" E "GALAXY"', '[SINALIZAÇÃO] EXISTEM LÂMPADAS APAGADAS?', '[SINALIZAÇÃO] A FACHADA ESTÁ LIMPA (SEM SUJEIRA OU POEIRA)?', '[SINALIZAÇÃO] O LETREIRO  SAMSUNG DA FACHADA ESTAVA LIGADO?', '[AVARIA] O PRODUTO ESTÁ SUJO OU AVARIADO?']).pluck(:pos_code, :question, :answer, :cycle, :brand)
    stores = Record.where(brand: 'MANUTENCAO', question: ['[AVARIA] O PRODUTO ESTÁ SUJO OU AVARIADO?']).pluck('DISTINCT pos_code, cycle, question, brand')

    records.each do |record|
      total[record[0]] ||= {}
      total[record[0]][record[3]] ||= 0
      total_question_product[record[0]] ||= {}
      total_question_product[record[0]][record[3]] ||= 0

      product_points[record[0]] ||= {}
      product_points[record[0]][record[3]] ||= 0

      if  record[1] == '[AVARIA] O PRODUTO ESTÁ SUJO OU AVARIADO?'
        total_question_product[record[0]][record[3]] += 1
        product_points[record[0]][record[3]] += 1 if record[2] == 'SIM'
      end

    end

    records.each do |record|
      array_store[record[0]] ||= {}
      array_store[record[0]][record[3]] ||= []
      valid[record[0]] = {}
      valid[record[0]][record[3]] = 0
      points[record[0]] ||= {}
      points[record[0]][record[3]] ||= {}
      points[record[0]][record[3]][record[1]] ||= '0'
    end

    records.each do |record|
    store = Store.where(pos_code: record[0], cycle: record[3]).pluck(:store_type)[0]

      case record[1]
      when '[CADEIRA DANIFICADA] HÁ CADEIRAS DANIFICADAS NA LOJA (INCLUSIVE DOS FUNCIONÁRIOS)?'
        total[record[0]][record[3]] += 17
        valid[record[0]][record[3]] += 17 if record[2] == 'NÃO'
        points[record[0]][record[3]][record[1]] = '17' if record[2] == 'NÃO'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'MANUTENCAO', points: points[record[0]][record[3]][record[1]])
      when '[SMART TABLE MESAS/BANCADAS LATERAIS] HÁ DANOS, MANCHAS OU AVARIAS NAS MESAS OU BANCADAS LATERAIS?'
        total[record[0]][record[3]] += 20
        valid[record[0]][record[3]] += 20 if record[2] == 'NÃO'
        points[record[0]][record[3]][record[1]] = '20' if record[2] == 'NÃO'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'MANUTENCAO', points: points[record[0]][record[3]][record[1]])
      when '[COMUNICAÇÃO CONCIÉRGE] HÁ DANOS NOS LETREIROS "SAMSUNG" E "GALAXY"'
        if store == 'SES'
          total[record[0]][record[3]] += 17
          valid[record[0]][record[3]] += 17 if record[2] == 'NÃO'
          points[record[0]][record[3]][record[1]] = '17' if record[2] == 'NÃO'
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'MANUTENCAO', points: points[record[0]][record[3]][record[1]])
        else
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: 'NÃO AVALIADO', brand: 'MANUTENCAO', points: '17')
        end
      when '[SINALIZAÇÃO] O LETREIRO  SAMSUNG DA FACHADA ESTAVA LIGADO?'
        if store == 'SES'
          total[record[0]][record[3]] += 17
          valid[record[0]][record[3]] += 17 if record[2] == 'SIM'
          points[record[0]][record[3]][record[1]] = '17' if record[2] == 'SIM'
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'MANUTENCAO', points: points[record[0]][record[3]][record[1]])
        else
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: 'NÃO AVALIADO', brand: 'MANUTENCAO', points: '17')
        end
      when '[SINALIZAÇÃO] EXISTEM LÂMPADAS APAGADAS?'
        total[record[0]][record[3]] += 17
        valid[record[0]][record[3]] += 17 if record[2] == 'NÃO'
        points[record[0]][record[3]][record[1]] = '17' if record[2] == 'NÃO'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'MANUTENCAO', points: points[record[0]][record[3]][record[1]])
      when '[SINALIZAÇÃO] A FACHADA ESTÁ LIMPA (SEM SUJEIRA OU POEIRA)?'
        total[record[0]][record[3]] += 15
        valid[record[0]][record[3]] += 15 if record[2] == 'SIM'
        points[record[0]][record[3]][record[1]] = '15' if record[2] == 'SIM'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'MANUTENCAO', points: points[record[0]][record[3]][record[1]])
      end
    end

    stores.each do |store|
      if ((product_points[store[0]][store[1]].to_f / total_question_product[store[0]][store[1]]) * 100) == 0.0
        total[store[0]][store[1]] += 17
        valid[store[0]][store[1]] += 17
        points[store[0]][store[1]][store[2]] = '17'
        new_answer = ((product_points[store[0]][store[1]].to_f / total_question_product[store[0]][store[1]]) * 100).to_s
        StoreResult.where(pos_code: store[0], question_default: '[AVARIA] O PRODUTO ESTÁ SUJO OU AVARIADO?').update_all(answer: new_answer, brand: 'MANUTENCAO', points: points[store[0]][store[1]][store[2]])
      else
        new_answer = ((product_points[store[0]][store[1]].to_f / total_question_product[store[0]][store[1]]) * 100).to_s
        StoreResult.where(pos_code: store[0], question_default: '[AVARIA] O PRODUTO ESTÁ SUJO OU AVARIADO?').update_all(answer: new_answer, brand: 'MANUTENCAO', points: '0')
      end
    end

    valid.each do |pos_code, cycles|
      cycles.each do |cycle, valid_total|
        Store.where(pos_code: pos_code, cycle: cycle).update_all(points_maintenance: valid_total.to_s)
        if ((valid_total.to_f / total[pos_code][cycle]) * 100) >= 70.0
          Store.where(pos_code: pos_code, cycle: cycle).update_all(maintenance: true)
        end
      end
    end
    puts "Done!"
  end

  task update_kpi_exposition: :environment do
    update_kpi_exposition
  end

  def update_kpi_exposition
    puts "Start update kpi exposition"
    array_store = {}
    valid = {}
    points = {}
    total = {}
    total_question_exposition = {}
    total_vendors_attendance = {}
    total_question_product = {}
    product_points = {}
    verify_s7 = {}
    verify_s7_edge = {}
    cor_s7 = {}
    cor_s7_edge = {}
    count_cor_s7 = {}
    count_cor_s7_edge = {}
    Store.update_all(exposition: false)

    records = Record.where(question: ['[SMART TABLE MESAS/BANCADAS] HÁ BURACOS (POSIÇÃO DO PRODUTO) SEM PRODUTOS EXPOSTOS?', '[MESA DEDICADA (SMART TABLE)] POSSUI MESA DEDICADA À S7?', '[CONFIGURAÇÃO DE CONTA] O APARELHO POSSUI CONTA SAMSUNG E GOOGLE?', '[CONEXÃO INTERNET] O APARELHO ESTÁ CONECTADO À INTERNET?', '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?', '[RETAIL MODE] LIGADO?', '[LIGADO] O APARELHO ESTÁ LIGADO?', '[COR S7 EDGE] QUAL?', 'MODELO:', '[COR S7 FLAT] QUAL?', '[ESPAÇAMENTO PAREDE DE ACESSÓRIOS] É MAIOR QUE 3CM (APROX. DOIS DEDOS)?']).pluck(:pos_code, :question, :answer, :cycle, :brand)
    stores = Record.where(question: ['[SMART TABLE MESAS/BANCADAS] HÁ BURACOS (POSIÇÃO DO PRODUTO) SEM PRODUTOS EXPOSTOS?', '[MESA DEDICADA (SMART TABLE)] POSSUI MESA DEDICADA À S7?', '[CONFIGURAÇÃO DE CONTA] O APARELHO POSSUI CONTA SAMSUNG E GOOGLE?', '[CONEXÃO INTERNET] O APARELHO ESTÁ CONECTADO À INTERNET?', '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?', '[RETAIL MODE] LIGADO?', '[LIGADO] O APARELHO ESTÁ LIGADO?', '[COR S7 EDGE] QUAL?', 'MODELO:', '[COR S7 FLAT] QUAL?', '[ESPAÇAMENTO PAREDE DE ACESSÓRIOS] É MAIOR QUE 3CM (APROX. DOIS DEDOS)?']).pluck(:pos_code, :cycle).uniq

    questions = Record.where(question: ['[CONFIGURAÇÃO DE CONTA] O APARELHO POSSUI CONTA SAMSUNG E GOOGLE?', '[CONEXÃO INTERNET] O APARELHO ESTÁ CONECTADO À INTERNET?', '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?', '[RETAIL MODE] LIGADO?', '[LIGADO] O APARELHO ESTÁ LIGADO?']).pluck('DISTINCT question, pos_code, cycle, brand')

    stores.each do |record|
      total[record[0]] ||= {}
      total[record[0]][record[1]] ||= 0
      array_store[record[0]] ||= {}
      array_store[record[0]][record[1]] ||= []
      total_question_exposition[record[0]] ||= {}
      total_question_exposition[record[0]][record[1]] ||= 0
      valid[record[0]] = {}
      valid[record[0]][record[1]] = 0

      verify_s7[record[0]] ||= {}
      verify_s7[record[0]][record[1]] ||= 0
      verify_s7_edge[record[0]] ||= {}
      verify_s7_edge[record[0]][record[1]] ||= 0

      cor_s7[record[0]] ||= {}
      cor_s7[record[0]][record[1]] ||= []
      cor_s7_edge[record[0]] ||= {}
      cor_s7_edge[record[0]][record[1]] ||= []

      count_cor_s7[record[0]] ||= {}
      count_cor_s7[record[0]][record[1]] ||= 0
      count_cor_s7_edge[record[0]] ||= {}
      count_cor_s7_edge[record[0]][record[1]] ||= 0

      total_question_product[record[0]] ||= {}
      total_question_product[record[0]][record[1]] ||= {}

      product_points[record[0]] ||= {}
      product_points[record[0]][record[1]] ||= {}

    end

    records.each do |record|
      points[record[0]] ||= {}
      points[record[0]][record[3]] ||= {}
      points[record[0]][record[3]][record[1]] ||= '0'
    end

    records.each do |record|
      store = Store.where(pos_code: record[0], cycle: record[3]).pluck(:store_type)[0]

      case record[1]
      when '[SMART TABLE MESAS/BANCADAS] HÁ BURACOS (POSIÇÃO DO PRODUTO) SEM PRODUTOS EXPOSTOS?'
        total[record[0]][record[3]] += 24
        valid[record[0]][record[3]] += 24 if record[2] == 'NÃO'
        points[record[0]][record[3]][record[1]] = '24' if record[2] == 'NÃO'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'EXPOSICAO', points: points[record[0]][record[3]][record[1]])
      when '[ESPAÇAMENTO PAREDE DE ACESSÓRIOS] É MAIOR QUE 3CM (APROX. DOIS DEDOS)?'
        total[record[0]][record[3]] += 24
        valid[record[0]][record[3]] += 24 if record[2] == 'NÃO'
        points[record[0]][record[3]][record[1]] = '24' if record[2] == 'NÃO'
        StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'EXPOSICAO', points: points[record[0]][record[3]][record[1]])
      when '[MESA DEDICADA (SMART TABLE)] POSSUI MESA DEDICADA À S7?'
        if store == 'SES'
          total[record[0]][record[3]] += 24
          valid[record[0]][record[3]] += 24 if record[2] == 'SIM'
          points[record[0]][record[3]][record[1]] = '24' if record[2] == 'SIM'
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: record[2], brand: 'EXPOSICAO', points: points[record[0]][record[3]][record[1]])
        else
          StoreResult.where(pos_code: record[0], question_default: record[1]).update_all(answer: 'NÃO AVALIADO', brand: 'EXPOSICAO', points: '24')
        end
      when '[COR S7 FLAT] QUAL?'
        cor_s7[record[0]][record[3]] << record[2]
        count_cor_s7[record[0]][record[3]] += 1
      when '[COR S7 EDGE] QUAL?'
        cor_s7_edge[record[0]][record[3]] << record[2]
        count_cor_s7_edge[record[0]][record[3]] += 1
      when 'MODELO:'
        if record[2] == 'GALAXY S7 - 4G - SS'
          verify_s7[record[0]][record[3]] += 1
        elsif record[2] == 'GALAXY S7 EDGE - 4G - SS'
          verify_s7_edge[record[0]][record[3]] += 1
        end
       when '[CONFIGURAÇÃO DE CONTA] O APARELHO POSSUI CONTA SAMSUNG E GOOGLE?', '[CONEXÃO INTERNET] O APARELHO ESTÁ CONECTADO À INTERNET?', '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?', '[RETAIL MODE] LIGADO?', '[LIGADO] O APARELHO ESTÁ LIGADO?'
        total_question_product[record[0]][record[3]][record[1]] ||= 0
        product_points[record[0]][record[3]][record[1]] ||= 0

        total_question_product[record[0]][record[3]][record[1]] += 1
        product_points[record[0]][record[3]][record[1]] += 1 if record[2] == 'SIM'
      end
    end

    stores.each do |store|

      total_question_exposition[store[0]][store[1]] += 8
      total[store[0]][store[1]] += 12
      total[store[0]][store[1]] += 24
      total[store[0]][store[1]] += 12

      if verify_s7[store[0]][store[1]] >= 1 && verify_s7_edge[store[0]][store[1]] >= 1
        valid[store[0]][store[1]] += 24
        points[store[0]][store[1]]['MODELO:'] = '24'
        StoreResult.where(pos_code: store[0], question_default: 'MODELO:').update_all(answer: 'SIM', brand: 'EXPOSICAO', points: points[store[0]][store[1]]['MODELO:'])
      else
        StoreResult.where(pos_code: store[0], question_default: 'MODELO:').update_all(answer: 'NAO', brand: 'EXPOSICAO', points: '0')
      end

      if !cor_s7_edge[store[0]][store[1]].nil?
        if cor_s7_edge[store[0]][store[1]].count >= 1
          valid[store[0]][store[1]] += 12
          points[store[0]][store[1]]['[COR S7 EDGE] QUAL?'] = '12'
          new_answer = (((cor_s7_edge[store[0]][store[1]].uniq.count).to_f/4) * 100).to_s
          StoreResult.where(pos_code: store[0], question_default: '[COR S7 EDGE] QUAL?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: points[store[0]][store[1]]['[COR S7 EDGE] QUAL?'])
        else
          new_answer = (((cor_s7_edge[store[0]][store[1]].uniq.count).to_f/4) * 100).to_s
          StoreResult.where(pos_code: store[0], question_default: '[COR S7 EDGE] QUAL?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: '0')
        end
      end

      if !cor_s7[store[0]][store[1]].nil?
        if cor_s7[store[0]][store[1]].count >= 1
          valid[store[0]][store[1]] += 12
          points[store[0]][store[1]]['[COR S7 FLAT] QUAL?'] = '12'
          new_answer = (((cor_s7[store[0]][store[1]].uniq.count).to_f/4) * 100).to_s
          StoreResult.where(pos_code: store[0], question_default: '[COR S7 FLAT] QUAL?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: points[store[0]][store[1]]['[COR S7 FLAT] QUAL?'])
        else
          new_answer = (((cor_s7[store[0]][store[1]].uniq.count).to_f/4) * 100).to_s
          StoreResult.where(pos_code: store[0], question_default: '[COR S7 FLAT] QUAL?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: '0')
        end
      end
    end

    # question, pos_code, cycle, brand

    questions.each do |question|
      store = Store.where(pos_code: question[1], cycle: question[2]).pluck(:store_type)[0]

      case question[0]
      when  '[CONFIGURAÇÃO DE CONTA] O APARELHO POSSUI CONTA SAMSUNG E GOOGLE?'
        total[question[1]][question[2]] += 24
        if ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100) >= 80.0
          valid[question[1]][question[2]] += 24
          points[question[1]][question[2]][question[0]] = '24'
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[CONFIGURAÇÃO DE CONTA] O APARELHO POSSUI CONTA SAMSUNG E GOOGLE?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: points[question[1]][question[2]][question[0]])
        else
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[CONFIGURAÇÃO DE CONTA] O APARELHO POSSUI CONTA SAMSUNG E GOOGLE?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: '0')
        end
      when  '[CONEXÃO INTERNET] O APARELHO ESTÁ CONECTADO À INTERNET?'
        total[question[1]][question[2]] += 24
        if ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100) >= 80.0
          valid[question[1]][question[2]] += 24
          points[question[1]][question[2]][question[0]] = '24'
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[CONEXÃO INTERNET] O APARELHO ESTÁ CONECTADO À INTERNET?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: points[question[1]][question[2]][question[0]])
        else
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[CONEXÃO INTERNET] O APARELHO ESTÁ CONECTADO À INTERNET?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: '0')
        end
      when '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?'
        if store == "SES"
        total[question[1]][question[2]] +=24
          if ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100) == 100.0
            valid[question[1]][question[2]] += 24
            points[question[1]][question[2]][question[0]] = '24'
            new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
            StoreResult.where(pos_code: question[1], question_default: '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: points[question[1]][question[2]][question[0]])
          else
            new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
            StoreResult.where(pos_code: question[1], question_default: '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: '0')
          end
        else
          StoreResult.where(pos_code: question[1], question_default: '[LOCALIZAÇÃO PRECIFICADOR] ESTÁ À DIREITA?').update_all(answer: 'NÃO AVALIADO', brand: 'EXPOSICAO', points: '24')
        end
      when '[LIGADO] O APARELHO ESTÁ LIGADO?'
        total[question[1]][question[2]] += 24
        if ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100) == 100.0
          valid[question[1]][question[2]] += 24
          points[question[1]][question[2]][question[0]] = '24'
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[LIGADO] O APARELHO ESTÁ LIGADO?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: points[question[1]][question[2]][question[0]])
        else
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[LIGADO] O APARELHO ESTÁ LIGADO?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: '0')
        end
      when '[RETAIL MODE] LIGADO?'
        total[question[1]][question[2]] += 24
        if ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100) >= 90.0
          valid[question[1]][question[2]] += 24
          points[question[1]][question[2]][question[0]] = '24'
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[RETAIL MODE] LIGADO?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: points[question[1]][question[2]][question[0]])
        else
          new_answer = ((product_points[question[1]][question[2]][question[0]].to_f / total_question_product[question[1]][question[2]][question[0]]) * 100).to_s
          StoreResult.where(pos_code: question[1], question_default: '[RETAIL MODE] LIGADO?').update_all(answer: new_answer, brand: 'EXPOSICAO', points: '0')
        end
      end
    end

    valid.each do |pos_code, cycles|
      cycles.each do |cycle, valid_total|
        Store.where(pos_code: pos_code, cycle: cycle).update_all(points_exposition: valid_total.to_s)
        if ((valid_total.to_f / total[pos_code][cycle]) * 100) >= 70.0
          Store.where(pos_code: pos_code, cycle: cycle).update_all(exposition: true)
        end
      end
    end
    puts "Done!"
  end


  task depara_correct_questions: :environment do
    depara_correct_questions
  end

  def depara_correct_questions
    puts "Start"

    StoreResult.where(question_dashboard: 'TODOS OS APARELHOS EM EXPOSIÇÃO ESTAM CONECTADOS A INTERNET?').update_all(question_dashboard: 'TODOS OS APARELHOS EM EXPOSIÇÃO ESTÃO CONECTADOS A INTERNET?')
    StoreResult.where(question_dashboard: 'OS APARELHOS POSSUIM CONTA SAMSUNG E GOOGLE CONFIGURADOS?').update_all(question_dashboard: 'OS APARELHOS POSSUEM CONTA SAMSUNG E GOOGLE CONFIGURADOS?')

    puts "Done!"
  end

  task change_question_in_action_plans: :environment do
    change_question_in_action_plans
  end

  def change_question_in_action_plans

    puts "Start change!"

    file = File.read(Rails.root + 'lib/assets/rules.json')
    json = JSON.parse(file)
    array = {}
    stores = Store.pluck(:pos_code)
    # 0 => QUESTION_FORM, 1 => QUESTION_DASH, 2 => CRITERION, 3 => POINTS
    json.each do |value|
      ActionPlan.where(item: value[0]).update_all(item: value[1])
    end

    ActionPlan.where(item: 'NA PAREDE DE ACESSÓRIOS O ESPAÇAMENTO ENTRE OS PRODUTOS É MAIOR QUE 3 CM (APROX. 2 DEDOS)?').update_all(item: 'NA PAREDE DE ACESSÓRIOS O ESPAÇAMENTO ENTRE OS PRODUTOS É MAIOR QUE 3 CM (APROX 2 DEDOS)?')
    StoreResult.where(question_dashboard: 'NA PAREDE DE ACESSÓRIOS O ESPAÇAMENTO ENTRE OS PRODUTOS É MAIOR QUE 3 CM (APROX. 2 DEDOS)?').update_all(question_dashboard: 'NA PAREDE DE ACESSÓRIOS O ESPAÇAMENTO ENTRE OS PRODUTOS É MAIOR QUE 3 CM (APROX 2 DEDOS)?')

    ActionPlan.where(item: 'O VENDEDOR ABORDOU O COMP. MISTERIOSO COM ATITUDE AMIGÁVEL E CORTÊS?').update_all(item: 'O VENDEDOR ABORDOU O COMPRADOR MISTERIOSO COM ATITUDE AMIGÁVEL E CORTÊS?')
    StoreResult.where(question_dashboard: 'O VENDEDOR ABORDOU O COMP. MISTERIOSO COM ATITUDE AMIGÁVEL E CORTÊS?').update_all(question_dashboard: 'O VENDEDOR ABORDOU O COMPRADOR MISTERIOSO COM ATITUDE AMIGÁVEL E CORTÊS?')

    ActionPlan.where(item: 'O VENDEDOR REALIZOU PERGUNTAS PARA IDENTIFICAR AS NECESSIDADES DO COMP. MISTERIOSO?').update_all(item: 'O VENDEDOR REALIZOU PERGUNTAS PARA IDENTIFICAR AS NECESSIDADES DO COMPRADOR MISTERIOSO?')
    StoreResult.where(question_dashboard: 'O VENDEDOR REALIZOU PERGUNTAS PARA IDENTIFICAR AS NECESSIDADES DO COMP. MISTERIOSO?').update_all(question_dashboard: 'O VENDEDOR REALIZOU PERGUNTAS PARA IDENTIFICAR AS NECESSIDADES DO COMPRADOR MISTERIOSO?')

    puts "Done!"
  end

  task remove_question_old_to_action_plans: :environment do
    remove_question_old_to_action_plans
  end

  def remove_question_old_to_action_plans
    puts "removing question !"
    ActionPlan.where(item: '[QTD CALÇADO PRETO (MULHER)] QUANTIDADE DE VENDEDORAS COM CALÇADO PRETO CORRETO?').delete_all()
    puts "Done!"
  end

  task change_question_in_brand_attendant: :environment do
    change_question_in_brand_attendant
  end

  def change_question_in_brand_attendant
    puts "Start change!"
    ActionPlan.where(item: 'A LOJA CAPTA DADOS DE CLIENTE PARA CRM?').update_all(item: 'A LOJA POSSUI REGISTRO DE CLIENTE?')
    StoreResult.where(question_dashboard: 'A LOJA CAPTA DADOS DE CLIENTE PARA CRM?').update_all(question_dashboard: 'A LOJA POSSUI REGISTRO DE CLIENTE?')
    puts "Done!"
  end

  task populate_stores_execution: :environment do
    populate_stores_execution
  end

  def populate_stores_execution
    puts 'Start: populate_stores_execution!'
    Record.pluck(:pos_code, :cycle, :execution_date_time).uniq.each do |row|
    Store.where(pos_code: row[0], cycle: row[1]).update_all(execution_date_time: row[2])
    end
  end

  task update_lat_long_to_stores: :environment do
    update_lat_long_to_stores
  end

  def update_lat_long_to_stores
    puts "Start update to store"
    Store.where(pos_code: '17655759000458').update_all(longitude: '-40.289293', latitude: '-20.341915')
    Store.where(pos_code: '17655759000610').update_all(longitude: '-40.287898', latitude: '-20.312624')
    Store.where(pos_code: '17655759000709').update_all(longitude: '-40.297474', latitude: '-20.351948')
    Store.where(pos_code: '17655759000881').update_all(longitude: '-40.400379', latitude: '-20.343293')
    Store.where(pos_code: '17655759000105').update_all(longitude: '-40.287772', latitude: '-20.312531')
    Store.where(pos_code: '17655759000539').update_all(longitude: '-40.275136', latitude: '-20.240015')
    puts "Start update to record"
    Record.where(pos_code: '17655759000458').update_all(longitude: '-40.289293', latitude: '-20.341915')
    Record.where(pos_code: '17655759000610').update_all(longitude: '-40.287898', latitude: '-20.312624')
    Record.where(pos_code: '17655759000709').update_all(longitude: '-40.297474', latitude: '-20.351948')
    Record.where(pos_code: '17655759000881').update_all(longitude: '-40.400379', latitude: '-20.343293')
    Record.where(pos_code: '17655759000105').update_all(longitude: '-40.287772', latitude: '-20.312531')
    Record.where(pos_code: '17655759000539').update_all(longitude: '-40.275136', latitude: '-20.240015')
    puts "Done!"
  end

  task change_rule_critetion: :environment do
    change_rule_critetion
  end

  def change_rule_critetion
    puts "Start Change!"
    StoreResult.where(question_dashboard: ['HAVIA 100% DO SORTIMENTO DE CORES S7 EDGE?', 'HAVIA 100% DO SORTIMENTO DE CORES S7 FLAT?']).update_all(criterion: '25%')
    puts "Done!"
  end

end
