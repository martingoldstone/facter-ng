# frozen_string_literal: true

module Facter
  class ExternalFactManager
    def resolve_facts(searched_facts)
      searched_facts = filter_external_facts(searched_facts)
      external_facts(searched_facts)
    end

    private

    def filter_external_facts(searched_facts)
      searched_facts.select { |searched_fact| %i[custom external].include?(searched_fact.type) }
    end

    def external_facts(custom_facts)
      LegacyFacter.search("#{ROOT_DIR}/custom_facts")
      LegacyFacter.search_external(["#{ROOT_DIR}/external_facts"])

      resolved_custom_facts = []

      custom_facts.each do |custom_fact|
        fact_value = LegacyFacter.value(custom_fact.name)
        resolved_fact = ResolvedFact.new(custom_fact.name, fact_value)
        resolved_fact.filter_tokens = []
        resolved_fact.user_query = custom_fact.user_query

        resolved_custom_facts << resolved_fact
      end

      resolved_custom_facts
    end
  end
end
