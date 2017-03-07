require 'test_helper'

class FeedUrlToSubscriberListCriteriaTest < ActiveSupport::TestCase
  test "can convert department to organisation" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards',
      stub("StaticData", topical_event?: false),
    )
    assert converter.valid?
    assert_equal converter.hash, {
      "links" => {
        "organisations" => ["advisory-committee-on-clinical-excellence-awards"]
      }
    }
  end

  test "can convert when topic is not a topical_event" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?topics%5B%5D=wildlife-and-animal-welfare',
      stub("StaticData", topical_event?: false),
    )
    assert converter.valid?
    assert_equal converter.hash, { "links" => { "policy_areas" => ["wildlife-and-animal-welfare"] } }
  end

  test "can convert when topic is a topical_event" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?topics%5B%5D=spending-round-2013',
      stub("StaticData", topical_event?: true),
    )
    assert converter.valid?
    assert_equal converter.hash, { "links" => { "topical_events" => ["spending-round-2013"] } }
  end

  test "ignores trailing whitespace" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards  ',
      stub("StaticData", topical_event?: false),
    )
    assert converter.valid?
    assert_equal converter.hash, {
      "links" => {
        "organisations" => ["advisory-committee-on-clinical-excellence-awards"]
      }
    }
  end

  test "can convert multiple options" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards&topics%5B%5D=employment ',
      stub("StaticData", topical_event?: false),
    )
    assert converter.valid?
    assert_equal converter.hash, { "links" => { "organisations" => ["advisory-committee-on-clinical-excellence-awards"], "policy_areas" => ["employment"] } }
  end

  test "will map links values to content_ids" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards',
      stub("StaticData", topical_event?: false, content_id: 'aaaaa'),
    )
    assert converter.valid?
    assert_equal converter.call, {
      "links" => {
        "organisations" => ["aaaaa"]
      }
    }
  end

  test "can extract whitehall supertype and subtype from announcement url" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/announcements.atom?announcement_filter_option=news-stories',
      stub("StaticData"),
    )
    assert converter.valid?
    assert_equal converter.call, {
      "links" => {},
      "whitehall_supertype" => "announcements",
      "whitehall_subtype" => "news-stories"
    }
  end

  test "can extract whitehall supertype and subtype from publication url" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/publications.atom?publication_filter_option=transparency-data',
      stub("StaticData"),
    )

    assert converter.valid?
    assert_equal converter.call, {
      "links" => {},
      "whitehall_supertype" => "publications",
      "whitehall_subtype" => "transparency-data"
    }
  end

  test "can extract whitehall subtype from statistics url" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/statistics.atom',
      stub("StaticData"),
    )

    assert converter.valid?
    assert_equal converter.call, {
      "links" => {},
      "whitehall_subtype" => "statistics"
    }
  end
end
