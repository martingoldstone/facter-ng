# frozen_string_literal: true

module Facter
  class FactLoader
    include Singleton

    attr_reader :internal_facts, :external_facts, :facts

    def initialize
      @log = Log.new

      @internal_facts = []
      @external_facts = []
      @facts = []

      @internal_loader = InternalFactLoader.new
      @external_fact_loader = ExternalFactLoader.new
    end

    def load(options)
      load_internal_facts(options)
      load_external_facts(options)

      @facts
    end

    private

    def load_internal_facts(options)
      @log.debug('Loading internal facts')
      if options[:user_query] || options[:show_legacy]
        # if we have a user query, then we must search in core facts and legacy facts
        @log.debug('Loading all internal facts')
        @internal_facts = @internal_loader.facts
      else
        @log.debug('Load only core facts')
        @internal_facts = @internal_loader.core_facts
      end

      @facts.concat(@internal_facts)
    end

    def load_external_facts(options)
      @log.debug('Loading external facts')
      unless options[:no_custom_facts]
        @log.debug('Loading custom facts')
        @external_facts.concat(@external_fact_loader.custom_facts)
      end

      unless options[:no_external_facts]
        @log.debug('Loading external facts')
        @external_facts.concat(@external_fact_loader.external_facts)
      end

      @facts.concat(@external_facts)
    end
  end
end
