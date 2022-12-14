require 'rubykassa/engine'
require 'rubykassa/client'
require 'rubykassa/payment_interface'
require 'rubykassa/xml_interface'
require 'rubykassa/notification'

module Rubykassa
  extend self

  def configure(&block)
    Rubykassa::Client.configure &block
  end

  Rubykassa::Configuration::ATTRIBUTES.map do |name|
    define_method name do
      Rubykassa::Client.configuration.send(name)
    end
  end

  def pay_url(invoice_id, total, custom_params, extra_params = {})
    Rubykassa::PaymentInterface.new do
      self.total      = total
      self.invoice_id = invoice_id
      if extra_params[:receipt] == :default
        self.receipt    = Rubykassa::gen_receipt(total, extra_params) 
      else
        self.receipt    = extra_params[:receipt]
      end
      self.params     = custom_params
    end.pay_url(extra_params)
  end

  def def_receipt()
    { # sno: "usn_income",
      items: [
        {
          name: "",
          quantity: 1,
          sum: 0,
          payment_method: "full_payment",
          payment_object: "intellectual_activity",
          tax: "none",
        }
      ]
    }
  end

  def gen_receipt(total_sum, extra_params)
    receipt = def_receipt()

    receipt[:items][0][:name] = extra_params[:description]
    receipt[:items][0][:sum] = total_sum
    
    CGI.escape(receipt.to_json)

  end

end
