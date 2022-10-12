# Hacer scrapping sobre el sitio portalinmobiliario
# listar las ofertas
# escoger un top 3 de acuerdo a un criterio
# posible criterio: menor precio - mayor espacio
require 'nokogiri'
require 'httparty'
require 'byebug'

BASE_URL = 'https://www.portalinmobiliario.com/arriendo/departamento/propiedades-usadas/1-dormitorio/providencia-metropolitana/_Banos_1#applied_filter_id%3DOPERATION_SUBTYPE%26applied_filter_name%3DModalidad%26applied_filter_order%3D3%26applied_value_id%3D244562%26applied_value_name%3DPropiedades+usadas%26applied_value_order%3D1%26applied_value_results%3D107%26is_custom%3Dfalse'.freeze

def parse_offers_elements
  unparsed_page = HTTParty.get(BASE_URL)
  parsed_page ||= Nokogiri::HTML(unparsed_page.body)
  parsed_page.css('div.ui-search-main > section > ol').children
end

def extract_offer_raw_data(offer)
  offer.css(
    'div.ui-search-result__wrapper
    div.ui-search-result__content
    > a.ui-search-result__content-wrapper.ui-search-link'
  )
end

def convert_uf_cases(price_offer_data)
  price_type = price_offer_data.css('div.ui-search-item__group.ui-search-item__group--price > div > div > span > span.price-tag-amount > span.price-tag-symbol').text
  value = price_offer_data.css('div.ui-search-item__group.ui-search-item__group--price > div > div > span > span.price-tag-amount > span.price-tag-fraction').text
  if price_type == 'UF'
    clp_value = value.to_i * 33_436
    return clp_value
  end
  value.tr('.', '').to_i
end

def offer_data(raw_offer_data)
  {
    price: convert_uf_cases(raw_offer_data),
    beds: raw_offer_data.css('div.ui-search-item__group.ui-search-item__group--attributes > ul > li:nth-child(2)').text,
    m2: raw_offer_data.css('div.ui-search-item__group.ui-search-item__group--attributes > ul > li:nth-child(1)').text,
    location: raw_offer_data.css('div.ui-search-item__group.ui-search-item__group--location > p.ui-search-item__group__element.ui-search-item__location').text,
    info: raw_offer_data.css('div.ui-search-item__group.ui-search-item__group--location > p:nth-child(3)').text,
    area_number: raw_offer_data.css('div.ui-search-item__group.ui-search-item__group--attributes > ul > li:nth-child(1)').text.split(' ').first
  }
end

def create_offer_list
  offers_list = []
  offers = parse_offers_elements
  offers.each do |offer|
    raw_offer_data = extract_offer_raw_data(offer)
    offers_list << offer_data(raw_offer_data)
  end
  offers_list
end

def select_top_offers
  offers_list = create_offer_list
  low_price_oder = offers_list.sort_by { |o| o[:price] }
  max_area_order = offers_list.sort_by { |o| o[:area_number] }.reverse
  top5 = []
  low_price_oder.first(4).each do |low_price|
    max_area_order.each do |max_price|
      top5 << low_price if low_price == max_price
    end
  end
  top5
end

puts select_top_offers
