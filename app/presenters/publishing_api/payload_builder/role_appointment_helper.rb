module PublishingApi
  module PayloadBuilder
    module RoleAppointmentHelper
      def has_role_appointment?(item)
        item.respond_to?(:role_appointment) && item.role_appointment.present?
      end

      def has_role_appointments?(item)
        item.respond_to?(:role_appointments) && item.role_appointments.present?
      end
    end
  end
end
