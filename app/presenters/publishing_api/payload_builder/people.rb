module PublishingApi
  module PayloadBuilder
    class People
      attr_reader :item
      def self.for(item)
        self.new(item).call
      end

      def initialize(item)
        @item = item
      end

      def call
        {}
          .merge(people_form_role_appointment)
          .merge(people_from_role_appointments)
      end

    private

      def people_form_role_appointment
        return {} unless item.respond_to?(:role_appointment)

        { people: [item.role_appointment.person.content_id] }
      end

      def people_from_role_appointments
        return {} unless item.respond_to?(:role_appointments)

        { people: item.role_appointments.map(&:person).collect(&:content_id) }
      end
    end
  end
end
