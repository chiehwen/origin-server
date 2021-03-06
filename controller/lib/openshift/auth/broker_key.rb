module OpenShift
  module Auth
    #
    # Service instance to generate and verify broker keys. Instance is
    # thread safe, reuse to avoid reloading the priv/pub keys.
    #
    class BrokerKey

      def initialize(auth_info = nil)
        @auth_info = auth_info || Rails.application.config.auth
      end

      #
      # Return a hash with :username if a broker auth key was correctly
      # provided, raise if authentication was not valid, or return nil
      # if no authentication was present.
      #
      def authenticate_request(controller)
        req = controller.request
        key, iv = req.request_parameters.values_at('broker_auth_key', 'broker_auth_iv')
        key, iv = req.headers['broker_auth_key'], req.headers['broker_auth_iv'] unless key && iv
        validate_broker_key(iv, key) if key && iv
      end

      #
      # Generate a broker key from an application
      #
      def generate_broker_key(app)
        cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
        cipher.encrypt
        cipher.key = cipher_key
        cipher.iv = iv = cipher.random_iv
        token = {:app_name => app.name,
                 token_login_key => app.domain.owner.id,
                 :creation_time => app.created_at}
        encrypted_token = cipher.update(token.to_json)
        encrypted_token << cipher.final
        encrypted_iv = public_key.public_encrypt(iv)

        # Base64 encode the iv and token
        encoded_iv = Base64::encode64(encrypted_iv)
        encoded_token = Base64::encode64(encrypted_token)

        [encoded_iv, encoded_token]
      end

      def validate_broker_key(iv, key)
        key = key.gsub(" ", "+")
        iv = iv.gsub(" ", "+")
        begin
          encrypted_token = Base64::decode64(key)
          cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
          cipher.decrypt
          cipher.key = cipher_key
          cipher.iv = private_key.private_decrypt(Base64::decode64(iv))
          json_token = cipher.update(encrypted_token)
          json_token << cipher.final
        rescue => e
          Rails.logger.error "Broker key authentication failed. #{e.message}\n  #{e.backtrace.join("\n  ")}"
          raise OpenShift::AccessDeniedException, "Broker key authentication failed: #{e.message}"
        end

        token = JSON.parse(json_token)
        user_id = token[token_login_key.to_s]
        app_name = token['app_name']           #FIXME should be app id
        creation_time = token['creation_time']

        user = begin
                 CloudUser.find(user_id)
               rescue Mongoid::Errors::DocumentNotFound
                 raise OpenShift::AccessDeniedException, "No such user exists #{user_id}"
               end
        app = Application.find(user, app_name) #FIXME should be app id

        raise OpenShift::AccessDeniedException, "No such application exists #{app_name} or invalid token time" if app.nil? or (Time.parse(creation_time) - app.created_at).abs > 1.0
        {:user => user, :auth_method => :broker_auth, :scopes => Scope::Scopes([Scope::Application.new(:id => app.uuid, :app_scope => :scale), Scope::Application.new(:id => app.uuid, :app_scope => :build)])}
      end

      private
        def private_key
          @private_key ||= OpenSSL::PKey::RSA.new(File.read(privkeyfile), privkeypass)
        end
        def public_key
          @public_key ||= OpenSSL::PKey::RSA.new(File.read(pubkeyfile), privkeypass)
        end

        def cipher_key
          @cipher_key ||= OpenSSL::Digest::SHA512.new(salt).digest
        end
        def salt
          @auth_info[:salt]
        end
        def privkeyfile
          @auth_info[:privkeyfile]
        end
        def privkeypass
          @auth_info[:privkeypass]
        end
        def pubkeyfile
          @auth_info[:pubkeyfile]
        end
        def token_login_key
          @auth_info[:token_login_key] || :login
        end
    end
  end
end
