require 'rho/rhocontroller'

class WikipediaPageController < Rho::RhoController

  def index
    puts "WikipediaPage index"
    # force fetch of daily wikipedia homepage
    if @params["home"]
      wiki_get("::Home")
    end
    
    render
  end
  
  def show
    puts "WikipediaPage show"
    
    @pages = WikipediaPage.find(:all)
    puts @pages.length
    
    @page = @pages[0]
    
    # show contents, otherwise query for homepage
    if @page
      @data = @page.data.unpack("m")[0]
    else
      @data = "Please wait..."
      wiki_get("::Home")
    end

    render :action => :show, :layout => false
  end
  
  def fetch
    puts "WikipediaPage fetch"
      
    wiki_get(@params['id'])

    redirect :action => :index
  end
  
  def create
    puts "WikipediaPage create"
      
    wiki_get(@params['search'])

    redirect :action => :index
  end
  
  protected
  
  def wiki_get(article)
    puts "wiki_get(#{article})\n"
    
    @page = WikipediaPage.new(:search => article)
    @page.save

    WikipediaPage.set_notification("/Wikipedia/WikipediaPage")

    success = SyncEngine::login('wikipedia', 'doesnotmatter')
    if success
      SyncEngine::dosync
    end

    # if SyncEngine::logged_in == 0
    #   SyncEngine::login('wikipedia', 'doesnotmatter')
    # end
    # 
    # WikipediaPage.ask(article)
  end
end