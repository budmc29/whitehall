module PublishingApi
  module PayloadBuilder
    class Roles
      attr_reader :item

      def self.for(item)
        self.new(item).call
      end

      def initialize(item)
        @item = item
      end

      def call
        {}
          .merge(roles_from_role_appointment)
          .merge(roles_from_role_appointments)
      end

      def roles_from_role_appointment
        return {} unless item.respond_to?(:role_appointment)

        { roles: [item.role_appointment.role.content_id] }
      end

      def roles_from_role_appointments
        return {} unless item.respond_to?(:role_appointments)

        { roles: item.role_appointments.map(&:role).collect(&:content_id) }
      end
    end
  end
end
