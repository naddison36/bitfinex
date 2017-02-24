var Bitfinex = require('bitfinex');

// Either pass your API key and secret as the first and second parameters to examples.js. eg
// node examples.js your-api-key your-api-secret
//
// Or enter them below.
// WARNING never commit your API keys into a public repository.
var key = process.argv[2] || 'your-api-key';
var secret = process.argv[3] || 'your-api-secret';

var privateClient = new Bitfinex(key, secret);

// uncomment the API you want to test.
// Be sure to check the parameters so you don't do any unwanted live trades

privateClient.history(
    "BTC",
    new Date("30-SEP-2014").getTime() / 1000,   // since
    new Date("2-OCT-2014").getTime() / 1000,    // until
    100,                                         // limit
    "exchange",
    function(err, transactions)
    {
        console.log('number of transactions ' + transactions.length);

        transactions.forEach(function(transaction) {
            console.log(transaction.currency + ' ' + transaction.balance + ' ' + new Date(transaction.timestamp * 1000).toString() );
        })
    });