
module SwellMedia
	class PasswordsController < Devise::PasswordsController

		layout 'sessions'

		# POST /resource/password
		def create
			self.resource = resource_class.send_reset_password_instructions(resource_params)
			yield resource if block_given?

			if successfully_sent?(resource)
				set_flash('Password reset email has been sent')

				log_event( { name: 'forgot_pw', content: "sent forgot password email." } )

				redirect_to after_sending_reset_password_instructions_path_for(resource_name)
			else
				set_flash( resource.errors.full_messages.first, :error )
				redirect_back( fallback_location: root_path )
			end
		end

		def update
			self.resource = resource_class.reset_password_by_token(resource_params)
			yield resource if block_given?

			if resource.errors.empty?
				resource.unlock_access! if unlockable?(resource)
				flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
				set_flash_message(:notice, flash_message) if is_flashing_format?
				sign_in(resource_name, resource)

				log_event( { name: 'update_password', content: "updated their password." } )

				redirect_to after_resetting_password_path_for(resource_name)
				# respond_with resource, location: after_resetting_password_path_for(resource)
			else
				set_flash( 'Unable to reset password', :error, resource )
				redirect_back( fallback_location: root_path )
			end
		end

		protected


			def after_sending_reset_password_instructions_path_for( resource )

				return '/'
			end

	end
end