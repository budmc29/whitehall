require "test_helper"

module PublishingApi
  module PayloadBuilder
    class PayloadBuilderPeopleTest < ActiveSupport::TestCase
      test "returns empty hash if no role_appointment or edition_role_appointments" do
        edition_with_no_roles_or_people = Object.new
        assert_equal People.for(edition_with_no_roles_or_people), {}
      end

      test "returns single person when role_appointment is present but edition_role_appointments is not" do
        person = create(:person)
        role_appointment = create(:role_appointment, person: person)

        stubbed_edition = stub(role_appointment: role_appointment)
        expected_hash = { people: [person.content_id] }

        assert_equal expected_hash, People.for(stubbed_edition)
      end

      test "returns an array of content_ids from people in edition_role_appointments" do
        role_appointments = 3.times.map do
          create(:role_appointment, person: create(:person))
        end

        stubbed_edition = stub(role_appointments:  role_appointments)

        expected_hash = { people:
          role_appointments.map do |role_appointment|
            role_appointment.person.content_id
          end
        }

        assert_equal expected_hash, People.for(stubbed_edition)
      end
    end
  end
end
