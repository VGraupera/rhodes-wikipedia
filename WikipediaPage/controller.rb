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
    puts @pages.inspect.to_s
    

    # page_pieces = []
    # # elements start at 0
    # 0.upto(@page.packet_count.to_i - 1) do |page|
    #  page_pieces << @page.send("p_#{page}".to_s)
    # end
    # encoded_page = page_pieces.join

    @data = @page.data.unpack("m")[0]

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
    
    success = SyncEngine::login('wikipedia', 'doesnotmatter')
    if success
      SyncEngine::dosync
    end
  end
end