class AppDelegate
  attr_accessor :status_menu, :results

  @@labels = {
    "phpusd" => { label: "USD", url: "" },
    "bitstamp" => { label: "Bitstamp", url: "http://www.bitstamp.com" },
    "coinbase" => { label: "Coinbase", url: "http://www.coinbase.com" },
    "localbitcoins" => { label: "Local Bitcoins", url: "http://localbitcoins.com" },
    "coinxchangebuy" => { label: "Coinxchange", url: "http://coinxchange.ph" },
    "coinxchangesell" => { label: "Coinxchange (sell)", url: "http://coinxchange.ph" },
    "buybitcoinbuy" => { label: "Buybitcoin.ph", url: "http://buybitcoin.ph/buy" },
    "buybitcoinsell" => { label: "Buybitcoin.ph (sell)", url: "http://buybitcoin.ph/sell" },
    "coinsbuy" => { label: "Coins.ph", url: "http://coins.ph" },
    "coinssell" => { label: "Coins.ph (sell)", url: "http://coins.ph" },
    "rebitsell" => { label: "Rebit (sell)", url: "http://rebit.ph" },
    "bitmarketsell" => { label: "Bitmarket", url: "http://bitmarket.ph" }
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

        resetMenuItems
        loadPreferredMarket

        @results.each_pair do |key, value|
          item = createMenuItem(key, "#{label(key)} - #{currency_format(value)}", 'setCurrentCurrency:')
          status_menu.addItem item
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
