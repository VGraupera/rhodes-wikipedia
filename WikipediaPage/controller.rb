require 'rho/rhocontroller'
require 'rho/rhosupport'

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

    #puts @page.inspect.to_s
    
    # show contents if available
    if @page
      #@data = @page.data.unpack("m")[0]
    end

    render :action => :show, :layout => false
  end
  
  # WikipediaPage/{my page}/fetch
  def fetch
    puts "WikipediaPage fetch with params=#{@params.inspect.to_s}"
      
    # strip braces which surround ID
    @search = strip_braces(@params['id'])
    wiki_get(@search)

    redirect :action => :index, :query => { :search => @search }
  end
  
   # GET /WikipediaPage/history
  def history
    @pages = WikipediaPage.find(:all, {:conditions => {'section' => "header"}}, {:order => 'created_at'})
    @pages = @pages.reverse
    render :action => :history
  end
  
  protected
  
  def wiki_get(article)
    puts "WikipediaPageController wiki_get(#{article})\n"
    
    object_id = "data_#{article}"
    @page = WikipediaPage.find(object_id)
    
    if @page
      puts "++++++Cache hit for #{article}"
      #puts @page.inspect.to_s
    end
    
    unless @page
      puts "------Cache miss for #{article}"
      
      if article == "::Home"
        WikipediaPage.set_notification("/Wikipedia/WikipediaPage")
      else
        # need to encode the article in the url or the login/logged_in functions will fail
        encoded_article = Rho::RhoSupport.url_encode(article)
        WikipediaPage.set_notification("/Wikipedia/WikipediaPage?search=#{encoded_article}")
      end
    
      # make sure we are logged in, this user must exist in rhosync or sync will fail
      if SyncEngine::logged_in == 0
        SyncEngine::login('anonymous', 'password')
      end
    
      WikipediaPage.ask(article)
    end
  end
  
  private
  def strip_braces(str=nil)
    str ? str.gsub(/\{/,"").gsub(/\}/,"") : nil
  end
end