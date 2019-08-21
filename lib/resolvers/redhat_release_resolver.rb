# frozen_string_literal: true

class RedHatReleaseResolver < BaseResolver
  # :name
  # :version
  # :codename

  class << self
    @@semaphore = Mutex.new
    @@fact_list ||= {}

    def resolve(fact_name)
      @@semaphore.synchronize do
        result ||= @@fact_list[fact_name]

        return result unless result.nil?

        output, _status = Open3.capture2('cat /etc/redhat-release')

        output_strings = output.split('release')
        version_codename = output_strings[1].split(' ')

        @@fact_list[:name] = output_strings[0].strip
        @@fact_list[:version] = version_codename[0].strip
        codename = version_codename[1].strip
        @@fact_list[:codename] = codename.gsub(/[()]/, "")

        return @@fact_list[fact_name]
      end
    end
  end
end
