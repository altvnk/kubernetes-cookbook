class Chef
  class Provider
    class Vault < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut

      use_inline_resources

      action :init do
        vault_shell_call = vault_shell_call(['init'])
        vault_shell_call.stdout.each_line.with_index do |line, index|
          process_unseal_keys_output line, index
          process_initial_root_token_output line
        end
      end

      action :install do
        server_config_dir = ::File.dirname new_resource.server_config_file
        server_key_dir = ::File.dirname new_resource.server_key_file
        server_certificate_dir = ::File.dirname new_resource.server_certificate_file
        trusted_server_certificate_dir = ::File.dirname new_resource.trusted_server_certificate_file

        directory server_config_dir do
          action :nothing
          recursive true
          not_if { ::File.file? server_config_dir }
        end.run_action(:create)

        directory server_key_dir do
          action :nothing
          recursive true
          not_if { ::File.file? server_key_dir }
        end.run_action(:create)

        directory server_certificate_dir do
          action :nothing
          recursive true
          not_if { ::File.file? server_certificate_dir }
        end.run_action(:create)

        directory trusted_server_certificate_dir do
          action :nothing
          recursive true
          not_if { ::File.file? trusted_server_certificate_dir }
        end.run_action(:create)

        openssl_rsa_key new_resource.server_key_file do
          action :nothing
          not_if { ::File.exist? new_resource.server_key_file }
          key_length 2048
        end.run_action(:create)

        openssl_x509 new_resource.server_certificate_file do
          action :nothing
          not_if { ::File.exist? new_resource.server_certificate_file }
          common_name node['fqdn']
          key_file new_resource.server_key_file
          org 'K8s Infra'
          org_unit 'Lab'
          country 'US'
          subject_alt_name ['IP:' + node['ipaddress']]
          expire 1825
        end.run_action(:create)

        file new_resource.trusted_server_certificate_file do
          action :nothing
          not_if { ::File.exist? new_resource.trusted_server_certificate_file }
          mode '0644'
          content ::File.open(new_resource.server_certificate_file).read
        end.run_action(:create)

        update_ca_trust

        new_resource.run_action(:install_binaries)

        template '/etc/systemd/system/vault.service' do
          action :nothing
          mode '0640'
          source 'vault.erb'
          variables(
            server_config_file: new_resource.server_config_file
          )
        end.run_action(:create)

        template new_resource.server_config_file do
          action :nothing
          mode '0640'
          source 'vault-config.erb'
          variables(
            cluster_name: new_resource.cluster_name,
            server_certificate_file: new_resource.server_certificate_file,
            server_key_file: new_resource.server_key_file,
            node_addr: node['ipaddress']
          )
        end.run_action(:create)

        service 'vault' do
          action [:enable, :start]
        end

      end

      action :install_binaries do
        remote_file new_resource.package_url do
          action :nothing
          not_if { ::File.exist? "#{Chef::Config[:file_cache_path]}/vault_package.zip" }
          path "#{Chef::Config[:file_cache_path]}/vault_package.zip"
          source new_resource.package_url
        end.run_action(:create)

        zipfile "#{Chef::Config[:file_cache_path]}/vault_package.zip" do
          action :nothing
          not_if { ::File.exist? '/usr/local/bin/vault' }
          into '/usr/local/bin'
        end.run_action(:extract)
      end

      action :configure_pki do
        # put CA certificate to databag for distribution
        if ::File.file? new_resource.trusted_ca_file
          trusted_ca_data_bag_data = {
            'id' => new_resource.trusted_ca_data_bag_item_name,
            'ca_cert' => ::File.open(new_resource.trusted_ca_file).read
          }

          Chef::Log.info("#{new_resource.name}: trusted_ca_data_bag_data=#{trusted_ca_data_bag_data.to_json}")

          intermediate_certificate_data_bag_data = {
            'id' => new_resource.intermediate_certificate_data_bag_item_name,
            'interm_cert' => ::File.open(new_resource.intermediate_certificate_file).read
          }

          Chef::Log.info("#{new_resource.name}: intermediate_certificate_data_bag_data=#{intermediate_certificate_data_bag_data.to_json}")

          ca_data_bag = get_data_bag new_resource.ca_data_bag_name
          trusted_ca_data_bag_item = get_data_bag_item new_resource.ca_data_bag_name, trusted_ca_data_bag_data['id']
          intermediate_certificate_data_bag_item = get_data_bag_item new_resource.ca_data_bag_name, intermediate_certificate_data_bag_data['id']

          if ca_data_bag.nil?
            ca_data_bag = Chef::DataBag.new
            ca_data_bag.name new_resource.ca_data_bag_name
            ca_data_bag.create
          end

          if trusted_ca_data_bag_item.nil?
            trusted_ca_data_bag_item = Chef::DataBagItem.new
            trusted_ca_data_bag_item.raw_data = trusted_ca_data_bag_data
            trusted_ca_data_bag_item.data_bag new_resource.ca_data_bag_name
            trusted_ca_data_bag_item.create
            trusted_ca_data_bag_item.save
          end

          if intermediate_certificate_data_bag_item.nil?
            intermediate_certificate_data_bag_item = Chef::DataBagItem.new
            intermediate_certificate_data_bag_item.raw_data = intermediate_certificate_data_bag_data
            intermediate_certificate_data_bag_item.data_bag new_resource.ca_data_bag_name
            intermediate_certificate_data_bag_item.create
            intermediate_certificate_data_bag_item.save
          end
        else
          return unless unsealed?
          
          trusted_ca_dir = ::File.dirname new_resource.trusted_ca_file
          csr_dir = ::File.dirname new_resource.csr_file
          intermediate_certificate_dir = ::File.dirname new_resource.intermediate_certificate_file

          directory trusted_ca_dir do
            action :nothing
            mode '0755'
            recursive true
            not_if { ::File.file? trusted_ca_dir }
          end.run_action(:create)

          directory csr_dir do
            action :nothing
            mode '0755'
            recursive true
            not_if { ::File.file? csr_dir }
          end.run_action(:create)

          directory intermediate_certificate_dir do
            action :nothing
            mode '0755'
            recursive true
            not_if { ::File.file? intermediate_certificate_dir }
          end.run_action(:create)

          authenticate

          # create and configure root CA

          unless vault_shell_call(['mounts']).stdout.include? new_resource.mount_path
            vault_shell_call(
              [
                'mount',
                "-path=#{new_resource.mount_path}",
                "-description=\"#{new_resource.root_ca_common_name}\"",
                '-max-lease-ttl=87600h',
                'pki'
              ]
            )
          end

          vault_shell_call = vault_shell_call(
            [
              'write',
              '--format=json',
              "#{new_resource.mount_path}/root/generate/internal",
              "common_name=\"#{new_resource.root_ca_common_name}\"",
              'ttl=87600h',
              'key_bits=4096',
              'exclude_cn_from_sans=true'
            ]
          )

          file new_resource.trusted_ca_file do # ~FC005
            action :nothing
            content ::JSON.parse(vault_shell_call.stdout)['data']['certificate']
          end.run_action(:create)

          update_ca_trust

          vault_shell_call(
            [
              'write',
              "#{new_resource.mount_path}/config/urls",
              "issuing_certificates=\"#{new_resource.api_server}/v1/#{new_resource.mount_path}\""
            ]
          )

          # create and configure intermediate CA

          unless vault_shell_call(['mounts']).stdout.include? "#{new_resource.mount_path}-interm"
            vault_shell_call(
              [
                'mount',
                "-path=#{new_resource.mount_path}-interm",
                "-description=\"#{new_resource.intermediate_ca_common_name}\"",
                '-max-lease-ttl=26280h',
                'pki'
              ]
            )
          end

          vault_shell_call = vault_shell_call(
            [
              'write',
              '-format=json',
              "#{new_resource.mount_path}-interm/intermediate/generate/internal",
              "common_name=\"#{new_resource.intermediate_ca_common_name}\"",
              'ttl=26280h',
              'key_bits=4096',
              'exclude_cn_from_sans=true'
            ]
          )

          file new_resource.csr_file do
            action :nothing
            content ::JSON.parse(vault_shell_call.stdout)['data']['csr']
          end.run_action(:create)

          update_ca_trust

          vault_shell_call = vault_shell_call(
            [
              'write',
              '-format=json',
              "#{new_resource.mount_path}/root/sign-intermediate",
              "csr=@#{new_resource.csr_file}",
              "common_name=\"#{new_resource.intermediate_ca_common_name}\"",
              'ttl=26280h'
            ]
          )

          file new_resource.intermediate_certificate_file do # ~FC005
            action :nothing
            content ::JSON.parse(vault_shell_call.stdout)['data']['certificate']
          end.run_action(:create)

          update_ca_trust

          vault_shell_call(
            [
              'write',
              "#{new_resource.mount_path}-interm/intermediate/set-signed",
              "certificate=@#{new_resource.intermediate_certificate_file}"
            ]
          )

          vault_shell_call(
            [
              'write',
              "#{new_resource.mount_path}-interm/config/urls",
              "issuing_certificates=\"#{new_resource.api_server}/v1/#{new_resource.mount_path}-interm/ca\"",
              "crl_distribution_points=\"#{new_resource.api_server}/v1/#{new_resource.mount_path}-interm/crl\""
            ]
          )

          # configure cert roles
          vault_shell_call(
            [
              'write',
              "#{new_resource.mount_path}-interm/roles/server",
              'key_bits=2048',
              'max_ttl=8760h',
              'allow_any_name=true'
            ]
          )
        end
      end

      action :issue_kubernetes_certificates do
        return unless unsealed?

        kubernetes_certificate_dir = ::File.dirname new_resource.kubernetes_certificate_file
        kubernetes_key_dir = ::File.dirname new_resource.kubernetes_key_file

        directory kubernetes_certificate_dir do
          action :nothing
          mode '0755'
          recursive true
          not_if { ::File.file? kubernetes_certificate_dir }
        end.run_action(:create)

        directory kubernetes_key_dir do
          action :nothing
          mode '0755'
          recursive true
          not_if { ::File.file? kubernetes_key_dir }
        end.run_action(:create)

        unless ::File.file?(new_resource.kubernetes_certificate_file) && ::File.file?(new_resource.kubernetes_key_file)
          authenticate

          vault_shell_call = vault_shell_call(
            [
              'write',
              '-format=json',
              "#{new_resource.mount_path}-interm/issue/server",
              "common_name=\"#{new_resource.kubernetes_certificate_common_name}\"",
              "alt_names=\"#{new_resource.kubernetes_certificate_alt_names}\"",
              "ip_sans=\"#{new_resource.kubernetes_certificate_ip_sans}\"",
              'ttl=8760h',
              'format=pem'
            ]
          )

          parsed_stdout = ::JSON.parse(vault_shell_call.stdout)

          certificate_file_content = parsed_stdout['data']['certificate'] + "\n"
          parsed_stdout['data']['ca_chain'].each do |ca_chain_content|
            certificate_file_content += ca_chain_content + "\n"
          end
          certificate_file_content += parsed_stdout['data']['issuing_ca']

          file new_resource.kubernetes_certificate_file do
            content certificate_file_content
            mode '0644'
          end

          file new_resource.kubernetes_key_file do
            content parsed_stdout['data']['private_key']
            mode '0644'
          end
        end
      end

      action :renew_server_certificates do
        return unless ::File.file? new_resource.kubernetes_certificate_file
        return unless ::File.file? new_resource.kubernetes_key_file

        file new_resource.server_key_file do
          action :nothing
          not_if { ::FileUtils.compare_file(new_resource.server_key_file, new_resource.kubernetes_key_file) }
          mode '0644'
          content ::File.open(new_resource.kubernetes_key_file).read
          notifies :restart, 'service[vault]', :immediately
        end.run_action(:create)

        file new_resource.server_certificate_file do
          action :nothing
          not_if { ::FileUtils.compare_file(new_resource.server_certificate_file, new_resource.kubernetes_certificate_file) }
          mode '0644'
          content ::File.open(new_resource.kubernetes_certificate_file).read
          notifies :restart, 'service[vault]', :immediately
        end.run_action(:create)

        service 'vault' do
          action :nothing
        end
      end

      action :trust_ca do
        ca_data_bag = get_data_bag new_resource.ca_data_bag_name
        trusted_ca_data_bag_item = get_data_bag_item new_resource.ca_data_bag_name, new_resource.trusted_ca_data_bag_item_name
        intermediate_certificate_data_bag_item = get_data_bag_item new_resource.ca_data_bag_name, new_resource.intermediate_certificate_data_bag_item_name

        return if ca_data_bag.nil?

        if !trusted_ca_data_bag_item.nil? && !::File.file?(new_resource.trusted_ca_file)
          file new_resource.trusted_ca_file do # ~FC005
            action :nothing
            content trusted_ca_data_bag_item['ca_cert']
          end.run_action(:create)
        end

        if !intermediate_certificate_data_bag_item.nil? && !::File.file?(new_resource.intermediate_certificate_file)
          file new_resource.intermediate_certificate_file do # ~FC005
            action :nothing
            content intermediate_certificate_data_bag_item['interm_cert']
          end.run_action(:create)
        end
        update_ca_trust
      end

      action :unseal do
        (1..5).each do |i|
          unseal_with_key "key#{i}"
        end
      end

      private

      def authenticate
        data_bag_item = get_data_bag_item new_resource.initial_token_data_bag_name, new_resource.initial_token_data_bag_item_name
        return if data_bag_item.nil?

        vault_shell_call(['auth', data_bag_item['token']])
      end

      def get_data_bag(bag_name)
        data_bag(bag_name)
      rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
        nil
      end

      def get_data_bag_item(bag_name, item_id)
        data_bag_item(bag_name, item_id)
      rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
        nil
      end

      def process_unseal_keys_output(line, index)
        return unless line.start_with? 'Unseal Key '

        unseal_key = line.split(':')[1].strip
        return if unseal_key.empty?

        unseal_keys_data_bag_data = {
          'id' => "key#{index + 1}",
          'key' => unseal_key
        }

        Chef::Log.info("#{new_resource.name}: unseal_keys_data_bag_data=#{unseal_keys_data_bag_data.to_json}")

        unseal_keys_data_bag = get_data_bag new_resource.unseal_keys_data_bag_name
        unseal_keys_data_bag_item = get_data_bag_item new_resource.unseal_keys_data_bag_name, unseal_keys_data_bag_data['id']

        if unseal_keys_data_bag && unseal_keys_data_bag_item
          unseal_keys_data_bag_item['key'] = unseal_keys_data_bag_data['key']
          unseal_keys_data_bag_item.save
        elsif !unseal_keys_data_bag
          new_unseal_keys_data_bag = Chef::DataBag.new
          new_unseal_keys_data_bag.name new_resource.unseal_keys_data_bag_name
          new_unseal_keys_data_bag.create
        elsif !unseal_keys_data_bag_item
          new_unseal_keys_data_bag_item = Chef::DataBagItem.new
          new_unseal_keys_data_bag_item.data_bag new_resource.unseal_keys_data_bag_name
          new_unseal_keys_data_bag_item.raw_data = unseal_keys_data_bag_data
          new_unseal_keys_data_bag_item.create
          new_unseal_keys_data_bag_item.save
        end
      end

      def process_initial_root_token_output(line)
        return unless line.start_with? 'Initial Root Token'

        token = line.split(':')[1].strip
        return if token.empty?

        initial_token_data_bag_data = {
          'id' => 'vault_token',
          'token' => token
        }

        Chef::Log.info("#{new_resource.name}: initial_token_data_bag_data=#{initial_token_data_bag_data.to_json}")

        initial_token_data_bag = get_data_bag new_resource.initial_token_data_bag_name
        initial_token_data_bag_item = get_data_bag_item new_resource.initial_token_data_bag_name, initial_token_data_bag_data['id']

        if initial_token_data_bag && initial_token_data_bag_item
          initial_token_data_bag_item['token'] = initial_token_data_bag_data['token']
          initial_token_data_bag_item.save
        elsif !initial_token_data_bag
          new_initial_token_data_bag = Chef::DataBag.new
          new_initial_token_data_bag.name new_resource.initial_token_data_bag_name
          new_initial_token_data_bag.create
        elsif !initial_token_data_bag_item
          new_initial_token_data_bag_item = Chef::DataBagItem.new
          new_initial_token_data_bag_item.data_bag new_resource.initial_token_data_bag_name
          new_initial_token_data_bag_item.raw_data = initial_token_data_bag_data
          new_initial_token_data_bag_item.create
          new_initial_token_data_bag_item.save
        end
      end

      def vault_shell_call(params)
        ENV['VAULT_ADDR'] = new_resource.api_server
        params_string = params.join(' ')
        call = shell_out("vault #{params_string}")

        Chef::Log.info("#{new_resource.name}: vault #{params_string} stdout: [#{call.stdout}]") unless call.stdout.strip.empty?
        Chef::Log.warn("#{new_resource.name}: vault #{params_string} stderr: [#{call.stderr}]") unless call.stderr.strip.empty?

        call
      end

      def unsealed?
        vault_shell_call(['status']).stdout.include? 'Sealed: false'
      end

      def unseal_with_key(unseal_keys_data_bag_item_id)
        data_bag_item = get_data_bag_item new_resource.unseal_keys_data_bag_name, unseal_keys_data_bag_item_id
        return if data_bag_item.nil?

        vault_shell_call(['unseal', data_bag_item['key']])
      end

      def update_ca_trust
        execute 'update-ca-trust' do
          action :nothing
          command '/usr/bin/update-ca-trust'
        end.run_action(:run)
      end
    end
  end
end
