module SwellMedia
	class OptinsController < ApplicationController

		def create
			@optin = SwellMedia::Optin.new( optin_params )
			if @optin.save

				if defined?( Gibbon ) && ENV['MAILCHIMP_API_KEY'].present? && params[:optin].present?
					gibbon = Gibbon::Request.new
					list_id = ENV['MAILCHIMP_DEFAULT_LIST_ID']
					list_id ||= gibbon.lists.retrieve(params: {"fields": "lists.id"}).body['lists'].first['id']

					#gibbon.lists( list_id ).members.create( body: { email_address: @optin.email, status: "pending", merge_fields: { NAME: @optin.name } } )

				end

				if @offer = LeadOffer.friendly.find( optin_params[:offer_id] )
					LeadOfferOptin.create( optin: @optin, lead_offer: @offer )
					# send offer email
				end

				redirect_to thank_you_optin_path( @optin.code )
			else
				set_flash "Couldn't sign up #{@optin.email}", :error, @optin
				redirect_to :back
				return false
			end
		end

		def thank_you
			@optin = SwellMedia::Optin.find_by( code: params[:id] )
			@offer_optin = SwellMedia::LeadOfferOptin.where( optin_id: @optin.id ).last
		end



		private
			def optin_params
				params.require( :optin ).permit( :name, :email, :offer_id )
			end
	end
end