require 'rho/rhocontroller'
require 'rho/rhosupport'
require 'rhom/rhom_source'

class WikipediaPageController < Rho::RhoController

  include Rhom
  
  # GET /WikipediaPage/index
  def index
    puts "WikipediaPage index with params=#{@params.inspect.to_s}"
    
    @search = @params["search"] || "::Home"
    wiki_get(@search)

     # show contents if available
     if @page
       @data = @page.data.unpack("m")[0]
     end
     
     @source = RhomSource.find("22")
     if @data.nil? && !@source.last_sync_success
       @data = "Error encountered."
     end
     
    render
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
        WikipediaPage.set_notification("/app/WikipediaPage")
      else
        # need to encode the article in the url or the login/logged_in functions will fail
        encoded_article = Rho::RhoSupport.url_encode(article)
        WikipediaPage.set_notification("/app/WikipediaPage?search=#{encoded_article}")
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