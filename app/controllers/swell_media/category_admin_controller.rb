module SwellMedia
	class CategoryAdminController < AdminController

		before_action :get_category, except: [ :create, :empty_trash, :index ]

		def create
			@category = Category.new( category_params )
			@category.user_id = current_user.id

			if @category.save
				set_flash 'Category Created'
				redirect_to edit_category_admin_path( @category.id )
			else
				set_flash 'Category could not be created', :error, @category
				redirect_back( fallback_location: '/admin' )
			end
		end

		def destroy
			if @category.trash?
				@category.destroy
			else
				@category.update( status: :trash )
			end
			set_flash 'Category Deleted'
			redirect_back( fallback_location: '/admin' )
		end

		def edit

		end

		def index
		
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'asc'

			@categories = Category.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@categories = eval "@categories.#{params[:status]}"
			end

			if params[:q].present?
				@categories = @categories.where( "array[:q] && keywords", q: params[:q].downcase )
			end

			@categories = @categories.page( params[:page] )
		end

		def update
			@category.attributes = category_params
			
			if @category.save
				set_flash 'Category Updated'
				redirect_to edit_category_admin_path( id: @category.id )
			else
				set_flash 'Category could not be Updated', :error, @category
				render :edit
			end
		end


		private
			def category_params
				params.require( :category ).permit( :name, :display, :slug, :parent_id, :description, :avatar, :status, :seq, :cover_image ) # todo
			end

			def get_category
				@category = Category.friendly.find( params[:id] )
			end
	end
end