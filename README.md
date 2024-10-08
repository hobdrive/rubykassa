## The Rubykassa gem

[![Gem Version](https://badge.fury.io/rb/rubykassa.png)](http://badge.fury.io/rb/rubykassa)
[![Build Status](https://secure.travis-ci.org/ZeroOneStudio/rubykassa.png)](http://travis-ci.org/ZeroOneStudio/rubykassa)
[![Coverage Status](https://coveralls.io/repos/ZeroOneStudio/rubykassa/badge.png)](https://coveralls.io/r/ZeroOneStudio/rubykassa)
[![Code Climate](https://codeclimate.com/github/ZeroOneStudio/rubykassa.png)](https://codeclimate.com/github/ZeroOneStudio/rubykassa)
[![Dependency Status](https://gemnasium.com/ZeroOneStudio/rubykassa.png)](https://gemnasium.com/ZeroOneStudio/rubykassa)
[![Inline docs](http://inch-ci.org/github/ZeroOneStudio/rubykassa.svg?branch=master)](http://inch-ci.org/github/ZeroOneStudio/rubykassa)

by [Zero One][]

[Zero One]: http://zeroone.st

Yet another Ruby wrapper for [Robokassa API][]. Make Robokassa to work with your Rails project without pain. Rubykassa took the best from [robokassa gem][] and [Active Merchant Robokassa integration] but easier to use and setup.

[Robokassa API]: http://robokassa.ru/ru/Doc/Ru/Interface.aspx
[robokassa gem]: https://github.com/shaggyone/robokassa
[Active Merchant Robokassa integration]: https://github.com/Shopify/active_merchant/tree/master/lib/active_merchant/billing/integrations/robokassa

## Have questions?

[![Gitter chat](https://badges.gitter.im/ZeroOneStudio/rubykassa.png)](https://gitter.im/ZeroOneStudio/rubykassa)

## Installation

Add to your `Gemfile`:

    gem "rubykassa"

## Usage

Run `rails g rubykassa:install`, get an initializer with the following code:

    Rubykassa.configure do |config|
      config.login = ENV["ROBOKASSA_LOGIN"]
      config.first_password = ENV["ROBOKASSA_FIRST_PASSWORD"]
      config.second_password = ENV["ROBOKASSA_SECOND_PASSWORD"]
      config.mode = :test # or :production
      config.http_method = :get # or :post
      config.xml_http_method = :get # or :post
      config.hash_algorithm = :md5 # or :ripemd160, :sha1, :sha256, :sha384, :sha512
    end

and configure it with your credentials. NB! Keep in mind that we are using environment variables. So do not forget to configure your `ENV`. For example using [figaro gem](https://github.com/laserlemon/figaro).

Also, you need to specify Result URL, Success URL and Fail URL at the "Technical Settings" (Технические настройки) in your Robokassa dashboard:

* Result URL: `http://<your_domain>/robokassa/result`
* Success URL: `http://<your_domain>/robokassa/success`
* Fail URL: `http://<your_domain>/robokassa/fail`

To define custom success/fail callbacks you can also use the initializer:

    Rubykassa.configure do |config|
      ...
      config.success_callback = ->(notification) { render plain: 'success' }
      config.fail_callback    = ->(notification) { redirect_to root_path }
      config.result_callback  = ->(notification) { render plain: notification.success }
    end

Lambdas are called in RobokassaController so you can respond with [any kind that is supported by Rails](http://guides.rubyonrails.org/layouts_and_rendering.html#creating-responses).

NOTE: `result_callback` should always return `"OK#{invoice_id}"` string. So, implement your custom logic above `render plain: notification.success` line.

IMPORTANT: Don't forget to restart web server after every change

Mode is `:test` by default. For production you have to use `:production`.
`http_method` and `xml_http_method` are `:get` by default but can be configured as `:post`

Once you are done, simply use `pay_url` helper in your view:

    <%= pay_url "Pay with Robokassa", ivoice_id, total_sum %>

Additionally you may want to pass extra options. There is no problem:

    <%= pay_url "Pay with Robokassa", ivoice_id, total_sum, { description: "Invoice description", email: "foo@bar.com", currency: "WMZM", culture: :ru } %>

Or if you would like to pass some custom params use `custom` key in options hash:

    <%= pay_url "Pay with Robokassa", ivoice_id, total_sum, { description: "Invoice description", email: "foo@bar.com", currency: "WMZM", culture: :ru, custom: { param1: "value1", param2: "value2" }} %>

**Notice!****** If you use Rubykassa::pay_url directly, custom array mapping is different, you should use

    Rubykassa::pay_url ivoice_id, total_sum,
    { param1: "value1", param2: "value2" },
    { description: "Invoice description", email: "foo@bar.com", currency: "WMZM", culture: :ru }

### Receipt handling

Requirements are here: https://docs.robokassa.ru/fiscalization/

Here is a default receipt JSON example:

    {
        "sno":"osn",
        "items": [
        {
            "name": "Название товара 1",
            "quantity": 1,
            "sum": 100,
            "payment_method": "full_payment",
            "payment_object": "commodity",
            "tax": "vat10"
        },
        {
            "name": "Название товара 2",
            "quantity": 3,
            "sum": 450,
            "payment_method": "full_prepayment",
            "payment_object": "excise",
            "nomenclature_code": "04620034587217"
        }
        ]
    }

receipt should be json URLencoded, and can be passed via extra params:

    <%= pay_url "Pay with Robokassa", ivoice_id, total_sum,
      { description: "Invoice description", email: "foo@bar.com", currency: "WMZM", culture: :ru, custom: { param1: "value1", param2: "value2",
      receipt: URI.escape(your_receipt.to_json)
    }} %>

You can put default receipt creation:

    <%= pay_url "Pay with Robokassa", ivoice_id, total_sum,
      { description: "Invoice description", email: "foo@bar.com", currency: "WMZM", culture: :ru, custom: { param1: "value1", param2: "value2",
      receipt: :default
    }} %>

**But be careful reviewing the type of report actually generated**

### Also `pay_url` helper can accept block:

    <%= pay_url ivoice_id, total_sum do %>
      Pay with Robokassa
    <% end %>

You can also pass some HTML options with `html` key in options hash (Bootstrap 3 example):

    <%= pay_url "Pay with Robokassa", ivoice_id, total_sum, { html: { class: 'btn btn-primary btn-bg' }}

If you need to implement Robokassa's XML interface functionality you have to the following:

    xml_interface = Rubykassa::XmlInterface.new do |interface|
      interface.invoice_id = your_invioce_id
      interface.total = your_total_sum
      interface.language = :ru # can be :en, :ru is default
    end

then call whatever you need

    xml_interface.get_currencies_list
    xml_interface.get_payment_methods
    xml_interface.get_rates
    xml_interface.op_state

In test mode, `op_state` accepts hash with additional attributes you would like to get back with response, for example `{ 'StateCode' => 5 }` (more about [StateCode](http://robokassa.ru/en/Doc/En/Interface.aspx#interfeys)). Please note, that any additional parameters to `op_state` are discarded in production mode.

## Supported Rubies and Rails versions

See the CI build [![Build Status](https://secure.travis-ci.org/ZeroOneStudio/rubykassa.png)](http://travis-ci.org/ZeroOneStudio/rubykassa)

## License

This project rocks and uses MIT-LICENSE
Copyright (c) 2013-2016 [Zero One][]

[ZERO.ONE]: http://www.zeroone.st


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/ZeroOneStudio/rubykassa/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
