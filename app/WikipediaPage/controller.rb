require 'rho/rhocontroller'
require 'rho/rhosupport'
require 'rhom/rhom_source'

class CGI
  # URL-encode a string.
  #   url_encoded_string = CGI::escape("'Stop!' said Fred")
  #      # => "%27Stop%21%27+said+Fred"
  def CGI::escape(string)
    string.gsub(/([^ a-zA-Z0-9_.-]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end.tr(' ', '+')
  end
  
  # URL-decode a string.
  #   string = CGI::unescape("%27Stop%21%27+said+Fred")
  #      # => "'Stop!' said Fred"
  def CGI::unescape(string)
    enc = string.encoding
    string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/) do
      [$1.delete('%')].pack('H*').force_encoding("utf-8")
    end
  end
end

class WikipediaPageController < Rho::RhoController

  include Rhom
  
  # GET /WikipediaPage/index
  def index
    puts "WikipediaPage index with params=#{@params.inspect.to_s}"

    @search = @params["search"] || "::Home"
    @search = CGI::unescape(@search)
    @show_old = @params["show_old"] # dont refresh page even if old
    
    header_page(@search)
    
    # if header is present we assume we have the body as well
    if @header
      # is it current?
      if (Time.parse(@header.created_at) > (Time.now - 3600)) || @show_old
        # puts "OK: show the page we have"
        @page = data_page(@search)
        @data = @page.data.unpack("m")[0]
      else
        # puts "--- refresh existing page"
        # ask to refresh existing page
        wiki_get(:article=>@search, :refresh=>true)
      end
    else
      # puts "--- ask for page 1st time"
      # ask for page for 1st time
      wiki_get(:article=>@search)
    end

    render
  end
  
  # shows there was an error with option to retry
  def error_page
     @search = @params["search"]
     render :action => :error_page
  end
  
  # links in existing wikipedia content are transformed to point to this action
  # which causes following those links to stay within the wikipedia app
  #
  # GET WikipediaPage/{my page}/fetch
  def fetch
    puts "WikipediaPage fetch with params=#{@params.inspect.to_s}"
      
    # strip braces which surround ID
    @search = strip_braces(@params['id'])
    
    # fetch param is double encoded by server, rhodes unencodes once
    @search = CGI::unescape(@search)

    redirect :action => :index, :query => { :search => @search }
  end
  
  # we end up here after we ask for new page from the server
  def sync_notify
    puts "WikipediaPage sync_notify with params=#{@params.inspect.to_s}"
    
    status = @params['status'] #status is added by sync client
    
    refresh = @params['refresh']
    @search = @params['article']
    
    if status == "ok"
      if refresh
        #replace old page with newly refreshed page
        
        refresh_header_id = "header_#{CGI::escape(@search)}_refresh"
        refresh_data_id = "data_#{CGI::escape(@search)}_refresh"
                
        # copy over new data, there are more fields but the content should be the same
        @header = header_page(@search)
        @refresh_header = WikipediaPage.find(refresh_header_id)
        @header.update_attributes("created_at" => @refresh_header.created_at)
        
        @data = data_page(@search)        
        @refresh_data = WikipediaPage.find(refresh_data_id)
        @data.update_attributes("data_length" => @refresh_data.data_length, "data" => @refresh_data.data)
        
        @refresh_header.destroy
        @refresh_data.destroy
      end
      
      # now we should have a good fresh page, so show it
      # we should be sitting on index page
      
      # Example of new call
      # WebView.execute_js("alert('I finished loading')")
      
      WebView::refresh();
      # redirect :action => :index, :query => { :search => @search }
    else
      if refresh
        # refresh failed, so show old page
        # WebView::navigate(url_for :action => :index, :query => { :search => @search, :show_old => true })
        # WebView::navigate should work but fails to load stylsheets on iPhone
        WebView::navigate "/app?show_old=true&search=#{Rho::RhoSupport.url_encode(@search)}"
      else
        WebView::navigate(url_for :action => :error_page, :query => { :search => @search })
      end
    end
  end
  
   # GET /WikipediaPage/history
  def history
    if @params['clear']
      WikipediaPage.delete_all
    end
    
    @pages = WikipediaPage.find(:all, {:conditions => {'section' => "header"}}, {:order => 'created_at'})
    @pages = @pages.reverse
    if @params['ajax']
      render :action => :history, :layout => false
    else
      render :action => :history
    end
  end
  
  protected
  
  # options:
  # article, required
  # refresh, optional
  def wiki_get(options = {})
    puts "WikipediaPageController wiki_get with #{options.inspect.to_s}\n"
    
    article = options[:article]
    
    if options[:refresh]
      param_string = "#{article}&refresh=true"
    else
      param_string = article
    end
    
    WikipediaPage.set_notification("/app/WikipediaPage/sync_notify", "article="+param_string)
      
    # make sure we are logged in. this user must exist in rhosync or sync will fail
    # also make sure that this app has allow anonymous access turned on
    if SyncEngine::logged_in == 0
      SyncEngine::login('anonymous', 'password')
    end
      
    puts "WikipediaPage.ask with #{param_string}"
    WikipediaPage.ask(param_string)
  end
    
  def header_page(article)
    header_id = "header_#{CGI::escape(article)}"
    @header = WikipediaPage.find(header_id)
  end
  
  def data_page(article)
    data_id = "data_#{CGI::escape(article)}"
    @page = WikipediaPage.find(data_id)
  end
  
  def strip_braces(str=nil)
    str ? str.gsub(/\{/,"").gsub(/\}/,"") : nil
  end
end