require 'rho/rhocontroller'

class WikipediaPageController < Rho::RhoController

  # GET /WikipediaPage/index
  def index
    puts "WikipediaPage index with params=#{@params.inspect.to_s}"
    
    @search = @params["search"] || "::Home"

    render
  end
  
  # GET /WikipediaPage/show
  # this is rendered inside the iframe
  def show
    puts "WikipediaPage show with params=#{@params.inspect.to_s}"
    
    @search = @params['search']  || "::Home"
    
    wiki_get(@search)

    puts @page.inspect.to_s
    
    # show contents if available
    if @page
      @data = @page.data.unpack("m")[0]
    else
      # no page yet....
      @data = "Please wait..."
    end

    render :action => :show, :layout => false
  end
  
  # WikipediaPage/{my page}/fetch
  def fetch
    puts "WikipediaPage fetch with params=#{@params.inspect.to_s}"
      
    # strip braces
    wiki_get(@params['id'])

    redirect :action => :index, :params => {:search => @params['id']}
  end
  
   # GET /WikipediaPage/history
  def history
    @pages = WikipediaPage.find(:all, {:order => :created_at})
  end
  
  protected
  
  def wiki_get(article)
    puts "WikipediaPageController wiki_get(#{article})\n"
    
    object_id = "data_#{article}"
    @page = WikipediaPage.find(object_id)
    
    if @page
      puts "++++++Cache hit for #{article}"
      puts @page.inspect.to_s
    end
    
    unless @page
      puts "------Cache miss for #{article}"
      WikipediaPage.set_notification("/Wikipedia/WikipediaPage?search=#{article}")

      # make sure we are logged in, this user must exist in rhosync or sync will fail
      if SyncEngine::logged_in == 0
        SyncEngine::login('anonymous', 'password')
      end
    
      WikipediaPage.ask(article)
    end
  end
end