class AppDelegate
  attr_accessor :status_menu, :results

  @@labels = {
    "phpusd" => { label: "USD", url: "", type: 'buy' },
    "bitstamp" => { label: "Bitstamp", url: "http://www.bitstamp.com", type: 'buy' },
    "coinbase" => { label: "Coinbase", url: "http://www.coinbase.com", type: 'buy' },
    "localbitcoins" => { label: "Local Bitcoins", url: "http://localbitcoins.com", type: 'buy' },
    "coinxchangebuy" => { label: "Coinxchange", url: "http://coinxchange.ph",  type: 'buy' },
    "coinxchangesell" => { label: "Coinxchange (sell)", url: "http://coinxchange.ph", type: 'sell' },
    "buybitcoinbuy" => { label: "Buybitcoin.ph", url: "http://buybitcoin.ph/buy", type: 'buy' },
    "buybitcoinsell" => { label: "Buybitcoin.ph (sell)", url: "http://buybitcoin.ph/sell", type: 'sell' },
    "coinsbuy" => { label: "Coins.ph", url: "http://coins.ph", type: 'buy' },
    "coinssell" => { label: "Coins.ph (sell)", url: "http://coins.ph", type: 'sell' },
    "rebitsell" => { label: "Rebit (sell)", url: "http://rebit.ph", type: 'sell' },
    "bitmarketsell" => { label: "Bitmarket (sell)", url: "http://bitmarket.ph", type: 'sell' }
  }

  def applicationDidFinishLaunching(notification)
    @app_name = NSBundle.mainBundle.infoDictionary['CFBundleDisplayName']

    @status_menu = NSMenu.new

    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength).init
    @status_item.setMenu(@status_menu)
    @status_item.setHighlightMode(true)

    loadRates
    setupTimer
  end

  def setupTimer
    # Refresh every 10 minutes
    EM.add_timer (60 * 10) do
      loadRates
    end
  end

  def loadRates
    url = "http://btcphp.com/ticker.php"
    BW::HTTP.get(url) do |response|
      if response.ok?
        @results = BW::JSON.parse(response.body.to_str)
        @results = Hash[@results.sort]

        resetMenuItems
        loadPreferredMarket

        %w(buy sell).each do |type|
          titleItem = NSMenuItem.alloc.initWithTitle("#{type.capitalize} Prices", action: nil, keyEquivalent: "")
          titleItem.setEnabled false
          status_menu.addItem titleItem
          @results.each_pair do |key, value|
            if market_type(key) == type
              item = createMenuItem(key, "#{label(key)} - #{currency_format(value)}", 'setCurrentCurrency:')
              status_menu.addItem item
            end
          end
          status_menu.addItem NSMenuItem.separatorItem
        end

        @status_menu.addItem createMenuItem("", "Quit", 'terminate:')
      end
    end
  end

  def loadPreferredMarket
    if App::Persistence['preferred_market']
      @results.each_pair do |key, value|
        if key == App::Persistence['preferred_market']
          @status_item.setTitle("#{label(key)} - #{currency_format(value)}")
        end
      end
    else
      first_item = @results.first
      @status_item.setTitle("#{label(first_item.first)} - #{currency_format(first_item.last)}")
    end
  end

  def setPreferredMarket(sender)
    App::Persistence['preferred_market'] = sender.key
  end

  def setCurrentCurrency(sender)
    resetMenuItemStatuses
    sender.checked = true
    @status_item.setTitle sender.title
    setPreferredMarket(sender)
  end

  def createMenuItem(key, name, action)
    NSMenuItem.alloc.initWithTitle(name, action: action, keyEquivalent: '').tap do |item|
      item.key = key
    end
  end

  # Get market type. Is it buy or sell?
  def market_type(key)
    @@labels[key][:type] if @@labels[key]
  end

  # Human friendly label
  def label(key)
    @@labels[key][:label] if @@labels[key]
  end

  # This is the reverse of label() where we get the key for a market
  def label_key(label)
    @@labels.each_pair do |k,v|
      return k if v[:label] == label
    end
  end

  def currency_format(amount)
    fmt = NSNumberFormatter.new
    fmt.setFormatterBehavior NSNumberFormatterBehavior10_4
    fmt.setCurrencySymbol "₱"
    fmt.setNumberStyle NSNumberFormatterCurrencyStyle
    fmt.stringFromNumber NSNumber.numberWithFloat(amount)
  end

  def resetMenuItems
    @status_menu.removeAllItems
  end

  def resetMenuItemStatuses
    @status_menu.itemArray.each do |status_item|
      status_item.checked = false
    end
  end

end
