module SwellMedia
	class RegistrationsController < Devise::RegistrationsController

		layout 'sessions'


		def check_name
			if SwellMedia.registered_user_class.constantize.find_by( name: params[:name] )
				render inline: "#{params[:name]} has been taken"
			else
				render inline: "ok"
			end
		end


		def create
			email = params[:user][:email]
			# todo -- check validity of email param?

			email_model = SwellMedia::Email.create_or_update_by_email( email )

			user_class = SwellMedia.registered_user_class.constantize

			user = user_class.where( email: email ).first

			if user.present? && not( user.unregistered? )
				# this email is already registered for this site
				set_flash "#{email} is already registered.", :error
				redirect_back( fallback_location: root_path )
				return false

			end

			user ||= user_class.new( email: email, status: (SwellMedia.default_user_status || 'pending') )

			user.status = SwellMedia.default_user_status || 'pending' if user.unregistered?

			user.name = params[:user][:name]
			user.ip = client_ip
			user.password = params[:user][:password]
			user.password_confirmation = params[:user][:password_confirmation]

			if user.save

				email_model.update_user_if_blank( user ) if email_model.present?
				user.on_registration

				log_event( { name: 'registration', content: "created a user account." } )

				if user.active_for_authentication?

					set_flash "Thanks for signing up!"
					sign_up( :user, user )

					path = after_sign_up_path_for( user )

					redirect_to path

				else

					set_flash "A message with a confirmation link has been sent to your email address. Please follow the link to activate your account." if user.inactive_message == :unconfirmed
					expire_data_after_sign_in!
					redirect_to after_inactive_sign_up_path_for(user)

				end
			else
				set_flash "Could not register user.", :error, user
				render :new
				return false
			end

		end

		protected
		def after_inactive_sign_up_path_for(resource)
			'/'
		end

	end
end
