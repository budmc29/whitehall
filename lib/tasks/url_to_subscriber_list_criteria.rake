desc "Migrate govuk delivery topics to email alert api"
task url_to_subscriber_list_criteria: :environment do
  require 'gds_api/helpers'
  include GdsApi::Helpers

  invalid = []
  parsed = 0
  skipped = 0
  missing_lookup = 0
  CSV.foreach(ARGV[-1], headers: true) do |row|
    parser = UrlToSubscriberListCriteria.new(row['_id'])
    if parser.skip?
      skipped += 1
    elsif parser.valid?
      if ENV['MIGRATE_TO_EMAIL_API']
        if parser.hash['links'].empty?
          print 'o'
        else
          real = (parser.hash.keys & ['whitehall_supertype', 'whitehall_subtype']).empty?
          hash = parser.call.merge(gov_delivery_id: row['topic_id'])

          # this is a hack so we get the right number in EmailAlertApi but they won't match anything..
          hash["document_type"] = hash.slice('whitehall_supertype', 'whitehall_subtype').values.join(' - ')

          response = email_alert_api.find_or_create_subscriber_list(hash)

          if response['subscriber_list']['gov_delivery_id'] == row['topic_id']
            if Date.parse(response['subscriber_list']['created_at']) < Date.today
              print real ? 'e' : 'E'
            else
              print real ? '.' : '-'
            end
          else
            # this is a hack and needs some more thought.
            # Required as the find does NOT take gov_delivery_id into account
            response = email_alert_api.send(:create_subscriber_list, parser.call.merge(gov_delivery_id: row['topic_id']))
            print real ? "d" : "D"
          end
        end
      else
        puts "# Parseing #{row['topic_id']} - #{row['_id']}"
        pp parser.hash
        pp parser.call
        puts ''
        parser.call
      end

      parsed += 1
      missing_lookup += 1 if parser.missing_lookup
    else
      invalid << row['_id']
    end
  end
  puts "#{invalid.count} invalid, #{parsed} parsed with #{missing_lookup} having invalid data, #{skipped} skipped here are 10 random skipped url to think about"
  invalid.shuffle.first(10).each { |s| puts s }
end
