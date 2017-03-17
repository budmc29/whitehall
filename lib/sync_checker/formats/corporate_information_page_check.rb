module SyncChecker
  module Formats
    class CorporateInformationPageCheck < EditionBase
      def expected_details_hash(corporate_information_page)
        super.tap do |details|
          details.except!(:change_history)
          details.except!(:emphasised_organisations)
          #does first_public_at (base_details)... need excepting?
          details.merge!(expected_tags(corporate_information_page))
          details.merge!(expected_organisation(corporate_information_page))
          #organisation... relation on model... pass in somehow
          details.merge!(expected_corporate_information_groups) #if something...
        end
      end

      def rendering_app
        Whitehall::RenderingApp::GOVERNMENT_FRONTEND
      end

      def root_path
        'government/organisations'
      end

      private

      def top_level_fields_hash(corporate_information_page, _)
        super.tap do |fields|
          fields[:document_type] = corporate_information_page.display_type_key
        end
      end

      def expected_tags(corporate_information_page)
        policies = if corporate_information_page.can_be_related_to_policies?
                     corporate_information_page.policies.map(&:slug)
                   end

        topics = Array(corporate_information_page.primary_specialist_sector_tag) +
        corporate_information_page.secondary_specialist_sector_tags

        {
          'tags' => {
            'browse_pages' => [],
            'policies' => policies.compact,
            'topics' => topics.compact,
          }
        }
      end

      def expected_organisation(corporate_information_page)
        {
          organisation: corporate_information_page.organisation.content_id
        }
      end

      def expected_corporate_information_groups
        {
          corporate_information_groups: corporate_information_groups
            .reject { |group| group[:contents].empty? }
        }
      end

      def corporate_information_groups
        [].tap do |groups|
        groups << {
          name: translation_for_group(:access_our_info),
          contents: contents_for_access_our_info.compact
        }

        groups << {
          name: translation_for_group(:jobs_and_contacts),
          contents: contents_for_jobs_and_contacts.compact,
        } unless organisation.court_or_hmcts_tribunal?
        end
      end

      def translation_for_group(group, namespace = :corporate_information)
        helpers.t("organisation.#{namespace}.#{group}")
      end

      def contents_for_access_our_info
        [].tap do |contents|
          contents.push(payload_for_organisation_chart)
          contents.push(*page_content_ids_by_menu_heading(:our_information))
          contents.push(payload_for_corporate_reports)
          contents.push(payload_for_transparency_data)
        end
      end

      def contents_for_jobs_and_contacts
        [].tap do |contents|
          contents.push(*page_content_ids_by_menu_heading(:jobs_and_contracts))
          contents.push(payload_for_jobs)
        end
      end

      def page_content_ids_by_menu_heading(menu_heading)
        organisation
          .corporate_information_pages
          .published
          .by_menu_heading(menu_heading)
          .map(&:content_id)
      end

      def organisation_has_corporate_report_publications?
        return unless organisation.present?

        organisation.has_published_publications_of_type?(
          PublicationType::CorporateReport,
        )
      end

      def organisation_has_chart_url?
        return unless organisation.present?

        organisation.organisation_chart_url.present?
      end


      def organisation_has_transparency_data_publications?
        return unless organisation.present?

        organisation.has_published_publications_of_type?(
          PublicationType::TransparencyData,
        )
      end

      def payload_for_corporate_reports
        return unless organisation_has_corporate_report_publications?

        corporate_reports_path =
          url_maker
            .publications_filter_path(
              organisation,
              publication_type: 'corporate-reports',
            )

        {
          title: translation_for_group(:corporate_reports, :headings),
          path: corporate_reports_path,
        }
      end

      def payload_for_jobs
        {
          title: 'Jobs',
          url: organisation.jobs_url,
        }
      end

      def payload_for_organisation_chart
        return unless organisation_has_chart_url?

        {
          title: translation_for_group(:organisation_chart),
          url: organisation.organisation_chart_url,
        }
      end

      def payload_for_transparency_data
        return unless organisation_has_transparency_data_publications?

        transparency_data_path =
          url_maker
            .publications_filter_path(
              organisation,
              publication_type: 'transparency-data',
            )

        {
          title: translation_for_group(:transparency),
          path: transparency_data_path,
        }
      end
    end
  end
end
