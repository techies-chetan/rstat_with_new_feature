class UpdatesController < ApplicationController
  before_filter :process_params
  before_filter :require_user, :only => [:timeline, :replies]

  def index
    render_index(Update)
  end

  def timeline
		render_index(current_user.timeline(params))
  end

  def replies
    render_index(current_user.at_replies(params))
  end

  def show
    @update = Update.first(:id => params[:id])
    render :layout => "update"
  end

  def create
		@in_arr =  params["text"].split(/ /)
		@arr = []
		@comp = []
		@in_arr.each_with_index do |input,index|
			case @in_arr[index][0..0]
				when '$','#','@','!','%','&','*','+'
								company_link =  @in_arr[index][0..0] == '$'  ? "http://localhost:3000/update/#{@in_arr[index][1..-1]}" : "http://localhost:3000/update/notfound"
								@arr << '<a href="' +company_link+ '">'  +@in_arr[index][1..-1]  + '</a>' 
								@comp << @in_arr[index]   
								@symb_err = ""
				else
						@symb_err = ""
						@arr << @in_arr[index]
				end													
		end

	params["text"] = @arr.join(' ')
	comp_list = @comp.join(',')
    # XXX: This should really be put into a model. Fat controller here!
    do_tweet = params[:tweet] == "1"
    u = Update.new(:text => params[:text],
                   :referral_id => params[:referral_id],
                   :author => current_user.author,
                   :twitter => do_tweet)
    StockFeed.create(:update_id => u._id,:stock_symbol => comp_list ,:author_id => current_user._id)
    # add entry to user's feed
    current_user.feed.updates << u

    unless u.valid?
      flash[:notice] = u.errors.values.join("\n")
    else
      current_user.feed.save
      current_user.save
#      render :text => current_user.feed.inspect and return false
      # tell hubs there is a new entry
      current_user.feed.ping_hubs

      flash[:notice] = "Update created #{@symb_err}."
    end

    if request.referrer
      redirect_to request.referrer
    else
      redirect_to root_path
    end
  end

  def destroy
    update = Update.first :id => params[:id]

    # lolsecurity.
    if update.author == current_user.author
      update.destroy

      flash[:notice] = "Update Baleeted!"
      redirect_to root_path
    else
      flash[:notice] = "I'm afraid I can't let you do that, #{current_user.name}."
      redirect_to back
    end
  end

  protected

  # Manage page state
  def set_pagination
   set_params_page
	 if params["name"].nil?
	    @updates = @updates.paginate(:page => params[:page], :per_page => params[:per_page], :order => :created_at.desc)
	 else
		 	@stock_feeds =  StockFeed.all(:conditions => {:stock_symbol => "$#{params["name"]}"})
			@ids = []
				@stock_feeds.each do |stock_feed|
					@ids << stock_feed.update_id			
				end
		   @updates = @updates.paginate(:conditions => {:_id => @ids},:page => params[:page], :per_page => params[:per_page], :order => :created_at.desc)
	 end	
    set_pagination_buttons(@updates)
  end

  # Render correct haml depending on request type
  def render_index(updates)
    @updates = updates
    set_pagination
   render :index, :layout => show_layout?
  end

  def process_params
    @update_id, @update_text = "", ""

    # Set update form state correctly
    id = params.fetch("reply") { params["share"] }
    if id
      u = Update.first(:id => id)
      @update_id = id
      @update_text = "@#{u.author.username} " if params["reply"]
      @update_text = "RS @#{u.author.username}: #{u.text}" if params["share"]
    elsif params["status"]
      @update_text = params["status"]
    end
  end
end
