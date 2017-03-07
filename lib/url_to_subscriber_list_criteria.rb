require 'uri'

class UrlToSubscriberListCriteria
  MISSING_LOOKUP = "*** MISSING KEY ***"
  SUBTYPE = "whitehall_subtype" # need to name this thing
  SUPERTYPE = "whitehall_supertype" # need to name this thing

  attr_reader :missing_lookup

  def initialize(url, static_data=StaticData)
    @url = URI.parse(url.strip)
    @static_data = static_data
    @missing_lookup = false
  end

  def skip?
    @url.path =~ %r{^/government/policies/.*/activity.atom$} || # these have already been migrated (I think)
      @url.path == "/government/policies.atom" || # not 100% sure what these are or where they come from

      @url.query =~ /official_document_status=/ || # to be removed
      @url.query =~ /relevant_to_local_government=1/ # to be removed
  end

  def valid?
    !hash.nil?
  end

  def call
    links = hash["links"].each_with_object({}) do |(key, values), result|
      result[key] = values.map { |value| lookup_content_id(key, value) }
    end
    hash.merge("links" => links)
  end

  def hash
    @hash ||= begin
      hash = if @url.path == "/government/feed" || @url.path == "/government/feed.atom"
         { 'links' => from_params }
      elsif result = @url.path.match(%r{^/government/world/(.*)\.atom$})
        { "links" => from_params.merge("world_locations" => [result[1]]) }
      elsif result = @url.path.match(%r{^/government/topical-events/(.*)\.atom$})
        { "links" => from_params.merge("topical_events" => [result[1]]) }
      elsif result = @url.path.match(%r{^/government/people/(.*)\.atom$})
        { "links" => from_params.merge("ministers" => [result[1]]) }
      elsif result = @url.path.match(%r{^/government/organisations/(.*)\.atom$})
        { "links" => from_params.merge("organisations" => [result[1]]) }
      elsif result =@url.path.match(%r{^/government/topics/(.*)\.atom$})
        { "links" => from_params.merge(topic_map([result[1]]) => [result[1]]) }
      elsif result =@url.path.match(%r{^/government/ministers/(.*)\.atom$})
        { "links" => from_params.merge("roles" => [result[1]]) } # this is not yet implemented


      elsif result = @url.path.match(%r{^/government/statistics\.atom$})
        { "links" => from_params, SUBTYPE => "statistics" } # this is not yet implemented
      elsif result = @url.path.match(%r{^/government/publications\.atom$})
        { "links" => from_params, SUPERTYPE => "publications" } # this is not yet implemented
      elsif result = @url.path.match(%r{^/government/announcements\.atom$})
        { "links" => from_params, SUPERTYPE => "announcements" } # this is not yet implemented

      else
        nil
      end

      # we want these to be a top level fields not link options
      if hash && hash["links"]["publication_filter_option"]
        hash[SUBTYPE] = hash["links"].delete("publication_filter_option") # this is not yet implemented
      end
      if hash && hash["links"]["announcement_filter_option"]
        hash[SUBTYPE] = hash["links"].delete("announcement_filter_option") # this is not yet implemented
      end

      hash
    end
  end

  def from_params
    return {} if @url.query.blank?

    hash = Rack::Utils.parse_nested_query(@url.query)
    {
      'departments' => 'organisations',
      'topics' => method(:topic_map),
      'policies' => 'related_policies',
    }.each do |from_key, to_key|
      next unless hash.key?(from_key)

      if to_key.is_a?(String)
        hash[to_key] = hash.delete(from_key)
      else
        value = hash.delete(from_key)
        hash[to_key.call(value)] = value
      end
    end
    hash
  end

  def topic_map(values)
    @static_data.topical_event?(values) ? 'topical_events' : 'policy_areas'
  end

  def lookup_content_id(key, slug)
    @static_data.content_id(key, slug).tap do |value|
      @missing_lookup = true if value == MISSING_LOOKUP
    end
  end

  module StaticData
    def self.topical_event?(values)
      @topical_events ||= TopicalEvent.pluck(:slug)
      (@topical_events & values).any?
    end

    def self.content_id(key, slug)
      case key
      when "world_locations"
        @world_location_lookup ||= Hash[WorldLocation.pluck(:slug, :content_id)]
        @world_location_lookup.fetch(slug, UrlToSubscriberListCriteria::MISSING_LOOKUP)
      when "organisations"
        @organisation_lookup ||= Hash[Organisation.pluck(:slug, :content_id)]
        @organisation_lookup.fetch(slug, UrlToSubscriberListCriteria::MISSING_LOOKUP)
      when "roles"
        @role_lookup ||= Hash[Role.pluck(:slug, :content_id)]
        @role_lookup.fetch(slug, UrlToSubscriberListCriteria::MISSING_LOOKUP)
      when "ministers"
        @people_lookup ||= Hash[Person.pluck(:slug, :content_id)]
        @people_lookup.fetch(slug, UrlToSubscriberListCriteria::MISSING_LOOKUP)

      when "policy_areas", "topical_events"
        @classifications_lookup ||= Hash[Classification.pluck(:slug, :content_id)]
        @classifications_lookup.fetch(slug, UrlToSubscriberListCriteria::MISSING_LOOKUP)

      else
        raise [key, slug]
      end
    end
  end
end
