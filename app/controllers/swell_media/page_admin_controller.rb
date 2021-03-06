
module SwellMedia
	class PageAdminController < AdminController
		before_action :get_page, except: [ :create, :empty_trash, :index ]


		def clone
			authorize( Page, :admin_create? )
			@new_page = Page.new(
				title: 			@page.title + " (copy)",
				subtitle: 		@page.subtitle,
				category_id: 	@page.category_id,
				layout: 		@page.layout,
				template: 		@page.template,
				description: 	@page.description,
				content: 		@page.content,
				show_title: 	@page.show_title,
				keywords: 		@page.keywords,
				tags: 			@page.tags
				)
			@new_page.publish_at ||= Time.zone.now
			@new_page.user = current_user
			@new_page.status = 'draft'

			if @new_page.save
				set_flash 'Page Cloned'
				redirect_to edit_page_admin_path( @new_page )
			else
				set_flash 'Page could not be created', :error, @new_page
				redirect_back( fallback_location: '/admin' )
			end

		end


		def create
			authorize( Page, :admin_create? )
			@page = Page.new( page_params )
			@page.publish_at ||= Time.zone.now
			@page.user = current_user
			@page.status = 'draft'

			if @page.save
				set_flash 'Page Created'
				redirect_to edit_page_admin_path( @page )
			else
				set_flash 'Page could not be created', :error, @page
				redirect_back( fallback_location: '/admin' )
			end
		end


		def destroy
			authorize( @page, :admin_destroy? )
			@page.trash!
			set_flash 'Page Trashed'
			redirect_back( fallback_location: '/admin' )
		end


		def edit
			authorize( @page, :admin_edit? )
		end


		def empty_trash
			authorize( Page, :admin_empty_trash? )
			@pages = Page.trash.destroy_all
			redirect_back( fallback_location: '/admin' )
			set_flash "#{@pages.count} destroyed"
		end


		def index
			authorize( Page, :admin? )

			sort_by = params[:sort_by] || 'publish_at'
			sort_dir = params[:sort_dir] || 'desc'

			@pages = Page.order( "#{sort_by} #{sort_dir}" )

			@pages = @pages.where( redirect_url: nil ) unless params[:redirects]

			if params[:status].present? && params[:status] != 'all'
				@pages = eval "@pages.#{params[:status]}"
			end

			if params[:q].present?
				@pages = @pages.where( "array[:q] && keywords", q: params[:q].downcase )
			end

			@pages = @pages.page( params[:page] )
		end


		def preview
			authorize( @page, :admin_preview? )
			@media = @page
			layout = @media.slug == 'homepage' ? 'swell_media/homepage' : "#{@media.class.name.underscore.pluralize}"
			render "swell_media/pages/show", layout: layout
		end


		def update
			authorize( @page, :admin_update? )

			@page.slug = nil if params[:page][:slug_pref].present? || params[:page][:title] != @page.title
			@page.attributes = page_params

			if @page.save
				set_flash 'Page Updated'
				redirect_to edit_page_admin_path( id: @page.id )
			else
				set_flash 'Page could not be Updated', :error, @page
				render :edit
			end
		end

		private
			def page_params
				params.require( :page ).permit( :title, :subtitle, :avatar_caption, :slug_pref, :description, :content, :status, :publish_at, :show_title, :is_commentable, :user_id, :tags, :tags_csv, :avatar, :avatar_asset_file, :avatar_asset_url )
			end

			def get_page
				@page = Page.friendly.find( params[:id] )
			end

	end
end
