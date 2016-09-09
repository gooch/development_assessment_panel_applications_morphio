require 'scraperwiki'
require "open-uri"
require 'nokogiri'
require File.dirname(__FILE__) + "/ruby_pdf_helper/scraper"

info_url = "http://daps.planning.wa.gov.au/8.asp"
url = "http://www.planning.wa.gov.au/daps/data/Current%20DAP%20Applications/Current%20DAP%20Applications.pdf"

doc = Nokogiri::XML(PdfHelper.pdftoxml(open(url) {|f| f.read}))

doc.search('page').each do |p|
  PdfHelper.extract_table_from_pdf_text(p.search('text')).each do |row|
    unless row[0] == 'No'

      description = row[4] ? row[4].gsub("\n", "") : nil
      record = {
        "council_reference" => row[0],
        "description" => description,
        "address" => row[4].split("\n").last + ", WA",
        "date_scraped" => Date.today.to_s,
        "info_url" => info_url,
        "comment_url" => info_url,
      }
      begin
        record["date_received"] = Date.strptime(row[5].gsub("//","/").strip, "%d/%m/%Y").to_s if row[5]
      rescue
        puts row[5]
      end

      if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
        ScraperWiki.save_sqlite(['council_reference'], record)
      else
        puts "Skipping already saved record " + record['council_reference']
      end
    end
  end
end
