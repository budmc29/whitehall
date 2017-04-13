require 'test_helper'

class UrlToSubscriberListCriteriaTest < ActiveSupport::TestCase
  test "can convert department to organisation" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards',
      stub("StaticData", topical_event?: false),
    )
    assert_equal converter.map_url_to_hash, {
      "links" => { "organisations" => ["advisory-committee-on-clinical-excellence-awards"] },
    }
  end

  test "can convert when topic is not a topical_event" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?topics%5B%5D=wildlife-and-animal-welfare',
      stub("StaticData", topical_event?: false),
    )
    assert_equal converter.map_url_to_hash, {
      "links" => { "policy_areas" => ["wildlife-and-animal-welfare"] },
    }
  end

  test "can convert when topic is a topical_event" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?topics%5B%5D=spending-round-2013',
      stub("StaticData", topical_event?: true),
    )
    assert_equal converter.map_url_to_hash, {
      "links" => { "topical_events" => ["spending-round-2013"] },
    }
  end

  test "ignores trailing whitespace" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards  ',
      stub("StaticData", topical_event?: false),
    )
    assert_equal converter.map_url_to_hash, {
      "links" => {
        "organisations" => ["advisory-committee-on-clinical-excellence-awards"],
      },
    }
  end

  test "can convert multiple options" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards&topics%5B%5D=employment ',
      stub("StaticData", topical_event?: false),
    )
    assert_equal converter.map_url_to_hash, {
      "links" => {
        "organisations" => ["advisory-committee-on-clinical-excellence-awards"],
        "policy_areas" => ["employment"],
      },
    }
  end

  test "will map links values to content_ids" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards',
      stub("StaticData", topical_event?: false, content_id: 'aaaaa'),
    )
    assert_equal converter.convert, {
      "links" => { "organisations" => ["aaaaa"] },
    }
  end

  test "can extract `email_document_supertype` and `government_document_supertype` from announcement url" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/announcements.atom?announcement_filter_option=news-stories',
      stub("StaticData"),
    )
    assert_equal converter.convert, {
      "links" => {},
      "email_document_supertype" => "announcements",
      "government_document_supertype" => "news-stories",
    }
  end

  test "can extract email `email_document_supertype` and `government_document_supertype` from publication url" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/publications.atom?publication_filter_option=transparency-data',
      stub("StaticData"),
    )

    assert_equal converter.convert, {
      "links" => {},
      "email_document_supertype" => "publications",
      "government_document_supertype" => "transparency-data",
    }
  end

  test "can extract `email_document_supertype` and `government_document_supertype` from statistics url" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/statistics.atom',
      stub("StaticData"),
    )

    assert_equal converter.convert, {
      "links" => {},
      "email_document_supertype" => "publications",
      "government_document_supertype" => "statistics",
    }
  end

  test "can detect missing mappings from slug to content_id" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=other',
      stub("StaticData", topical_event?: false, content_id: UrlToSubscriberListCriteria::MISSING_LOOKUP),
    )

    assert_equal converter.convert, {
      "links" => { "organisations" => ["*** MISSING KEY ***"] },
    }
    assert_equal converter.missing_lookup, "organisations: other"
  end

  test "can detect multiple missing mappings from slug to content_id" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=other&topics%5B%5D=unknown',
      stub("StaticData", topical_event?: false, content_id: UrlToSubscriberListCriteria::MISSING_LOOKUP),
    )

    assert_equal converter.convert, {
      "links" => {
        "organisations" => ["*** MISSING KEY ***"],
        "policy_areas" => ["*** MISSING KEY ***"],
      },
    }
    assert_equal converter.missing_lookup, "organisations: other and policy_areas: unknown"
  end

  test "does not incorrectly detect missing mapping from slug to content id" do
    converter = UrlToSubscriberListCriteria.new(
      'https://www.gov.uk/government/feed?departments%5B%5D=advisory-committee-on-clinical-excellence-awards',
      stub("StaticData", topical_event?: false, content_id: 'aaaaa-111111'),
    )

    assert !converter.missing_lookup
  end
end
