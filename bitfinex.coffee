# https://bitfinex.com/pages/api

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

request = require 'request'
crypto = require 'crypto'
verror = require 'verror'

module.exports = class Bitfinex

	constructor: (key, secret, timeout) ->

		@url = "https://api.bitfinex.com"
		@key = key
		@secret = secret
		@nonce = Math.round((new Date()).getTime() / 1000)
		@timeout = timeout || 20000

	_nonce: () ->

		return @nonce++

	make_request: (sub_path, params, cb) ->

		if !@key or !@secret
			return cb(new Error("missing api key or secret"))

		path = '/v1/' + sub_path
		url = @url + path
		nonce = JSON.stringify(@_nonce())

		payload = 
			request: path
			nonce: nonce

		for key, value of params
			payload[key] = value

		base64Payload = new Buffer(JSON.stringify(payload)).toString('base64')
		signature = crypto.createHmac("sha384", @secret).update(base64Payload).digest('hex')

		headers = 
			'X-BFX-APIKEY': @key
			'X-BFX-PAYLOAD': base64Payload
			'X-BFX-SIGNATURE': signature

		request { url: url, method: "POST", headers: headers, timeout: @timeout }, (err,response,body)->

			if err
				error = new verror(err, 'failed post request to url %s with payload %s.', url, JSON.stringify(payload))
				error.name = err.code
				return cb error

			try
        result = JSON.parse(body)
			catch err
				error = new verror('failed post request to url %s with payload %s. HTTP status code: %s.', url, JSON.stringify(payload), response.statusCode)
				error.name = response.statusCode
				return cb error

			if result.message
				error = new verror('failed post request to url %s with payload %s. Message: %s', url, payload, result.message)
				error.name = result.message
				return cb error

			cb null, result

	make_public_request: (path, params, cb) ->

		url = @url + '/v1/' + path

		request { url: url, method: "GET", timeout: @timeout, qs: params}, (err,response,body)->

      if err
        error = new verror(err, 'failed post request to url %s', url)
        error.name = err.code
        return cb error

      else if response.statusCode != 200 && response.statusCode != 400
        error = new verror('failed post request to url %s with params %s. Response status code: %s', url, JSON.stringify(params), response.statusCode)
        error.name = response.statusCode
        return cb error

      try
          result = JSON.parse(body)
      catch err
        error = new verror(err, 'failed to parse response body from url %s with params %s. Body: %s', url, JSON.stringify(params), body.toString() )
        error.name = err.message
        return cb error

      if result.message?
        error = new verror('failed post request to url %s. Message: %s', url, result.message)
        error.name = result.message
        return cb error

      cb null, result
    
	#####################################
	########## PUBLIC REQUESTS ##########
	#####################################                            

	ticker: (symbol, cb) ->

		@make_public_request('pubticker/' + symbol, {}, cb)

	today: (symbol, cb) ->

		@make_public_request('today/' + symbol, {}, cb)

	candles: (symbol, cb) ->

		@make_public_request('candles/' + symbol, {}, cb)

	lendbook: (currency, cb) ->

		@make_public_request('lendbook/' + currency, {}, cb)

	orderbook: (symbol, cb) ->

    maxOrders = 100
    uri = 'book/' + symbol
    @make_public_request(uri, {limit_bids: maxOrders, limit_asks: maxOrders}, cb)
    
	trades: (symbol, params, cb) ->

    if !params
      params = {}

    @make_public_request('trades/' + symbol, params, cb)

	lends: (currency, cb) ->

		@make_public_request('lends/' + currency, {}, cb)

	get_symbols: (cb) ->

		@make_public_request('symbols/', {}, cb)

	# #####################################
	# ###### AUTHENTICATED REQUESTS #######
	# #####################################   

	new_order: (symbol, amount, price, exchange, side, type, cb) ->

		params = 
			symbol: symbol
			amount: amount
			price: price
			exchange: exchange
			side: side
			type: type
			# is_hidden: is_hidden 

		@make_request('order/new', params, cb)  

	multiple_new_orders: (symbol, amount, price, exchange, side, type, cb) ->

		params = 
			symbol: symbol
			amount: amount
			price: price
			exchange: exchange
			side: side
			type: type

		@make_request('order/new/multi', params, cb)  

	cancel_order: (order_id, cb) ->

		params = 
			order_id: parseInt(order_id)

		@make_request('order/cancel', params, cb)

	cancel_all_orders: (cb) ->

		@make_request('order/cancel/all', {}, cb)

	cancel_multiple_orders: (order_ids, cb) ->

		params = 
			order_ids: order_ids.map( (id) ->
			    return parseInt(id) )

		@make_request('order/cancel/multi', params, cb)

	replace_order: (order_id, symbol, amount, price, exchange, side, type, cb) ->

		params = 
			order_id: parseInt(order_id)
			symbol: symbol
			amount: amount
			price: price
			exchange: exchange
			side: side
			type: type

		@make_request('order/cancel/replace', params, cb)  

	order_status: (order_id, cb) ->

		params = 
			order_id: parseInt(order_id)

		@make_request('order/status', params, cb)  

	active_orders: (cb) ->

		@make_request('orders', {}, cb)  

	active_positions: (cb) ->

		@make_request('positions', {}, cb)  

	past_trades: (symbol, fromDate, toDate, limit_trades, cb) ->

		params = 
			symbol: symbol
			timestamp: fromDate
			until: toDate
			limit_trades: limit_trades

		@make_request('mytrades', params, cb)

	history: (currency, fromDate, toDate, limit, wallet, cb) ->

		params =
			currency: currency
			since: fromDate
			until: toDate
			limit: limit
			wallet: wallet

		@make_request('history', params, cb)

	movements: (currency, fromDate, toDate, limit, cb) ->

		params =
			currency: currency
			since: fromDate
			until: toDate
			limit: limit

		@make_request('history/movements', params, cb)

	new_offer: (currency, amount, rate, period, direction, insurance_option, cb) ->

		params = 
			currency: currency
			amount: amount
			rate: rate
			period: period
			direction: direction
			insurance_option: insurance_option

		@make_request('offer/new', params, cb)  

	cancel_offer: (offer_id, cb) ->

		params =
      offer_id: parseInt(offer_id)

		@make_request('offer/cancel', params, cb) 

	offer_status: (offer_id, cb) ->

		params =
      offer_id: parseInt(offer_id)

		@make_request('offer/status', params, cb) 

	active_offers: (cb) ->

		@make_request('offers', {}, cb) 

	active_credits: (cb) ->

	 	@make_request('credits', {}, cb) 

	wallet_balances: (cb) ->

		@make_request('balances', {}, cb)
