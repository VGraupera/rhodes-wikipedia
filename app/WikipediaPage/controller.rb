require 'rho/rhocontroller'
require 'rho/rhosupport'
require 'rhom/rhom_source'

class WikipediaPageController < Rho::RhoController

  include Rhom
  
  # GET /WikipediaPage/index
  def index
    puts "WikipediaPage index with params=#{@params.inspect.to_s}"
    @search = @params["search"] || "::Home"
    
    @source = RhomSource.find("22")
    if !@source.last_sync_success && !@params["retry"]
       redirect :action => :error_page, :query => { :search => @search }
    else   
      wiki_get(@search, @params["retry"])

      # show contents if available
      if @page
        @data = @page.data.unpack("m")[0]
      end
     
      render
    end
  end
  
  def error_page
     @search = @params["search"]
     render :action => :error_page
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
    if @params['clear']
      WikipediaPage.delete_all
    end
    
    @pages = WikipediaPage.find(:all, {:conditions => {'section' => "header"}}, {:order => 'created_at'})
    @pages = @pages.reverse
    render :action => :history
  end
  
  protected
  
  def wiki_get(article, retry_attempt=nil)
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
        WikipediaPage.set_notification(with_retry("/app/WikipediaPage",retry_attempt))
      else      
        # need to encode the article in the url or the login/logged_in functions will fail
        encoded_article = Rho::RhoSupport.url_encode(article)
        WikipediaPage.set_notification(with_retry("/app/WikipediaPage?search=#{encoded_article}", retry_attempt))      
      end
    
      # make sure we are logged in, this user must exist in rhosync or sync will fail
      if SyncEngine::logged_in == 0
        SyncEngine::login('anonymous', 'password')
      end
        
      WikipediaPage.ask(article)
    end
  end
  
  private
  
  def with_retry(string, retry_attempt)
    if retry_attempt
      string += "&retry=true"
    else
      string
    end
  end
  
  def strip_braces(str=nil)
    str ? str.gsub(/\{/,"").gsub(/\}/,"") : nil
  end
end