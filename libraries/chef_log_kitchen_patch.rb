if ENV['TEST_KITCHEN']
  class Chef
    class Log
      # without this `Chef::Log.info` calls will NOT appear in `kitchen converge` output
      def self.info(message)
        puts "\n\tINFO: #{message}"
      end
    end
  end
end
