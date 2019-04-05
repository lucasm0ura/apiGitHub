require 'benchmark'
require 'rest_client'

namespace :baseman_auditoria do

  desc "TODO"
  task sync: :environment do
    bm = Benchmark.measure do

      campaign_id = Rails.application.config.baseman_auditoria_brandshop[:campaign_id]
      resource = RestClient::Resource.new("#{Rails.application.config.baseman_auditoria_brandshop[:base_url]}/api/v1/baseman.json", headers: { charset: "utf-8", authorization: "#{ActionController::HttpAuthentication::Token.encode_credentials(Rails.application.config.baseman_auditoria_brandshop[:token])}" })

      loop do
        max_visit_id = Record.where(campaign_id: campaign_id).maximum(:visit_id)

        puts "Quering from VISIT_ID: #{max_visit_id}"

        has_data = false
        resource.get(params: {visit_id: max_visit_id, campaign_id: campaign_id, }) do |response, request, result, &block|
          response.return!(request, result, &block) if response.code != 200

          data = Record.new
          ActiveRecord::Base.transaction do
            ActiveSupport::JSON.decode(response).each do |record|
              has_data = true
              attributes = {}  

              Record.attribute_names.each do |k|
                attributes[k] = record[k]
                attributes['campaign_id'] = campaign_id
              end
              Record.create(attributes)
            end
          end
        end

        break unless has_data
      end
    end

  end

end
