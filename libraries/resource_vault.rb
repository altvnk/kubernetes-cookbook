require 'chef/resource'

class Chef
  class Resource
    class Vault < Chef::Resource
      def initialize(name, run_context = nil)
        super

        @resource_name = :vault

        @allowed_actions.push(:configure_pki)
        @allowed_actions.push(:init)
        @allowed_actions.push(:install)
        @allowed_actions.push(:install_binaries)
        @allowed_actions.push(:issue_kubernetes_certificates)
        @allowed_actions.push(:renew_server_certificates)
        @allowed_actions.push(:trust_ca)
        @allowed_actions.push(:unseal)

        @action = :init

        @provider = Chef::Provider::Vault
      end

      def api_server(arg = nil)
        result = set_or_return(
          :api_server,
          arg,
          kind_of: String
        )

        ENV['VAULT_ADDR'] = result

        result
      end

      def ca_data_bag_name(arg = nil)
        set_or_return(
          :ca_data_bag_name,
          arg,
          kind_of: String
        )
      end

      def csr_file(arg = nil)
        set_or_return(
          :csr_file,
          arg,
          kind_of: String
        )
      end

      def cluster_name(arg = nil)
        set_or_return(
          :cluster_name,
          arg,
          kind_of: String
        )
      end

      def initial_token_data_bag_name(arg = nil)
        set_or_return(
          :initial_token_data_bag_name,
          arg,
          kind_of: String
        )
      end

      def initial_token_data_bag_item_name(arg = nil)
        set_or_return(
          :initial_token_data_bag_item_name,
          arg,
          kind_of: String
        )
      end

      def intermediate_ca_common_name(arg = nil)
        set_or_return(
          :intermediate_ca_common_name,
          arg,
          kind_of: String
        )
      end

      def intermediate_certificate_data_bag_item_name(arg = nil)
        set_or_return(
          :intermediate_certificate_data_bag_item_name,
          arg,
          kind_of: String
        )
      end

      def intermediate_certificate_file(arg = nil)
        set_or_return(
          :intermediate_certificate_file,
          arg,
          kind_of: String
        )
      end

      def kubernetes_certificate_file(arg = nil)
        set_or_return(
          :kubernetes_certificate_file,
          arg,
          kind_of: String
        )
      end

      def kubernetes_certificate_alt_names(arg = nil)
        set_or_return(
          :kubernetes_certificate_alt_names,
          arg,
          kind_of: String
        )
      end

      def kubernetes_certificate_common_name(arg = nil)
        set_or_return(
          :kubernetes_certificate_common_name,
          arg,
          kind_of: String
        )
      end

      def kubernetes_certificate_ip_sans(arg = nil)
        set_or_return(
          :kubernetes_certificate_ip_sans,
          arg,
          kind_of: String
        )
      end

      def kubernetes_key_file(arg = nil)
        set_or_return(
          :kubernetes_key_file,
          arg,
          kind_of: String
        )
      end

      def mount_path(arg = nil)
        set_or_return(
          :mount_path,
          arg,
          kind_of: String
        )
      end

      def package_url(arg = nil)
        set_or_return(
          :package_url,
          arg,
          kind_of: String
        )
      end

      def root_ca_common_name(arg = nil)
        set_or_return(
          :root_ca_common_name,
          arg,
          kind_of: String
        )
      end

      def server_certificate_file(arg = nil)
        set_or_return(
          :server_certificate_file,
          arg,
          kind_of: String
        )
      end

      def server_config_file(arg = nil)
        set_or_return(
          :server_config_file,
          arg,
          kind_of: String
        )
      end

      def server_key_file(arg = nil)
        set_or_return(
          :server_key_file,
          arg,
          kind_of: String
        )
      end

      def trusted_ca_data_bag_item_name(arg = nil)
        set_or_return(
          :trusted_ca_data_bag_item_name,
          arg,
          kind_of: String
        )
      end

      def trusted_ca_file(arg = nil)
        set_or_return(
          :trusted_ca_file,
          arg,
          kind_of: String
        )
      end

      def trusted_server_certificate_file(arg = nil)
        set_or_return(
          :trusted_server_certificate_file,
          arg,
          kind_of: String
        )
      end

      def unseal_keys_data_bag_name(arg = nil)
        set_or_return(
          :unseal_keys_data_bag_name,
          arg,
          kind_of: String
        )
      end

      def unseal_keys_data_bag_item_name(arg = nil)
        set_or_return(
          :unseal_keys_data_bag_item_name,
          arg,
          kind_of: String
        )
      end
    end
  end
end
